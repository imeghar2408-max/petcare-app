# PetCare Platform

A two-sided marketplace for pet services (walking, grooming, training, boarding, vet visits).

## Structure

```
petcare-platform/
├── backend/                 # NestJS + PostgreSQL (Prisma) + Socket.IO
├── apps/
│   ├── petcare_user/        # Flutter app — pet owners book services
│   └── petcare_provider/    # Flutter app — providers manage jobs
├── admin-web/                # React + Vite — internal staff dashboard
└── packages/
    └── petcare_core/        # Shared Dart models, API client, theme (used by both mobile apps)
```

## Architecture decisions

| Concern | Choice | Why |
|---|---|---|
| Client framework | Flutter | One codebase → Android now, iOS later |
| Core business data | PostgreSQL + Prisma (via NestJS) | Bookings/payments need real transactions & constraints |
| Auth | Firebase Auth | Battle-tested OTP/social login, saves weeks |
| Push notifications | Firebase Cloud Messaging | Standard, free, reliable |
| Live location + chat | Socket.IO on the NestJS backend | Full control, no per-message Firestore billing at scale |
| Geo "nearby providers" | PostGIS (Postgres extension) | Proper geospatial queries |
| Payments | Razorpay | Best UPI/card support for India |
| File storage (photos, docs) | Firebase Storage or S3 | Simple, cheap |

## Build phases

- [x] **Phase 0** — Repo scaffold, DB schema, shared package, project configs
- [x] **Phase 1** — Auth (OTP login/signup) for both apps, user & provider profile creation
- [x] **Phase 2** — Service catalog, provider discovery, booking request → accept/reject/start/complete flow
- [x] **Phase 3** — Live location tracking (Socket.IO) with an owner-defined safe zone + breach alerts, and in-app chat
- [x] **Phase 4** — Razorpay payments (this drop)
- [x] **Phase 5** — Ratings & reviews, provider earnings dashboard, push notifications, minimal admin API
- [x] **Phase 6** — Admin web dashboard for staff: provider verification, bookings lookup, platform metrics (this drop)

## What Phase 2 added

- **Backend**: already had `/providers/nearby`, `/bookings` (create), `/bookings/:id/respond|start|complete`, `/bookings/mine`, `/users/pets` from Phase 0/1 — this phase is mostly client-side wiring.
- **User app**: tap a service → `ProviderListScreen` (fetches nearby providers) → `BookingFormScreen` (pick pet / add a pet inline / pick date-time / address / notes) → submits the request → `MyBookingsScreen` shows all bookings with live status.
- **Provider app**: `ProviderHomeScreen` now has two tabs — **Requests** (Accept/Reject) and **Active jobs** (Start job → Mark complete) — both backed by real API calls, pull-to-refresh.
- **Known placeholders to fix before shipping**: booking lat/lng are hardcoded to a Delhi coordinate rather than geocoded from the typed address or device GPS; the first-login `POST /auth/register` call isn't wired into the OTP screens yet (needed once so the backend creates the User + profile row); there's no push notification on new requests yet (that needs FCM wiring, planned for Phase 3/5).

## Native platform setup (required for Phase 3 — maps & location)

Both apps use `google_maps_flutter`, and the provider app also uses `geolocator` for live GPS. A few one-time native setup steps, per app (`apps/petcare_user/android` and `apps/petcare_provider/android`):

