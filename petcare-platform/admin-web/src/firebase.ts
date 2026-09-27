import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';

// Fill these in from the same Firebase project the two mobile apps use —
// Project settings → General → Your apps → Web app (add one if you don't
// have one yet; it's free and takes a minute).
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

export const firebaseApp = initializeApp(firebaseConfig);
export const auth = getAuth(firebaseApp);
