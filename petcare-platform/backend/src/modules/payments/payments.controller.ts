import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import * as crypto from 'crypto';
import Razorpay from 'razorpay';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';
import { PrismaService } from '../../common/prisma.module';

@UseGuards(FirebaseAuthGuard)
@Controller('payments')
export class PaymentsController {
  private razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID!,
    key_secret: process.env.RAZORPAY_KEY_SECRET!,
  });

  constructor(private prisma: PrismaService) {}

  // Called from the user app right after a booking is ACCEPTED, before
  // opening Razorpay checkout.
  @Post('create-order')
  async createOrder(@Body() body: { bookingId: string }) {
    const booking = await this.prisma.booking.findUnique({ where: { id: body.bookingId } });
    const order = await this.razorpay.orders.create({
      amount: booking!.priceInr * 100, // paise
      currency: 'INR',
      receipt: booking!.id,
    });
    await this.prisma.payment.create({
      data: {
        bookingId: booking!.id,
        razorpayOrderId: order.id,
        amountInr: booking!.priceInr,
        status: 'PENDING',
      },
    });
    return order;
  }

  // Called from the app after Razorpay checkout succeeds, to verify the
  // payment signature server-side before marking it PAID.
  @Post('verify')
  async verify(
    @Body()
    body: {
      razorpay_order_id: string;
      razorpay_payment_id: string;
      razorpay_signature: string;
    },
  ) {
    const expected = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET!)
      .update(`${body.razorpay_order_id}|${body.razorpay_payment_id}`)
      .digest('hex');

    const valid = expected === body.razorpay_signature;

    if (valid) {
      await this.prisma.payment.updateMany({
        where: { razorpayOrderId: body.razorpay_order_id },
        data: { razorpayPaymentId: body.razorpay_payment_id, status: 'PAID' },
      });
    }
    return { valid };
  }
}