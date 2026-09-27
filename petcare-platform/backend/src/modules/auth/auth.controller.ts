import { Body, Controller, Post, UseGuards, Req } from '@nestjs/common';
import { FirebaseAuthGuard } from './firebase-auth.guard';
import { PrismaService } from '../../common/prisma.module';
import { UserRole } from '@prisma/client';

class RegisterDto {
  role: UserRole;
  name: string;
  email?: string;
}

@Controller('auth')
export class AuthController {
  constructor(private prisma: PrismaService) {}

  // Called once right after Firebase sign-in on first app open.
  // Creates the User row (and role-specific profile) if it doesn't exist yet.
  @UseGuards(FirebaseAuthGuard)
  @Post('register')
  async register(@Req() req: any, @Body() dto: RegisterDto) {
    const { uid, phone_number } = req.firebaseUser;

    let user = await this.prisma.user.findUnique({ where: { firebaseUid: uid } });
    if (user) return user;

    user = await this.prisma.user.create({
      data: {
        firebaseUid: uid,
        phone: phone_number,
        role: dto.role,
        name: dto.name,
        email: dto.email,
        ...(dto.role === 'PET_OWNER' ? { petOwnerProfile: { create: {} } } : {}),
        ...(dto.role === 'PROVIDER' ? { providerProfile: { create: {} } } : {}),
      },
      include: { petOwnerProfile: true, providerProfile: true },
    });
    return user;
  }

  // Called on every subsequent app open to fetch the existing user + role profile.
  @UseGuards(FirebaseAuthGuard)
  @Post('me')
  async me(@Req() req: any) {
    const { uid } = req.firebaseUser;
    return this.prisma.user.findUnique({
      where: { firebaseUid: uid },
      include: { petOwnerProfile: true, providerProfile: true },
    });
  }
}
