import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/models/payment_status.dart';
import 'package:au_connect/services/paynow_service.dart';
import 'package:au_connect/services/flutterwave_service.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.none;

  // Flutterwave payment tracking (used for confirming payment after redirect)
  String? _flutterwaveTxRef;
  String? _flutterwaveCheckoutUrl;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paymentStatus = PaymentData.applicationFeeStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Application Fee Payment',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildFeeCard(paymentStatus),
            const SizedBox(height: 32),
            if (paymentStatus == PaymentStatus.unpaid) _buildPaymentSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeCard(PaymentStatus status) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Application Fee',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${PaymentData.applicationFeeAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, color: Colors.green),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: status.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status.displayName,
                style: TextStyle(color: status.color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Make Payment',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_selectedPaymentMethod == PaymentMethod.none) ...[
              _buildPaymentMethodButton(
                'EcoCash',
                Icons.phone_android,
                PaymentMethod.ecoCash,
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodButton(
                'Visa Card',
                Icons.credit_card,
                PaymentMethod.visaCard,
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodButton(
                'Flutterwave (International)',
                Icons.public,
                PaymentMethod.flutterwave,
              ),
            ] else if (_selectedPaymentMethod == PaymentMethod.ecoCash) ...[
              _buildEcoCashForm(),
            ] else if (_selectedPaymentMethod == PaymentMethod.visaCard) ...[
              _buildVisaCardForm(),
            ] else if (_selectedPaymentMethod == PaymentMethod.flutterwave) ...[
              _buildFlutterwaveForm(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodButton(String title, IconData icon, PaymentMethod method) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedPaymentMethod = method),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEcoCashForm() {
    final TextEditingController phoneController = TextEditingController();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedPaymentMethod = PaymentMethod.none),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                const Text(
                  'EcoCash Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'EcoCash Phone Number',
                hintText: '07XXXXXXXX',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: \$${PaymentData.applicationFeeAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showEcoCashConfirmation(phoneController.text),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisaCardForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedPaymentMethod = PaymentMethod.none),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Visa Card Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: PaymentData.applicationFeeAmount.toStringAsFixed(2)),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _processVisaPayment,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlutterwaveForm() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedPaymentMethod = PaymentMethod.none),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Flutterwave (International)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: \$${PaymentData.applicationFeeAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _showFlutterwaveConfirmation(
                nameController.text,
                emailController.text,
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Pay with Flutterwave'),
            ),
            if (_flutterwaveTxRef != null) ...[
              const SizedBox(height: 16),
              Text(
                'Transaction reference: $_flutterwaveTxRef',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              if (_flutterwaveCheckoutUrl != null)
                ElevatedButton(
                  onPressed: () async {
                    final uri = Uri.parse(_flutterwaveCheckoutUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text('Reopen Flutterwave Checkout'),
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _verifyFlutterwavePayment,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Verify Payment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFlutterwaveConfirmation(String name, String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Flutterwave Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: $name'),
            Text('Email: $email'),
            Text('Amount: \$${PaymentData.applicationFeeAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('You will be redirected to Flutterwave to complete your payment.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processFlutterwavePayment(name, email);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showEcoCashConfirmation(String phoneNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm EcoCash Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone Number: $phoneNumber'),
            Text('Amount: \$${PaymentData.applicationFeeAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('You will receive a prompt on your phone to complete the payment.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processEcoCashPayment(phoneNumber);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processEcoCashPayment(String phoneNumber) async {
    final reference = 'APPFEE-${DateTime.now().millisecondsSinceEpoch}';

    // Track this payment attempt in history
    PaymentData.addPaymentRecord(
      PaymentRecord(
        txRef: reference,
        method: PaymentMethodType.ecoCash,
        amount: PaymentData.applicationFeeAmount,
        status: PaymentStatus.unpaid,
        note: 'EcoCash payment initiated',
      ),
    );

    final service = PaynowService();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final response = await service.initiateEcoCashPayment(
      reference: reference,
      amount: PaymentData.applicationFeeAmount,
      phoneNumber: phoneNumber,
    );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (response.status.toLowerCase() == 'ok') {
      setState(() {
        PaymentData.updatePaymentStatus(PaymentStatus.paid);
        _selectedPaymentMethod = PaymentMethod.none;
      });

      PaymentData.updatePaymentRecordStatus(
        reference,
        PaymentStatus.paid,
        note: 'EcoCash transaction initiated',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('EcoCash payment initiated. Please complete payment on your phone.'),
          backgroundColor: Colors.green,
        ),
      );

      if (response.browserUrl != null) {
        // You could open the browser URL if required.
      }
    } else {
      PaymentData.updatePaymentRecordStatus(
        reference,
        PaymentStatus.unpaid,
        note: 'EcoCash initiation failed: ${response.error ?? response.status}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.error ?? response.status}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processFlutterwavePayment(String name, String email) async {
    final reference = 'APPFEE-FLW-${DateTime.now().millisecondsSinceEpoch}';

    PaymentData.addPaymentRecord(
      PaymentRecord(
        txRef: reference,
        method: PaymentMethodType.flutterwave,
        amount: PaymentData.applicationFeeAmount,
        status: PaymentStatus.unpaid,
        note: 'Flutterwave checkout created',
      ),
    );

    final service = FlutterwaveService();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final response = await service.createCheckout(
      txRef: reference,
      amount: PaymentData.applicationFeeAmount,
      currency: 'USD',
      customerEmail: email,
      customerName: name,
    );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (response.success && response.checkoutUrl != null) {
      setState(() {
        _flutterwaveTxRef = reference;
        _flutterwaveCheckoutUrl = response.checkoutUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Flutterwave checkout initialized. Please complete payment in the browser and then tap "Verify Payment".'),
          backgroundColor: Colors.green,
        ),
      );

      final uri = Uri.parse(response.checkoutUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _verifyFlutterwavePayment() async {
    final txRef = _flutterwaveTxRef;
    if (txRef == null) return;

    final service = FlutterwaveService();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final response = await service.verifyTransaction(txRef: txRef);

    if (!mounted) return;
    Navigator.pop(context); // dismiss loading

    if (response.success) {
      setState(() {
        PaymentData.updatePaymentStatus(PaymentStatus.paid);
        _selectedPaymentMethod = PaymentMethod.none;
        _flutterwaveTxRef = null;
        _flutterwaveCheckoutUrl = null;
      });

      PaymentData.updatePaymentRecordStatus(
        txRef,
        PaymentStatus.paid,
        note: 'Flutterwave payment verified',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verified successfully! Application fee has been marked as paid.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      PaymentData.updatePaymentRecordStatus(
        txRef,
        PaymentStatus.unpaid,
        note: 'Flutterwave verification failed: ${response.message ?? response.status ?? 'Unknown'}',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment verification failed: ${response.message ?? response.status ?? 'Unknown'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _processVisaPayment() {
    final reference = 'APPFEE-VISA-${DateTime.now().millisecondsSinceEpoch}';
    PaymentData.addPaymentRecord(
      PaymentRecord(
        txRef: reference,
        method: PaymentMethodType.visaCard,
        amount: PaymentData.applicationFeeAmount,
        status: PaymentStatus.paid,
        note: 'Visa card payment simulated as complete',
      ),
    );

    // Simulate payment processing
    setState(() {
      PaymentData.updatePaymentStatus(PaymentStatus.paid);
      _selectedPaymentMethod = PaymentMethod.none;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment successful! Application fee has been paid.'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

enum PaymentMethod {
  none,
  ecoCash,
  visaCard,
  flutterwave,
}