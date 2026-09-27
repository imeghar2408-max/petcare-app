import { Body, Controller, Get, Post, Query, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PrismaService } from '../../common/prisma.module';
import { ServiceType } from '@prisma/client';

class SetAvailabilityDto {
  isAvailable: boolean;
  lat?: number;
  lng?: number;
}

class AddServiceDto {
  serviceType: ServiceType;
  priceInr: number;
  durationMin: number;
}

@Controller('providers')
export class ProvidersController {
  constructor(private prisma: PrismaService) {}

  // Public: find available providers near the pet owner for a given service.
  // NOTE: for production, replace this with a PostGIS ST_DWithin query for
  // proper radius search + sort by distance. This is a straightforward
  // starting version.
  @Get('nearby')
  async nearby(
    @Query('serviceType') serviceType: ServiceType,
    @Query('lat') lat: string,
    @Query('lng') lng: string,
  ) {
    return this.prisma.providerProfile.findMany({
      where: {
        isAvailable: true,
        verificationStatus: 'VERIFIED',
        servicesOffered: { some: { serviceType } },
      },
      include: { servicesOffered: true, user: true },
      take: 20,
    });
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('availability')
  async setAvailability(@Req() req: any, @Body() dto: SetAvailabilityDto) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });
    return this.prisma.providerProfile.update({
      where: { id: user!.providerProfile!.id },
      data: {
        isAvailable: dto.isAvailable,
        currentLat: dto.lat,
        currentLng: dto.lng,
      },
    });
  }

  @UseGuards(FirebaseAuthGuard)
  @Post('services')
  async addService(@Req() req: any, @Body() dto: AddServiceDto) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });
    return this.prisma.providerService.upsert({
      where: {
        providerId_serviceType: {
          providerId: user!.providerProfile!.id,
          serviceType: dto.serviceType,
        },
      },
      create: { ...dto, providerId: user!.providerProfile!.id },
      update: { priceInr: dto.priceInr, durationMin: dto.durationMin },
    });
  }

  // Earnings summary: total paid-out-eligible income (completed jobs with a
  // PAID payment) plus the underlying list, so the app can show a running
  // total and a statement-style breakdown.
  @UseGuards(FirebaseAuthGuard)
  @Get('earnings')
  async earnings(@Req() req: any) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { providerProfile: true },
    });
    const bookings = await this.prisma.booking.findMany({
      where: {
        providerId: user!.providerProfile!.id,
        status: 'COMPLETED',
        payment: { status: 'PAID' },
      },
      include: { payment: true, pet: true },
      orderBy: { scheduledAt: 'desc' },
    });
    const totalInr = bookings.reduce((sum, b) => sum + (b.payment?.amountInr ?? 0), 0);
    return { totalInr, count: bookings.length, bookings };
  }
}
