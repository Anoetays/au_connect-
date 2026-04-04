import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:au_connect/providers/application_form_provider.dart';
import 'package:au_connect/services/application_state.dart';
import 'package:au_connect/services/flutterwave_service.dart';
import 'package:au_connect/services/payment_service.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:au_connect/theme/app_theme.dart';

import 'submit_application_screen.dart';

// ─── color tokens ─────────────────────────────────────────────────────────────
const _kCrimson      = AppTheme.primaryDark;
const _kCrimsonLight = AppTheme.primaryCrimson;
const _kCrimsonPale  = AppTheme.primaryLight;
const _kInk          = AppTheme.textPrimary;
const _kInkMid       = AppTheme.textSecondary;
const _kParchment    = AppTheme.background;
const _kParchDeep    = Color(0xFFF0EBE1);
const _kBorder       = AppTheme.border;
const _kMuted        = AppTheme.textMuted;
const _kEmerald      = AppTheme.statusApproved;
const _kEmeraldMid   = Color(0xFF2A9D6A);
const _kGreenBg      = Color(0xFFF0FBF5);
const _kGreenBd      = Color(0xFFC2E8D4);
const _kGreenFg      = Color(0xFF10B981);
const _kGreenDk      = Color(0xFF065F46);

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key, this.nextRoute});
  final WidgetBuilder? nextRoute;

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMethod = -1;
  final bool _processing = false;
  bool _overlayShowing = false;
  Map<String, dynamic>? _application;
  bool _loading = true;
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  static const double _appFee = 25.0;

  static const _methods = [
    _Method(id: 0, name: 'EcoCash',       sub: 'Mobile Wallet',        icon: Icons.phone_android_rounded),
    _Method(id: 1, name: 'Visa / Master', sub: 'Credit or Debit Card',  icon: Icons.credit_card_rounded),
    _Method(id: 2, name: 'Flutterwave',   sub: 'Direct Bank Transfer',  icon: Icons.account_balance_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _loadData();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        SupabaseService.getProfile(),
        SupabaseService.getMyApplication(),
      ]);
      if (!mounted) return;
      setState(() {
        _application = results[1];
        _loading = false;
      });
      _ctrl.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _ctrl.forward(from: 0);
    }
  }

  String get _programName =>
      _application?['program'] as String? ?? 'your chosen programme';

  bool get _feePaid =>
      _application?['application_fee_paid'] as bool? ?? false;

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kParchment,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: _kCrimson))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _kCrimson,
                    child: FadeTransition(
                      opacity: _fade,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: _buildContent(context)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Color(0xF5FAF7F2),
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_rounded,
                    size: 18, color: _kCrimson),
                const SizedBox(width: 8),
                Text(
                  'Back',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kCrimson,
                    letterSpacing: 0.02 * 13,
                  ),
                ),
              ],
            ),
          ),
          // Title
          Text(
            'Payments',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.08 * 18,
              color: _kInk,
            ),
          ),
          // History
          GestureDetector(
            onTap: () => _showPaymentHistory(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder, width: 1.5),
              ),
              child: const Icon(Icons.access_time_rounded,
                  size: 15, color: _kMuted),
            ),
          ),
        ],
      ),
    );
  }

  // ── CONTENT ────────────────────────────────────────────────────────────────
  Widget _buildContent(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 44, 36, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page heading
              Text(
                'Financial Overview',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your application fees and explore institutional support programs.',
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  color: _kMuted,
                ),
              ),
              const SizedBox(height: 28),

              // App fee card
              _buildAppFeeCard(),
              const SizedBox(height: 20),

              // Bottom row
              _buildBottomRow(context),
            ],
          ),
        ),
      ),
    );
  }

  // ── APP FEE CARD ──────────────────────────────────────────────────────────
  Widget _buildAppFeeCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1A1208),
            blurRadius: 18,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x0A1A1208),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: badge+title | amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    _feePaid
                        ? _PaidBadge()
                        : const _ActionBadge(),
                    const SizedBox(height: 12),
                    Text(
                      'Application Fee',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Complete your application for the $_programName.',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, color: _kMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${_appFee.toStringAsFixed(2)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: _feePaid ? _kEmerald : _kInk,
                      letterSpacing: -0.01 * 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Non-refundable fee',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: _kMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: _kBorder, height: 1),
          ),

          if (!_feePaid) ...[
            // Method label
            Text(
              'SELECT PAYMENT METHOD',
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.1 * 11.5,
                color: _kInkMid,
              ),
            ),
            const SizedBox(height: 14),

            // Method tiles
            Row(
              children: List.generate(_methods.length, (i) {
                final m = _methods[i];
                final sel = _selectedMethod == m.id;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedMethod = m.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 10),
                      decoration: BoxDecoration(
                        color: sel ? _kCrimsonPale : _kParchment,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? _kCrimson : _kBorder,
                          width: 1.5,
                        ),
                        boxShadow: sel
                            ? const [
                                BoxShadow(
                                  color: Color(0x1A9B1B30),
                                  blurRadius: 0,
                                  spreadRadius: 3,
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: sel
                                    ? _kCrimson.withValues(alpha: 0.3)
                                    : _kBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(m.icon,
                                size: 18,
                                color: sel ? _kCrimson : _kInkMid),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            m.name,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: sel ? _kInk : _kInk,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.sub,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: _kMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Pay button
            _PayButton(
              enabled: _selectedMethod != -1,
              processing: _processing,
              label: _selectedMethod == 0
                  ? 'Pay with EcoCash'
                  : _selectedMethod != -1
                      ? 'Pay \$${_appFee.toStringAsFixed(2)} via ${_methods[_selectedMethod].name}'
                      : 'Select a payment method',
              onTap: _handlePayment,
            ),
            const SizedBox(height: 10),
            // TODO: Remove before production — test bypass
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: widget.nextRoute ?? (_) => const SubmitApplicationScreen(),
                ),
              ),
              child: const Text(
                'Skip Payment (Test Only)',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ] else ...[
            // Paid banner
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _kGreenBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kGreenBd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 20, color: _kGreenFg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Payment received. You'll receive a confirmation email shortly.",
                      style: GoogleFonts.dmSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: _kGreenDk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── BOTTOM ROW ────────────────────────────────────────────────────────────
  Widget _buildBottomRow(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final wide = constraints.maxWidth >= 600;
      if (wide) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildAwardsCard(context)),
            const SizedBox(width: 20),
            Expanded(child: _buildAssistanceCard(context)),
          ],
        );
      }
      return Column(children: [
        _buildAwardsCard(context),
        const SizedBox(height: 20),
        _buildAssistanceCard(context),
      ]);
    });
  }

  // ── AWARDS CARD ───────────────────────────────────────────────────────────
  Widget _buildAwardsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0FBF5), Color(0xFFE4F7ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kGreenBd),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1A1208),
            blurRadius: 18,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kEmerald.withValues(alpha: 0.12),
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    size: 18, color: _kEmerald),
              ),
              const SizedBox(width: 10),
              Text(
                'ACTIVE AWARDS',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.08 * 12,
                  color: _kEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$1,200.00',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 40,
              fontWeight: FontWeight.w600,
              color: _kEmerald,
              letterSpacing: -0.01 * 40,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Merit Scholarship applied',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kEmeraldMid,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => _showAwardDetails(context),
            child: Row(
              children: [
                Text(
                  'View award details',
                  style: GoogleFonts.dmSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _kEmerald,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.chevron_right_rounded,
                    size: 13, color: _kEmerald),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ASSISTANCE CARD ───────────────────────────────────────────────────────
  Widget _buildAssistanceCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1A1208),
            blurRadius: 18,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kCrimsonPale,
                ),
                child: const Icon(Icons.favorite_rounded,
                    size: 15, color: _kCrimson),
              ),
              const SizedBox(width: 10),
              Text(
                'Need Assistance?',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Apply for university grants, student loans, or hardship funds for the current academic year.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: _kMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          _AssistButton(
            onTap: () => _showAssistanceForm(context),
          ),
        ],
      ),
    );
  }

  // ── PAYMENT LOGIC ─────────────────────────────────────────────────────────
  Future<void> _handlePayment() async {
    if (_selectedMethod == -1 || _processing) return;
    if (_selectedMethod == 0) {
      _showEcoCashDialog();
      return;
    }
    if (_selectedMethod == 2) {
      await _handleFlutterwavePayment();
      return;
    }
    // Visa — not yet implemented
  }

  Future<void> _handleFlutterwavePayment() async {
    final email = SupabaseService.currentUser?.email ?? '';
    final name = _application?['full_name'] as String? ?? email.split('@').first;
    final txRef = 'app_fee_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await FlutterwaveService().createCheckout(
        txRef: txRef,
        amount: _appFee,
        currency: 'USD',
        customerEmail: email,
        customerName: name,
      );

      if (response.success && response.checkoutUrl != null) {
        final url = Uri.parse(response.checkoutUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          // Show waiting dialog while user completes payment
          _showFlutterwaveWaitingDialog(txRef);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open payment page. Please try again.'),
            backgroundColor: _kCrimson,
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Payment setup failed: ${response.message}'),
          backgroundColor: _kCrimson,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Payment setup failed. Please try again.'),
        backgroundColor: _kCrimson,
      ));
    }
  }

  void _showFlutterwaveWaitingDialog(String txRef) {
    _overlayShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FlutterwaveWaitingDialog(
        txRef: txRef,
        onVerified: (success) async {
          _dismissOverlay();
          if (success) {
            // Update application fee status in database
            final appId = _application?['id'] as String?;
            if (appId != null) {
              try {
                await SupabaseService.updateApplicationFeePaid(appId, true);
                // Refresh application data
                _loadData();
              } catch (e) {
                debugPrint('Failed to update fee status: $e');
              }
            }
            _showPaymentSuccess();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Payment verification failed. Please contact support.'),
              backgroundColor: _kCrimson,
            ));
            setState(() => _selectedMethod = -1);
          }
        },
      ),
    ).then((_) => _overlayShowing = false);
  }

  void _showEcoCashDialog() {
    final email = SupabaseService.currentUser?.email ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _EcoCashDialog(
          amount: _appFee,
          email: email,
          onSuccess: (pollUrl) {
            _showWaitingOverlay();
            _startPolling(pollUrl);
          },
        ),
      ),
    );
  }

  void _showWaitingOverlay() {
    _overlayShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _WaitingDialog(),
    ).then((_) => _overlayShowing = false);
  }

  void _dismissOverlay() {
    if (_overlayShowing && mounted) Navigator.of(context).pop();
  }

  void _showPaymentSuccess() {
    // Update the global provider with payment info
    ref.read(applicationFormProvider.notifier).updatePaymentInfo(
      PaymentInfo(
        isPaid: true,
        amount: _appFee,
        method: _selectedMethod == 0 ? 'EcoCash' : _selectedMethod == 1 ? 'Visa/Master' : 'Flutterwave',
        paidAt: DateTime.now(),
      ),
    );

    ApplicationState.instance.setFeePaid(true);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: _kGreenFg, size: 24),
            const SizedBox(width: 8),
            Text('Payment Successful',
                style: GoogleFonts.cormorantGaramond(fontSize: 20, fontWeight: FontWeight.w600)),
          ],
        ),
        content: Text(
          'Your application fee has been paid successfully. You can now proceed to submit your application.',
          style: GoogleFonts.dmSans(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: widget.nextRoute ?? (_) => const SubmitApplicationScreen(),
                ),
              );
            },
            child: const Text('Continue to Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _startPolling(String pollUrl) async {
    const maxAttempts = 12;
    const interval = Duration(seconds: 5);

    for (int i = 0; i < maxAttempts; i++) {
      await Future.delayed(interval);
      if (!mounted) return;

      final result = await PaymentService.pollTransaction(pollUrl);
      if (!mounted) return;

      if (result['success'] == true) {
        final status = (result['status'] as String).toLowerCase();
        final paid = result['paid'] == true;

        if (paid || status == 'paid') {
          _dismissOverlay();
          // Update application fee status in database
          final appId = _application?['id'] as String?;
          if (appId != null) {
            try {
              await SupabaseService.updateApplicationFeePaid(appId, true);
              // Refresh application data
              _loadData();
            } catch (e) {
              debugPrint('Failed to update fee status: $e');
            }
          }
          _showPaymentSuccess();
          return;
        }
        if (status == 'cancelled' || status == 'failed' || status == 'dispute') {
          _dismissOverlay();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Payment was cancelled or failed. Please try again.'),
            backgroundColor: _kCrimson,
          ));
          setState(() => _selectedMethod = -1);
          return;
        }
        // Still pending — keep polling
      }
    }

    // Timed out
    if (!mounted) return;
    _dismissOverlay();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Payment request timed out. Please try again.'),
      backgroundColor: _kCrimson,
    ));
    setState(() => _selectedMethod = -1);
  }

  void _showPaymentHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(
                'Payment History',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 20, fontWeight: FontWeight.w600, color: _kInk),
              ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 16),
            if (_feePaid)
              _HistoryRow(
                label: 'Application Fee',
                amount: '\$${_appFee.toStringAsFixed(2)}',
                date: 'Paid',
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(children: [
                    Icon(Icons.receipt_long_rounded,
                        size: 40, color: _kBorder),
                    const SizedBox(height: 12),
                    Text('No payments yet',
                        style: GoogleFonts.dmSans(color: _kMuted)),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showAwardDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _kGreenFg.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.card_giftcard_rounded,
                    color: _kGreenFg, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Merit Scholarship',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 20),
            _DetailRow(label: 'Award Amount',      value: '\$1,200.00'),
            const SizedBox(height: 12),
            _DetailRow(label: 'Type',              value: 'Merit-Based Scholarship'),
            const SizedBox(height: 12),
            _DetailRow(label: 'Applicable Period', value: 'Academic Year 2025'),
            const SizedBox(height: 12),
            _DetailRow(label: 'Status',            value: 'Active', isSuccess: true),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kGreenFg.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'This scholarship will be applied directly to your outstanding tuition balance. Contact the Bursary Office for more details.',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: _kGreenFg, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAssistanceForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(
                  'Apply for Assistance',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context)),
              ]),
              const SizedBox(height: 6),
              Text(
                'Select the type of financial support you are applying for.',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: _kMuted, height: 1.4),
              ),
              const SizedBox(height: 20),
              ...[
                ('University Grant',  'Non-repayable support for qualifying students',           Icons.school_rounded),
                ('Student Loan',      'Repayable loan with favorable interest terms',            Icons.account_balance_rounded),
                ('Hardship Fund',     'Emergency support for students in financial difficulty',  Icons.favorite_rounded),
              ].map((item) {
                final (title, desc, icon) = item;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$title application submitted'),
                          backgroundColor: _kCrimson,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _kBorder),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _kCrimsonPale,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: _kCrimson, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: _kInk)),
                              Text(desc,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: _kMuted,
                                      height: 1.3)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: _kMuted, size: 20),
                      ]),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _Method ──────────────────────────────────────────────────────────────────
