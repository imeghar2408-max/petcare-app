# PetCare Ops — Admin Web Dashboard

The internal tool your team uses to run the platform day to day: approve new providers, look up bookings for support, and see headline numbers. Separate from the two mobile apps — this is a desk tool for staff, not something pet owners or providers ever see.

## What's here

- **Overview** — total bookings, revenue collected, verified providers, and a status breakdown.
- **Provider verification** — the queue of new providers waiting for approval. Nothing shows here shows up in `/providers/nearby` for pet owners until someone approves it.
- **Bookings** — the most recent 100 bookings platform-wide, filterable by status, for support lookups.

## Setup

```bash
cd admin-web
cp .env.example .env
npm install
npm run dev
```

You need two things in `.env`:
1. **`VITE_API_BASE_URL`** — your backend's URL.
2. **Firebase web config** — the *same* Firebase project the two mobile apps use. In the Firebase console: Project settings → General → Your apps → Add app → Web (it's free, takes under a minute). Copy the config values in.

## Creating your first admin user

Signing in here only proves *who* someone is — the backend separately checks `User.role === 'ADMIN'` in Postgres on every request (see `AdminOnlyGuard` in the backend). So:

1. Have the staff member sign up for a Firebase account for this project (e.g. via the Firebase console → Authentication → Add user, with email/password).
2. Open `npx prisma studio` in `backend/`, find (or create) their `User` row, and set `role` to `ADMIN`.
3. They can now sign in here and see real data — anyone else gets 403s from every `/admin/*` endpoint.

There's no self-serve "become an admin" flow by design — that's a decision worth keeping deliberate.

## Extending this

The design is intentionally plain and data-forward (a serif for headings, monospace for IDs/amounts, one accent color used sparingly) — the point is to move fast through data, not to look flashy. Natural next additions, in rough order of likely usefulness:
- A way to issue refunds directly from the Bookings page (calls `POST /payments/verify`'s sibling — you'd add a `POST /admin/bookings/:id/refund` on the backend using Razorpay's refund API)
- A dispute/flag queue if support tickets start coming in through some other channel
- Role tiers (e.g. `support` vs `finance` vs `super-admin`) if more than one or two people end up using this
- Server-side pagination once bookings exceed a few hundred (the `/admin/bookings` endpoint currently just takes the latest 100)
