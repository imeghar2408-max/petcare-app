import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { AdminOnlyGuard } from './admin-only.guard';
import { PrismaService } from '../../common/prisma.module';
import { sendPush } from '../../common/push';
import { ComplaintStatus } from '@prisma/client';

// There is no dedicated admin app in this scaffold — these endpoints are
// meant to be driven from `npx prisma studio` (see backend README) or a
// lightweight internal tool later. The one thing that MUST happen somewhere
// is provider verification: /providers/nearby only ever returns providers
// with verificationStatus VERIFIED, so without this step (or an equivalent
// manual DB edit) no provider will ever appear to pet owners.
@UseGuards(FirebaseAuthGuard, AdminOnlyGuard)
@Controller('admin')
export class AdminController {
  constructor(private prisma: PrismaService) {}

  @Get('providers/pending')
  async pendingProviders() {
    return this.prisma.providerProfile.findMany({
      where: { verificationStatus: 'PENDING' },
      include: { user: true, servicesOffered: true },
    });
  }

  @Post('providers/:id/verify')
  async verifyProvider(@Param('id') id: string, @Body() body: { approve: boolean }) {
    const provider = await this.prisma.providerProfile.update({
      where: { id },
      data: { verificationStatus: body.approve ? 'VERIFIED' : 'REJECTED' },
      include: { user: true },
    });
    await sendPush(
      provider.user.fcmToken,
      body.approve ? 'You\'re verified!' : 'Verification update',
      body.approve
        ? 'Your provider account is verified — you can now go online and receive bookings.'
        : 'Your verification was not approved. Contact support for details.',
      { type: 'PROVIDER_VERIFICATION' },
    );
    return provider;
  }

  @Get('bookings')
  async allBookings() {
    return this.prisma.booking.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
      include: {
        pet: true,
        payment: true,
        petOwner: { include: { user: true } },
        provider: { include: { user: true } },
      },
    });
  }

  // Headline numbers for the dashboard landing page.
  @Get('metrics')
  async metrics() {
    const [
      totalBookings,
      pendingVerifications,
      activeProviders,
      totalOwners,
      statusCounts,
      revenue,
      openComplaints,
    ] = await Promise.all([
      this.prisma.booking.count(),
      this.prisma.providerProfile.count({ where: { verificationStatus: 'PENDING' } }),
      this.prisma.providerProfile.count({ where: { verificationStatus: 'VERIFIED' } }),
      this.prisma.petOwnerProfile.count(),
      this.prisma.booking.groupBy({ by: ['status'], _count: true }),
      this.prisma.payment.aggregate({ where: { status: 'PAID' }, _sum: { amountInr: true } }),
      this.prisma.complaint.count({ where: { status: { in: ['OPEN', 'IN_PROGRESS'] } } }),
    ]);

    return {
      totalBookings,
      pendingVerifications,
      activeProviders,
      totalOwners,
      revenueInr: revenue._sum.amountInr ?? 0,
      openComplaints,
      bookingsByStatus: Object.fromEntries(
        statusCounts.map((s) => [s.status, s._count]),
      ),
    };
  }

  // Support queue: every complaint filed from either app, newest first.
  // Optionally filtered by status (OPEN, IN_PROGRESS, RESOLVED, CLOSED).
  @Get('complaints')
  async complaints(@Query('status') status?: ComplaintStatus) {
    return this.prisma.complaint.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: 'desc' },
      include: {
        reportedBy: true,
        booking: { include: { pet: true, provider: { include: { user: true } } } },
      },
    });
  }

  // Move a complaint through the queue, optionally leaving an internal note.
  // Notifies whoever filed it when it's marked RESOLVED or CLOSED.
  @Post('complaints/:id/status')
  async updateComplaintStatus(
    @Param('id') id: string,
    @Body() body: { status: ComplaintStatus; adminNote?: string },
  ) {
    const complaint = await this.prisma.complaint.update({
      where: { id },
      data: {
        status: body.status,
        adminNote: body.adminNote,
        resolvedAt: body.status === 'RESOLVED' || body.status === 'CLOSED' ? new Date() : null,
      },
      include: { reportedBy: true },
    });

    if (body.status === 'RESOLVED' || body.status === 'CLOSED') {
      await sendPush(
        complaint.reportedBy.fcmToken,
        'Your report has been reviewed',
        body.adminNote || `Your report "${complaint.subject}" has been ${body.status.toLowerCase()}.`,
        { type: 'COMPLAINT_UPDATE', complaintId: complaint.id },
      );
    }

    return complaint;
  }
}