class _Method {
  final int id;
  final String name, sub;
  final IconData icon;
  const _Method({
    required this.id,
    required this.name,
    required this.sub,
    required this.icon,
  });
}

// ─── _ActionBadge ────────────────────────────────────────────────────────────
class _ActionBadge extends StatefulWidget {
  const _ActionBadge();

  @override
  State<_ActionBadge> createState() => _ActionBadgeState();
}

class _ActionBadgeState extends State<_ActionBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _opacity = Tween(begin: 1.0, end: 0.3)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kCrimson,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xB3FFFFFF),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'ACTION REQUIRED',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.14 * 10,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _PaidBadge ───────────────────────────────────────────────────────────────
class _PaidBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kGreenBg,
        border: Border.all(color: _kGreenBd),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: _kGreenFg),
          const SizedBox(width: 5),
          Text(
            'PAID',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.14 * 10,
              color: _kGreenDk,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _PayButton ───────────────────────────────────────────────────────────────
class _PayButton extends StatefulWidget {
  final bool enabled, processing;
  final String label;
  final VoidCallback onTap;

  const _PayButton({
    required this.enabled,
    required this.processing,
    required this.label,
    required this.onTap,
  });

  @override
  State<_PayButton> createState() => _PayButtonState();
}

class _PayButtonState extends State<_PayButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.enabled && !widget.processing ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 50,
          transform: (widget.enabled && _hover)
              ? Matrix4.translationValues(0, -1, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [_kCrimsonLight, _kCrimson],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.enabled ? null : _kParchDeep,
            borderRadius: BorderRadius.circular(10),
            border: widget.enabled
                ? null
                : Border.all(color: _kBorder, width: 1.5),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: _kCrimson.withValues(alpha: _hover ? 0.40 : 0.30),
                      blurRadius: _hover ? 20 : 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: widget.processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.enabled
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: widget.enabled ? Colors.white : _kMuted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.04 * 14,
                          color: widget.enabled ? Colors.white : _kMuted,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── _AssistButton ───────────────────────────────────────────────────────────
class _AssistButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AssistButton({required this.onTap});

  @override
  State<_AssistButton> createState() => _AssistButtonState();
}

class _AssistButtonState extends State<_AssistButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: _hover ? _kCrimson : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _kCrimson, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Apply for Assistance',
                style: GoogleFonts.dmSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.04 * 13.5,
                  color: _hover ? Colors.white : _kCrimson,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  size: 15,
                  color: _hover ? Colors.white : _kCrimson),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _HistoryRow ──────────────────────────────────────────────────────────────
