import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import * as admin from 'firebase-admin';

// Both Flutter apps sign in with Firebase Auth (phone OTP) and send the
// resulting ID token as: Authorization: Bearer <idToken>
// This guard verifies it and attaches the decoded token to the request.
@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest();
    const authHeader = req.headers.authorization;
    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token');
    }
    const idToken = authHeader.split(' ')[1];
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      req.firebaseUser = decoded; // { uid, phone_number, ... }
      return true;
    } catch (e) {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}
