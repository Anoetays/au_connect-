import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VisaGuidanceScreen extends StatefulWidget {
  const VisaGuidanceScreen({super.key});

  @override
  State<VisaGuidanceScreen> createState() => _VisaGuidanceScreenState();
}

class _VisaGuidanceScreenState extends State<VisaGuidanceScreen> {
  static const _navy = Color(0xFF0D3B6E);
  static const _gold = Color(0xFFC9952A);
  static const _crimson = Color(0xFFB22234);

  // Expanded state per step
  final List<bool> _expanded = [true, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _guardAccess();
  }

  Future<void> _guardAccess() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        _redirect();
        return;
      }
      final row = await Supabase.instance.client
          .from('applications')
          .select('applicant_type')
          .eq('user_id', uid)
          .maybeSingle();

      final type = row?['applicant_type'] as String? ?? '';
      if (type != 'international') _redirect();
    } catch (_) {
      // On any error, allow access — don't block the user
    }
  }

  void _redirect() {
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/onboarding_dashboard');
  }

  void _launchEmail() async {
    // Using Navigator to show a snack since url_launcher is already a dep
    // but we don't import it here to avoid any issues — show info instead
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email: international@africau.edu'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: Column(
        children: [
          // ── App bar (navy) ─────────────────────────────────────────
          Container(
            color: _navy,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Visa Guidance',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'AU',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero section (navy gradient) ─────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D3B6E), Color(0xFF092B52)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🤖', style: TextStyle(fontSize: 12)),
                              SizedBox(width: 6),
                              Text(
                                'AI VISA ASSISTANT',
                                style: TextStyle(
                                  color: Color(0xD9FFFFFF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          alignment: Alignment.center,
                          child: const Text('🛂', style: TextStyle(fontSize: 26)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Hi! I'm here to help with your Zimbabwe Visa & Study Permit.",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "As a non-resident international student, here are the exact steps you need to follow to legally study at Africa University.",
                          style: TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Intro info card ──────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FD),
                        border: Border.all(color: const Color(0xFFB8DCF5)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ℹ️', style: TextStyle(fontSize: 20)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1A4A6E),
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(text: 'Zimbabwe student visas are managed by the '),
                                  TextSpan(
                                    text: 'Department of Immigration',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: '. The process typically takes '),
                                  TextSpan(
                                    text: '4–8 weeks',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: '. Start early alongside your admission process.'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Section title ────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text(
                      'Step-by-Step Process',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),

                  // ── Step cards ───────────────────────────────────
                  _StepCard(
                    index: 0,
                    color: _crimson,
                    number: '1',
                    title: 'Receive Offer Letter from AU',
                    subtitle: 'Required before applying for your visa',
                    isExpanded: _expanded[0],
                    onToggle: () => setState(() => _expanded[0] = !_expanded[0]),
                    docs: const [
                      ('📄', 'Wait for your official AU Offer/Acceptance Letter'),
                      ('📄', 'Ensure it states your programme, duration & start date'),
                      ('✅', 'Download it from your AU Connect dashboard'),
                    ],
                    tip: 'Your offer letter is generated automatically once your application is approved — you\'ll receive a notification.',
                  ),

                  _StepCard(
                    index: 1,
                    color: _navy,
                    number: '2',
                    title: 'Apply for Student Visa',
                    subtitle: 'At Zimbabwe Embassy in your home country',
                    isExpanded: _expanded[1],
                    onToggle: () => setState(() => _expanded[1] = !_expanded[1]),
                    docs: const [
                      ('🛂', 'Valid passport (min. 6 months beyond study period)'),
                      ('📋', 'Completed Visa Application Form (Form 4)'),
                      ('📄', 'Original AU Offer Letter'),
                      ('💰', 'Proof of sufficient funds (bank statement)'),
                      ('🏥', 'Medical certificate & HIV test results'),
                      ('🖼️', 'Passport-size photos (×4)'),
                    ],
                    tip: 'Visit the nearest Zimbabwe Embassy or High Commission. Fee is approximately USD \$50–\$100 depending on nationality.',
                  ),

                  _StepCard(
                    index: 2,
                    color: _gold,
                    number: '3',
                    title: 'Apply for Study Permit',
                    subtitle: 'Separate from the visa — done on arrival or via embassy',
                    isExpanded: _expanded[2],
                    onToggle: () => setState(() => _expanded[2] = !_expanded[2]),
                    docs: const [
                      ('📋', 'Complete Zimbabwe Study Permit Application'),
                      ('📄', 'AU Offer Letter (certified copy)'),
                      ('📜', 'Academic certificates (O-Level, A-Level or equivalent)'),
                      ('🏥', 'Medical / health clearance certificate'),
                      ('💰', 'Permit fee: approx. USD \$300'),
                    ],
                    tip: 'Study permits are issued by Zimbabwe\'s Dept. of Immigration. AU\'s International Students Office can assist — see contacts below.',
                  ),

                  _StepCard(
                    index: 3,
                    color: const Color(0xFF1A7A4A),
                    number: '4',
                    title: 'Travel to Zimbabwe',
                    subtitle: 'Arrive with all documents ready',
                    isExpanded: _expanded[3],
                    onToggle: () => setState(() => _expanded[3] = !_expanded[3]),
                    docs: const [
                      ('✈️', 'Book flights to Harare (HRE) — closest to Mutare/AU'),
                      ('🧳', 'Carry originals of all documents'),
                      ('🏫', 'Report to AU International Students Office on arrival'),
                    ],
                    tip: 'Africa University is located in Mutare. Bus connections from Harare take approx. 3 hours.',
                  ),

                  _StepCard(
                    index: 4,
                    color: const Color(0xFF6A3D9A),
                    number: '5',
                    title: 'Register & Enrol at AU',
                    subtitle: 'Final step — complete your enrolment',
                    isExpanded: _expanded[4],
                    onToggle: () => setState(() => _expanded[4] = !_expanded[4]),
                    docs: const [
                      ('✅', 'Submit Study Permit to AU Registrar\'s Office'),
                      ('💳', 'Pay first semester tuition fees'),
                      ('🎓', 'Collect student ID and class schedule'),
                    ],
                    tip: null,
                  ),

                  // ── Contact card ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: _crimson,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Text('📞', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AU International Office',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'international@africau.edu',
                                  style: TextStyle(color: Color(0xBFFFFFFF), fontSize: 12),
                                ),
                                Text(
                                  '+263 20 2060  |  Mon–Fri 8am–4pm',
                                  style: TextStyle(color: Color(0xBFFFFFFF), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: _launchEmail,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Contact',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step expansion card ───────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  final int index;
  final Color color;
  final String number;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final List<(String, String)> docs;
  final String? tip;

  const _StepCard({
    required this.index,
    required this.color,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    required this.docs,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: onToggle,
              borderRadius: isExpanded
                  ? const BorderRadius.vertical(top: Radius.circular(14))
                  : BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6C757D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFFADB5BD),
                    ),
                  ],
                ),
              ),
            ),

            // Body
            if (isExpanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ...docs.map((item) => _DocRow(emoji: item.$1, text: item.$2)),
                    if (tip != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '💡 $tip',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6C757D),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DocRow extends StatelessWidget {
  final String emoji;
  final String text;

  const _DocRow({required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F3F5))),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF343A40)),
            ),
          ),
        ],
      ),
    );
  }
}