1. **Google Maps API key** — get one from Google Cloud Console (enable "Maps SDK for Android"), then add it to `android/app/src/main/AndroidManifest.xml` inside the `<application>` tag:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_KEY_HERE"/>
   ```
2. **Location permissions** — add to the same `AndroidManifest.xml`, above `<application>`:
   ```xml
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
   ```
   (Provider app only, since it's the one streaming its GPS position.)
3. **Firebase config** — download `google-services.json` from the Firebase console for each app's package name, drop it in `android/app/`, and follow the standard [FlutterFire setup](https://firebase.google.com/docs/flutter/setup) (`flutterfire configure`) so `Firebase.initializeApp()` in `main.dart` actually has something to initialize.
4. **Backend DB migration** — after pulling this update, run `npx prisma migrate dev` again in `backend/` to add the new `safeZoneLat/Lng/RadiusM` columns.

## What Phase 3 added

- **Backend**: `POST /bookings/:id/safe-zone` (owner sets a center point + radius); the `location` Socket.IO gateway now checks every incoming GPS ping against the booking's safe zone (haversine distance) and broadcasts a `location:alert` event to both apps the moment the provider crosses the boundary in either direction.
- **User app**: `TrackingScreen` — a live map showing the provider's position (updates via socket) plus an editable safe-zone circle: tap "edit," tap the map to move the center, drag the radius slider (50m–2km), save. A red banner appears the instant the provider leaves the zone.
- **Provider app**: `ProviderTrackingScreen` — streams device GPS to the backend every ~10m of movement via `geolocator`, shows the owner-set zone as a read-only circle, and gets its own banner if it strays outside.
- **Chat**: a straightforward per-booking chat screen in both apps (Socket.IO `/chat` namespace), reachable from the bookings list.
- **Known placeholders**: no push notification when a chat message arrives while the app is backgrounded; the safe zone is a simple circle (no custom-shaped zones); `location:update` pings aren't throttled beyond geolocator's own `distanceFilter`, so for a production rollout you'd want to batch/debounce them server-side too.

## What Phase 4 & 5 added

**Payments (Phase 4)**
- User app: once a provider marks a job **Complete**, a "Pay Now" button appears on that booking. Tapping it opens Razorpay's native checkout (`razorpay_flutter`), and on success the backend verifies the signature server-side (`POST /payments/verify`) before marking the payment PAID — never trust the client's word alone for that.
- You'll need to pass your real Razorpay key at build time: `flutter run --dart-define=RAZORPAY_KEY_ID=rzp_live_xxxx` (defaults to a test placeholder otherwise).

**Ratings (Phase 5)**
- Right after a successful payment, the user app opens a 5-star + comment screen (`POST /bookings/:id/review`). The backend recomputes the provider's running average in the same DB transaction as the review insert.
- The provider app shows its own current rating (⭐ avg + count) in the Jobs tab app bar.

**Provider earnings (Phase 5)**
- New **Earnings** tab in the provider app: total lifetime income + a per-job statement, backed by `GET /providers/earnings` (sums PAID payments on COMPLETED bookings).
- Actual bank/UPI payouts aren't automated — the `Payout` table exists in the schema for a future scheduled job (e.g. Razorpay Payouts/Route, run weekly), which is a natural Phase 6.

**Push notifications (Phase 5)**
- Both apps register their FCM device token with the backend right after login (`POST /users/fcm-token`) via a shared `PushService` in `petcare_core`.
- The backend now pushes on: new booking request (→ provider), booking accepted/rejected (→ owner), job completed (→ owner), and provider verification decision (→ provider).
- Foreground messages currently surface as an in-app SnackBar. For a real system-tray notification while the app is open, add `flutter_local_notifications` and display one inside `PushService`'s `onForegroundMessage` callback — background/terminated-app notifications already show natively via FCM without any extra code.

**Minimal admin layer (Phase 5)**
- There's no separate admin app (you asked for two apps — the user and provider ones), but a real gap needed closing: `/providers/nearby` only ever returns **VERIFIED** providers, so without *some* way to verify them, no provider would ever be bookable.
- Added `AdminModule` (`GET /admin/providers/pending`, `POST /admin/providers/:id/verify`) restricted to `User.role === ADMIN`. To create your first admin, either edit a user's role directly via `npx prisma studio` (already wired up as `npm run prisma:studio`), or add a one-off seed script.
- Prisma Studio doubles as a perfectly serviceable internal admin tool for now (browse/edit any table with a UI). If you want a real admin web dashboard later, that's a good, self-contained follow-up project — happy to help build it.

## What Phase 6 added

A separate web app at `admin-web/` — React + Vite + TypeScript, no shared code with the Flutter apps (different platform, makes sense to keep independent). It's a desk tool for your team, not something end users ever see:
- **Overview** — headline metrics (bookings, revenue, verified/pending providers, open complaints)
- **Provider verification** — approve or reject new providers; nothing they submit is bookable until someone does this
- **Bookings** — searchable/filterable list of all bookings, for support lookups
- **Complaints** — every report filed from either mobile app, with a detail panel to move it through Open → In Progress → Resolved/Closed and leave a note that gets pushed back to whoever filed it

It authenticates against the same Firebase project as the mobile apps, but a staff sign-in only gets real data once their `User.role` is set to `ADMIN` in Postgres — see `admin-web/README.md` for the exact steps to create your first admin account.

**Complaints, end to end:** both mobile apps got a Support section (reachable from the app bar) where a pet owner or provider can file a report — either standalone or pre-linked to a specific booking (there's a flag icon right on each booking card), track the status of reports they've already filed, and see any note support left once it's resolved. It's deliberately generic — "the provider never showed up," "payment charged twice," "the app crashed" all go through the same flow rather than needing separate paths.

## Getting started

### Backend
```bash
cd backend
cp .env.example .env   # fill in DB URL, Firebase, Razorpay keys
npm install
npx prisma migrate dev --name init
npm run start:dev
```

### Flutter apps
```bash
cd apps/petcare_user
flutter pub get
flutter run

cd apps/petcare_provider
flutter pub get
flutter run
```

Both apps depend on `packages/petcare_core` via a local path dependency — edit models/API client once, both apps see it.

## Next steps
This scaffold gives you the database schema, project configuration, and one working vertical slice (phone OTP auth) so the patterns are established. Each phase above should be built and tested before moving to the next — happy to build out any phase in detail.
