import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PrismaService } from '../../common/prisma.module';

class AddPetDto {
  name: string;
  species: string;
  breed?: string;
  age?: number;
  weightKg?: number;
  notes?: string;
  photoUrl?: string;
}

@UseGuards(FirebaseAuthGuard)
@Controller('users')
export class UsersController {
  constructor(private prisma: PrismaService) {}

  @Get('pets')
  async myPets(@Req() req: any) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { petOwnerProfile: { include: { pets: true } } },
    });
    return user?.petOwnerProfile?.pets ?? [];
  }

  @Post('pets')
  async addPet(@Req() req: any, @Body() dto: AddPetDto) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { petOwnerProfile: true },
    });
    return this.prisma.pet.create({
      data: { ...dto, ownerId: user!.petOwnerProfile!.id },
    });
  }

  // Called once after Firebase Messaging hands the app a device token, and
  // again whenever it refreshes, so the backend can push notifications.
  @Post('fcm-token')
  async setFcmToken(@Req() req: any, @Body() body: { token: string }) {
    return this.prisma.user.update({
      where: { firebaseUid: req.firebaseUser.uid },
      data: { fcmToken: body.token },
    });
  }
}
