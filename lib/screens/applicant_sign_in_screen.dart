import 'package:flutter/material.dart';
import 'package:au_connect/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/auth_service.dart';

class ApplicantSignInScreen extends StatefulWidget {
  const ApplicantSignInScreen({super.key});

  @override
  State<ApplicantSignInScreen> createState() => _ApplicantSignInScreenState();
}

class _ApplicantSignInScreenState extends State<ApplicantSignInScreen>
    with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(
        parent: _ctrl, curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailCtrl = TextEditingController(text: _emailCtrl.text.trim());
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.resetPassword,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Enter your email address and we will send you a password reset link.',
              style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'your@email.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primary),
                ),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white),
              onPressed: () async {
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await _authService.resetPassword(email);
                  if (mounted) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('Password reset link sent to $email'),
                      backgroundColor: AppTheme.statusApproved,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(SnackBar(
                      content: Text('Failed to send reset email: $e'),
                    ));
                  }
                }
              },
              child: Text(l10n.sendResetLink),
            ),
          ],
        );
      },
    );
    emailCtrl.dispose();
  }

  Future<void> _signIn() async {
    if (_emailCtrl.text.trim().isEmpty || _passwordCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailAndPassword(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/applicant_type_selection');
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sign-in failed: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          _Blob(top: -160, right: -120, size: 400, opacity: 0.09),
          _Blob(bottom: -180, left: -100, size: 460, opacity: 0.08),
          // Top accent bar
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.primaryDark, AppTheme.primary, Color(0xFFE85070), AppTheme.primary
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) => Opacity(
                    opacity: _anim.value,
                    child: Transform.translate(
                      offset: Offset(0, 22 * (1 - _anim.value)),
                      child: child,
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.10),
                            blurRadius: 80,
                            offset: const Offset(0, 24),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNav(context),
                          _buildHero(context),
                          _buildForm(l10n),
                          _buildActions(l10n),
                          _buildFooter(l10n),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _NavBackButton(onTap: () => Navigator.pop(context)),
          ),
          Text(
            'AU Connect',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
              letterSpacing: 0.3,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
      child: Column(
        children: [
          _LogoRing(),
          const SizedBox(height: 16),
          const Text(
            'AFRICA UNIVERSITY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 3.5,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.dmSerifDisplay(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
                height: 1.1,
              ),
              children: const [
                TextSpan(text: 'Welcome '),
                TextSpan(
                  text: 'Back',
                  style: TextStyle(
                      color: AppTheme.primary, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.signInToContinue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: AppTheme.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      child: Column(
        children: [
          _FieldBox(
            label: l10n.email,
            controller: _emailCtrl,
            hint: 'name@example.com',
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _FieldBox(
            label: l10n.password,
            controller: _passwordCtrl,
            hint: 'Enter your password',
            prefixIcon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            showToggle: true,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            labelSuffix: GestureDetector(
              onTap: () => _showForgotPasswordDialog(context),
              child: Text(
                l10n.forgotPassword,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Remember me
          GestureDetector(
            onTap: () => setState(() => _rememberMe = !_rememberMe),
            child: Row(
              children: [
                _Checkbox(value: _rememberMe),
                const SizedBox(width: 8),
                Text(
                  l10n.rememberMe,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      child: Column(
        children: [
          // Primary button
          GestureDetector(
            onTap: _isLoading ? null : _signIn,
            child: _PrimaryButton(
              label: l10n.signIn,
              icon: Icons.login_rounded,
              loading: _isLoading,
            ),
          ),
          const SizedBox(height: 14),
          _OrDivider(),
          const SizedBox(height: 14),
          // Secondary button
          GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, '/applicant_sign_up'),
            child: _SecondaryButton(label: l10n.createAccount),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
      child: Column(
        children: [
          Divider(color: AppTheme.primaryLight, thickness: 1),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              Text(
                '${l10n.needHelp} ',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w300,
                  color: AppTheme.textMuted,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/chatbot_dashboard'),
                child: Text(
                  l10n.contactAdmissions,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared private widgets ────────────────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double? top, bottom, left, right, size;
  final double opacity;
  const _Blob({this.top, this.bottom, this.left, this.right, required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Positioned(
        top: top, bottom: bottom, left: left, right: right,
        child: IgnorePointer(
          child: Container(
            width: size, height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primary.withValues(alpha: opacity),
                  AppTheme.primary.withValues(alpha: opacity * 0.4),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.6, 0.85],
              ),
            ),
          ),
        ),
      );
}

class _NavBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _NavBackButton({required this.onTap});

  @override
  State<_NavBackButton> createState() => _NavBackButtonState();
}

class _NavBackButtonState extends State<_NavBackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 34, height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface,
            border: Border.all(
              color: _hovered
                  ? AppTheme.primary
                  : AppTheme.primary.withValues(alpha: 0.14),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary
                    .withValues(alpha: _hovered ? 0.15 : 0.07),
                blurRadius: _hovered ? 14 : 8,
              ),
            ],
          ),
          child: const Icon(Icons.chevron_left_rounded,
              size: 18, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

class _LogoRing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.18),
            blurRadius: 28, offset: const Offset(0, 8),
          ),
          BoxShadow(color: AppTheme.primaryLight, spreadRadius: 6),
        ],
      ),
      child: Center(
        child: Container(
          width: 48, height: 48,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTheme.primary, AppTheme.primaryDark],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _FieldBox extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextEditingController? controller;
  final bool obscure;
  final bool showToggle;
  final VoidCallback? onToggle;
  final TextInputType? keyboardType;
  final Widget? labelSuffix;

  const _FieldBox({
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.controller,
    this.obscure = false,
    this.showToggle = false,
    this.onToggle,
    this.keyboardType,
    this.labelSuffix,
  });

  @override
  State<_FieldBox> createState() => _FieldBoxState();
}

class _FieldBoxState extends State<_FieldBox> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                letterSpacing: 0.1,
              ),
            ),
            if (widget.labelSuffix != null) widget.labelSuffix!,
          ],
        ),
        const SizedBox(height: 6),
        // Input wrap
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused
                  ? AppTheme.primary
                  : AppTheme.primary.withValues(alpha: 0.14),
              width: 1.5,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.09),
                      spreadRadius: 3,
                      blurRadius: 0,
                    )
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Left accent stripe
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: _focused ? 3 : 0,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryDark],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        widget.prefixIcon,
                        size: 18,
                        color: _focused
                            ? AppTheme.primary
                            : AppTheme.textMuted,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focus,
                        obscureText: widget.obscure,
                        keyboardType: widget.keyboardType,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w300,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          hintStyle: const TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w300,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (widget.showToggle)
                      GestureDetector(
                        onTap: widget.onToggle,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            widget.obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool value;
  const _Checkbox({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 18, height: 18,
      decoration: BoxDecoration(
        color: value ? AppTheme.primary : AppTheme.surface,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: value ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.14),
          width: 1.5,
        ),
      ),
      child: value
          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
          : null,
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool loading;
  const _PrimaryButton({required this.label, required this.icon, this.loading = false});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryDark],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: _hovered ? 0.42 : 0.38),
              blurRadius: _hovered ? 32 : 22,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: widget.loading
            ? const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(widget.icon, color: Colors.white, size: 16),
                ],
              ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppTheme.border, Colors.transparent],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l10n.or,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.6,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppTheme.border, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatefulWidget {
  final String label;
  const _SecondaryButton({required this.label});

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? AppTheme.border : AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? AppTheme.primary.withValues(alpha: 0.28)
                : AppTheme.primary.withValues(alpha: 0.14),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppTheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
