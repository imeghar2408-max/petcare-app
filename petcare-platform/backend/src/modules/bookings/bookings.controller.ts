import { Body, Controller, Param, Post, Get, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PrismaService } from '../../common/prisma.module';
import { sendPush } from '../../common/push';
import { ServiceType } from '@prisma/client';

class CreateBookingDto {
  petId: string;
  providerId: string;
  serviceType: ServiceType;
  scheduledAt: string; // ISO date
  addressText: string;
  lat: number;
  lng: number;
  notes?: string;
}

@UseGuards(FirebaseAuthGuard)
@Controller('bookings')
export class BookingsController {
  constructor(private prisma: PrismaService) {}

  // Pet owner requests a service from a specific provider.
  @Post()
  async create(@Req() req: any, @Body() dto: CreateBookingDto) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { petOwnerProfile: true },
    });

    const providerService = await this.prisma.providerService.findUnique({
      where: {
        providerId_serviceType: { providerId: dto.providerId, serviceType: dto.serviceType },
      },
    });

    const booking = await this.prisma.booking.create({
      data: {
        petOwnerId: user!.petOwnerProfile!.id,
        providerId: dto.providerId,
        petId: dto.petId,
        serviceType: dto.serviceType,
        scheduledAt: new Date(dto.scheduledAt),
        addressText: dto.addressText,
        lat: dto.lat,
        lng: dto.lng,
        notes: dto.notes,
        priceInr: providerService?.priceInr ?? 0,
        status: 'REQUESTED',
      },
      include: { pet: true },
    });

    const provider = await this.prisma.providerProfile.findUnique({
      where: { id: dto.providerId },
      include: { user: true },
    });
    await sendPush(
      provider?.user.fcmToken,
      'New booking request',
      `${user!.name} wants to book ${dto.serviceType.toLowerCase()} for ${booking.pet.name}`,
      { bookingId: booking.id, type: 'BOOKING_REQUEST' },
    );

    return booking;
  }

  // Provider accepts or rejects an incoming request.
  @Post(':id/respond')
  async respond(@Param('id') id: string, @Body() body: { accept: boolean }) {
    const booking = await this.prisma.booking.update({
      where: { id },
      data: { status: body.accept ? 'ACCEPTED' : 'REJECTED' },
      include: {
        pet: true,
        provider: { include: { user: true } },
        petOwner: { include: { user: true } },
      },
    });

    await sendPush(
      booking.petOwner.user.fcmToken,
      body.accept ? 'Booking accepted!' : 'Booking declined',
      body.accept
        ? `${booking.provider!.user.name} accepted your ${booking.serviceType.toLowerCase()} request`
        : `${booking.provider!.user.name} can't take this booking`,
      { bookingId: booking.id, type: 'BOOKING_RESPONSE' },
    );

    return booking;
  }

  @Post(':id/start')
  async start(@Param('id') id: string) {
    return this.prisma.booking.update({ where: { id }, data: { status: 'IN_PROGRESS' } });
  }

  // Pet owner sets (or updates) the safe zone for this booking — a center
  // point + radius the provider is expected to stay within. Settable any
  // time before/during the job.
  @Post(':id/safe-zone')
  async setSafeZone(
    @Param('id') id: string,
    @Body() body: { lat: number; lng: number; radiusM: number },
  ) {
    return this.prisma.booking.update({
      where: { id },
      data: {
        safeZoneLat: body.lat,
        safeZoneLng: body.lng,
        safeZoneRadiusM: body.radiusM,
      },
    });
  }

  @Post(':id/complete')
  async complete(@Param('id') id: string) {
    const booking = await this.prisma.booking.update({
      where: { id },
      data: { status: 'COMPLETED' },
      include: { petOwner: { include: { user: true } } },
    });
    await sendPush(
      booking.petOwner.user.fcmToken,
      'Job complete!',
      'Your booking is done — tap to pay and leave a review.',
      { bookingId: booking.id, type: 'BOOKING_COMPLETE' },
    );
    return booking;
  }

  // Pet owner rates the provider once a booking is COMPLETED. Recomputes the
  // provider's running average rating in the same transaction.
  @Post(':id/review')
  async review(@Param('id') id: string, @Body() body: { rating: number; comment?: string }) {
    const booking = await this.prisma.booking.findUniqueOrThrow({ where: { id } });

    return this.prisma.$transaction(async (tx) => {
      const review = await tx.review.create({
        data: { bookingId: id, rating: body.rating, comment: body.comment },
      });

      const provider = await tx.providerProfile.findUniqueOrThrow({
        where: { id: booking.providerId! },
      });
      const newCount = provider.ratingCount + 1;
      const newAvg = (provider.ratingAvg * provider.ratingCount + body.rating) / newCount;
      await tx.providerProfile.update({
        where: { id: provider.id },
        data: { ratingAvg: newAvg, ratingCount: newCount },
      });

      return review;
    });
  }

  @Get('mine')
  async mine(@Req() req: any) {
    const user = await this.prisma.user.findUnique({
      where: { firebaseUid: req.firebaseUser.uid },
      include: { petOwnerProfile: true, providerProfile: true },
    });
    if (user?.petOwnerProfile) {
      return this.prisma.booking.findMany({
        where: { petOwnerId: user.petOwnerProfile.id },
        orderBy: { scheduledAt: 'desc' },
        include: {
          pet: true,
          provider: { include: { user: true } },
          payment: true,
          review: true,
        },
      });
    }
    return this.prisma.booking.findMany({
      where: { providerId: user?.providerProfile?.id },
      orderBy: { scheduledAt: 'desc' },
      include: { pet: true, petOwner: { include: { user: true } }, payment: true },
    });
  }
}
