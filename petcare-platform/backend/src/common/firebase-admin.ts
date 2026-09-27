import * as admin from 'firebase-admin';

// Called once from main.ts before the Nest app starts. The FirebaseAuthGuard
// and push-notification helper both rely on the default app this creates.
export function initFirebaseAdmin() {
  if (admin.apps.length) return;
  admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    }),
  });
}