class _HistoryRow extends StatelessWidget {
  final String label, amount, date;
  const _HistoryRow({
    required this.label,
    required this.amount,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: _kParchment,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w500, fontSize: 14, color: _kInk)),
            Text(date,
                style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted)),
          ]),
          Text(amount,
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: _kGreenFg)),
        ],
      ),
    );
  }
}

// ─── _DetailRow ───────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isSuccess;
  const _DetailRow({
    required this.label,
    required this.value,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.dmSans(fontSize: 14, color: _kMuted)),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSuccess ? _kGreenFg : _kInk,
          ),
        ),
      ],
    );
  }
}

// ─── _EcoCashDialog ───────────────────────────────────────────────────────────
class _EcoCashDialog extends StatefulWidget {
  final double amount;
  final String email;
  final void Function(String pollUrl) onSuccess;

  const _EcoCashDialog({
    required this.amount,
    required this.email,
    required this.onSuccess,
  });

  @override
  State<_EcoCashDialog> createState() => _EcoCashDialogState();
}

class _EcoCashDialogState extends State<_EcoCashDialog> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  static final _validPrefix = RegExp(r'^07[1378]\d{7}$');

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final phone = _phoneCtrl.text.trim();
    if (phone.length != 10 || !phone.startsWith('0')) {
      setState(() => _error = 'Phone number must be exactly 10 digits');
      return false;
    }
    if (!_validPrefix.hasMatch(phone)) {
      setState(() => _error = 'Number must start with 077, 078, 073, or 071');
      return false;
    }
    setState(() => _error = null);
    return true;
  }

  Future<void> _confirm() async {
    if (!_validate() || _loading) return;
    setState(() => _loading = true);

    final phone = _phoneCtrl.text.trim();
    final reference = 'APP-FEE-${DateTime.now().millisecondsSinceEpoch}';

    final result = await PaymentService.initiateEcoCash(
      phone: phone,
      amount: widget.amount,
      email: widget.email,
      reference: reference,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.of(context).pop();
      widget.onSuccess(result['pollUrl'] as String);
    } else {
      setState(() {
        _loading = false;
        _error = result['error'] as String? ?? 'Payment initiation failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: _kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kCrimsonPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_android_rounded,
                    color: _kCrimson, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay with EcoCash',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _kInk,
                    ),
                  ),
                  Text(
                    '\$${widget.amount.toStringAsFixed(2)} Application Fee',
                    style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: _loading ? null : () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: _kCrimsonPale,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: _kCrimson.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_outlined,
                    color: _kCrimson, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Amount to pay',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: _kInkMid),
                ),
                const Spacer(),
                Text(
                  '\$${widget.amount.toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kCrimson,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Phone label
          Text(
            'EcoCash Phone Number',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _kInkMid,
            ),
          ),
          const SizedBox(height: 8),

          // Phone field
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            enabled: !_loading,
            decoration: InputDecoration(
              hintText: 'e.g. 0771234567',
              hintStyle:
                  GoogleFonts.dmSans(color: _kMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.phone_rounded,
                  color: _kMuted, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: _error != null ? _kCrimson : _kBorder,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: _kCrimson, width: 1.5),
              ),
              filled: true,
              fillColor: _kParchment,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
            ),
            style:
                GoogleFonts.dmSans(fontSize: 14, color: _kInk),
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
          ),

          // Inline error
          if (_error != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: _kCrimson, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style:
                        GoogleFonts.dmSans(fontSize: 12, color: _kCrimson),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _loading ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kCrimson,
                disabledBackgroundColor: _kCrimsonPale,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Confirm Payment',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _WaitingDialog ───────────────────────────────────────────────────────────
class _WaitingDialog extends StatelessWidget {
  const _WaitingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: _kCrimsonPale,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android_rounded,
                  color: _kCrimson, size: 36),
            ),
            const SizedBox(height: 24),
            Text(
              'Check your phone',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'A prompt has been sent to your EcoCash number. Enter your PIN to complete payment.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: _kMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(color: _kCrimson),
            const SizedBox(height: 16),
            Text(
              'Waiting for confirmation...',
              style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlutterwaveWaitingDialog extends StatefulWidget {
  const _FlutterwaveWaitingDialog({
    required this.txRef,
    required this.onVerified,
  });

  final String txRef;
  final void Function(bool success) onVerified;

  @override
  State<_FlutterwaveWaitingDialog> createState() => _FlutterwaveWaitingDialogState();
}

class _FlutterwaveWaitingDialogState extends State<_FlutterwaveWaitingDialog> {
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startVerification();
  }

  Future<void> _startVerification() async {
    setState(() => _verifying = true);

    // Wait a bit for user to complete payment, then start polling
    await Future.delayed(const Duration(seconds: 3));

    const maxAttempts = 20;
    const interval = Duration(seconds: 3);

    for (int i = 0; i < maxAttempts; i++) {
      if (!mounted) return;

      try {
        final response = await FlutterwaveService().verifyTransaction(txRef: widget.txRef);
        if (!mounted) return;

        if (response.success) {
          widget.onVerified(true);
          return;
        }

        // If not successful yet, wait and try again
        if (response.status != 'successful') {
          await Future.delayed(interval);
          continue;
        }
      } catch (e) {
        // Continue polling on error
        await Future.delayed(interval);
      }
    }

    // Timed out
    if (mounted) {
      widget.onVerified(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _kCrimson.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payment_rounded,
                  color: _kCrimson, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Complete Payment',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please complete the payment in your browser. This dialog will close automatically once payment is confirmed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: _kMuted, height: 1.5),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(color: _kCrimson),
            const SizedBox(height: 16),
            Text(
              _verifying ? 'Verifying payment...' : 'Preparing verification...',
              style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted),
            ),
          ],
        ),
      ),
    );
  }
}
