import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _pwConfirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  bool _changingPw = false;
  bool _showPw = false;
  String? _email;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _pwCtrl.dispose();
    _pwConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await SupabaseService.getProfile();
      if (!mounted) return;
      _email = SupabaseService.currentUser?.email ?? '';
      _nameCtrl.text = profile?['full_name'] as String? ?? '';
      _phoneCtrl.text = profile?['phone'] as String? ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load profile.';
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });
    try {
      await SupabaseService.upsertProfile({
        'full_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _saving = false;
        _success = 'Profile updated successfully.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Failed to save changes: $e';
      });
    }
  }

  Future<void> _changePassword() async {
    final pw = _pwCtrl.text.trim();
    final confirm = _pwConfirmCtrl.text.trim();
    if (pw.isEmpty) {
      setState(() => _error = 'Enter a new password.');
      return;
    }
    if (pw != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    setState(() {
      _changingPw = true;
      _error = null;
      _success = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: pw),
      );
      if (!mounted) return;
      _pwCtrl.clear();
      _pwConfirmCtrl.clear();
      setState(() {
        _changingPw = false;
        _success = 'Password changed successfully.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _changingPw = false;
        _error = 'Failed to change password: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryCrimson))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: _buildForm(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios_new,
                      size: 16, color: AppTheme.primaryCrimson),
                  const SizedBox(width: 6),
                  Text('Back',
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryCrimson)),
                ],
              ),
            ),
            const Spacer(),
            Text('Settings',
                style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            const Spacer(),
            const SizedBox(width: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Profile Settings',
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 26,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 28),

          // ── Feedback ──────────────────────────────────────────────────────
          if (_error != null) ...[
            _buildAlert(_error!, isError: true),
            const SizedBox(height: 16),
          ],
          if (_success != null) ...[
            _buildAlert(_success!, isError: false),
            const SizedBox(height: 16),
          ],

          // ── Account info ─────────────────────────────────────────────────
          _buildSection('Account Information', [
            _buildLabel('Display Name'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            _buildLabel('Email Address'),
            const SizedBox(height: 6),
            TextFormField(
              initialValue: _email,
              readOnly: true,
              style: const TextStyle(color: AppTheme.textMuted),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppTheme.background,
                suffixIcon: const Icon(Icons.lock_outline,
                    size: 16, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            _buildLabel('Phone Number'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '+263 7X XXX XXXX'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryCrimson,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text('Save Changes',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ]),

          const SizedBox(height: 28),

          // ── Change password ───────────────────────────────────────────────
          _buildSection('Change Password', [
            _buildLabel('New Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pwCtrl,
              obscureText: !_showPw,
              decoration: InputDecoration(
                hintText: 'At least 6 characters',
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showPw = !_showPw),
                  child: Icon(
                    _showPw
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildLabel('Confirm Password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _pwConfirmCtrl,
              obscureText: true,
              decoration:
                  const InputDecoration(hintText: 'Repeat new password'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: _changingPw ? null : _changePassword,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryCrimson,
                  side: const BorderSide(color: AppTheme.primaryCrimson),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _changingPw
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryCrimson)))
                    : Text('Change Password',
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title,
              style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0.3),
    );
  }

  Widget _buildAlert(String msg, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? AppTheme.primaryLight : const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isError
                ? AppTheme.primaryCrimson.withValues(alpha: 0.3)
                : const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? AppTheme.primaryCrimson : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isError
                    ? AppTheme.primaryCrimson
                    : const Color(0xFF166534),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
