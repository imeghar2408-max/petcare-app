import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:petcare_core/petcare_core.dart';
import '../reviews/rate_provider_screen.dart';

/// Not a screen with its own route — call `PaymentFlow.start(context, booking)`
/// from wherever a "Pay Now" button lives. Opens Razorpay's native checkout
/// UI, verifies the payment server-side on success, then routes into the
/// rating screen.
class PaymentFlow {
  static Future<void> start(BuildContext context, Booking booking) async {
    final api = ApiClient(baseUrl: ApiConfig.baseUrl);
    final razorpay = Razorpay();

    final order = await api.post('/payments/create-order', data: {'bookingId': booking.id});
    final orderId = order.data['id'];
    final amount = order.data['amount']; // in paise

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
      final verifyRes = await api.post('/payments/verify', data: {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });
      razorpay.clear();
      if (!context.mounted) return;
      if (verifyRes.data['valid'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment successful!')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RateProviderScreen(booking: booking)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment could not be verified. Contact support.')),
        );
      }
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      razorpay.clear();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment failed: ${response.message}')));
    });

    razorpay.open({
      'key': const String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_xxxxxxxx'),
      'order_id': orderId,
      'amount': amount,
      'currency': 'INR',
      'name': 'PetCare',
      'description': '${booking.serviceType.label} for ${booking.petName ?? 'your pet'}',
    });
  }
}
