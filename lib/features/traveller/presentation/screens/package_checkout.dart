// lib/features/traveller/presentation/screens/package_checkout.dart
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'mytrip.dart';
import '../../../../core/config/env_config.dart';
import '../../api/payment_api.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String selectedPaymentMethod = 'paypal';
  bool _isProcessing = false;
  late PaymentApi paymentApi;

  @override
  void initState() {
    super.initState();
    Stripe.publishableKey = EnvConfig.stripePublishableKey;
    paymentApi = PaymentApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D12),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination Card
                  _buildDestinationCard(),
                  const SizedBox(height: 24),

                  // Fixed Payment Amount
                  Text(
                    'Payment Amount: \$5',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Method Section
                  Text(
                    'Payment Method',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPaymentMethodCard(),
                ],
              ),
            ),
          ),

          // Pay Now Button
          _buildPayNowButton(),
        ],
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 5, 11, 26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=80&h=80&fit=crop',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade700,
                child: const Icon(Icons.image, color: Colors.white54),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Ella',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Badulla, Uva',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  '4.5 Rating',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'PayPal - daviddasilva@gmail.com',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            color: Colors.white54,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Pay Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. Create a payment intent on the server
      final paymentIntent = await paymentApi.createPaymentIntent(
        5.0, // Your fixed amount
        'usd',
        {
          'userId': 'user-id-here', // You should get this from your auth system
          'destination': 'Ella, Badulla, Uva',
        },
      );

      // 2. Initialize the payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['clientSecret'],
          merchantDisplayName: 'Roamio',
        ),
      );
      
      // 3. Display the payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      // 4. Show success dialog
      _showSuccessDialog();
    } catch (e) {
      // Handle payment failure
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.greenAccent.shade400,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.black, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                "Payment Completed",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Your payment is successful!\nI hope you are on your way.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) =>  MyTripScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Payment Failed",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          error,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              "OK",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}