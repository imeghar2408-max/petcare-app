import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PrismaService } from '../../common/prisma.module';
import { ComplaintCategory } from '@prisma/client';

class CreateComplaintDto {
  category: ComplaintCategory;
  subject: string;
  description: string;
  bookingId?: string;
}

// Either app (pet owner or provider) can file a complaint — about the other
// party on a booking, about the app itself, or anything else. Kept generic
// rather than booking-specific because "the provider never showed up" and
// "the app crashed on checkout" both need to land somewhere.
@UseGuards(FirebaseAuthGuard)
@Controller('complaints')
export class ComplaintsController {
  constructor(private prisma: PrismaService) {}

  @Post()
  async create(@Req() req: any, @Body() dto: CreateComplaintDto) {
    const user = await this.prisma.user.findUnique({ where: { firebaseUid: req.firebaseUser.uid } });
    return this.prisma.complaint.create({
      data: {
        reportedById: user!.id,
        category: dto.category,
        subject: dto.subject,
        description: dto.description,
        bookingId: dto.bookingId,
      },
    });
    // TODO: push notification to an admin/support Slack channel or FCM
    // topic here, so urgent categories (e.g. SAFETY) get eyes on them fast.
  }

  // So the person who filed it can see whether it's been looked at yet.
  @Get('mine')
  async mine(@Req() req: any) {
    const user = await this.prisma.user.findUnique({ where: { firebaseUid: req.firebaseUser.uid } });
    return this.prisma.complaint.findMany({
      where: { reportedById: user!.id },
      orderBy: { createdAt: 'desc' },
      include: { booking: { include: { pet: true } } },
    });
  }
}
