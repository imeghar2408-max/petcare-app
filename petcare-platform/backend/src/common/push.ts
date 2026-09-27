import * as admin from 'firebase-admin';

/// Sends a push notification to one device token. Silently no-ops (and logs)
/// if the token is missing or FCM rejects it (e.g. stale/uninstalled app) —
/// notification failures should never break the underlying API call.
export async function sendPush(
  fcmToken: string | null | undefined,
  title: string,
  body: string,
  data: Record<string, string> = {},
) {
  if (!fcmToken) return;
  try {
    await admin.messaging().send({ token: fcmToken, notification: { title, body }, data });
  } catch (e) {
    console.warn('Push notification failed:', (e as Error).message);
  }
}
