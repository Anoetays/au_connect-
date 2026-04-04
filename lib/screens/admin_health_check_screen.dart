import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:au_connect/theme/app_theme.dart';

class AdminHealthCheckScreen extends StatefulWidget {
  const AdminHealthCheckScreen({super.key});

  @override
  State<AdminHealthCheckScreen> createState() => _AdminHealthCheckScreenState();
}

class _AdminHealthCheckScreenState extends State<AdminHealthCheckScreen> {
  bool _loading = true;
  String? _error;

  String? _userId;
  String? _profileRole;
  bool? _isAdminByRpc;

  int? _applicationsVisible;
  int? _documentsVisible;
  int? _adminNotificationsVisible;

  bool _realtimeConnected = false;
  int _realtimeEvents = 0;
  int _lastRealtimePayloadSize = 0;
  DateTime? _lastRealtimeEventAt;
  String? _realtimeError;

  StreamSubscription<List<Map<String, dynamic>>>? _appStreamSub;
  Timer? _probeTimeout;

  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  @override
  void dispose() {
    _appStreamSub?.cancel();
    _probeTimeout?.cancel();
    super.dispose();
  }

  Future<void> _runChecks() async {
    setState(() {
      _loading = true;
      _error = null;
      _userId = null;
      _profileRole = null;
      _isAdminByRpc = null;
      _applicationsVisible = null;
      _documentsVisible = null;
      _adminNotificationsVisible = null;
      _realtimeConnected = false;
      _realtimeEvents = 0;
      _lastRealtimePayloadSize = 0;
      _lastRealtimeEventAt = null;
      _realtimeError = null;
    });

    final user = _db.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Not authenticated. Please sign in as an admin user.';
      });
      return;
    }

    _userId = user.id;

    try {
      final profile = await _db
          .from('profiles')
          .select('role')
          .eq('user_id', user.id)
          .maybeSingle();
      _profileRole = profile?['role'] as String?;
    } catch (e) {
      _error = 'Failed to resolve profile role: $e';
    }

    try {
      final result = await _db.rpc('is_admin');
      _isAdminByRpc = result == true;
    } catch (e) {
      _isAdminByRpc = null;
      _error ??= 'RPC check is_admin failed: $e';
    }

    try {
      final apps = await _db.from('applications').select('id');
      _applicationsVisible = (apps as List).length;
    } catch (e) {
      _error ??= 'applications visibility check failed: $e';
    }

    try {
      final docs = await _db.from('documents').select('id');
      _documentsVisible = (docs as List).length;
    } catch (e) {
      _error ??= 'documents visibility check failed: $e';
    }

    try {
      final notifications = await _db
          .from('notifications')
          .select('id')
          .eq('recipient_role', 'admin');
      _adminNotificationsVisible = (notifications as List).length;
    } catch (e) {
      _error ??= 'notifications visibility check failed: $e';
    }

    _startRealtimeProbe();

    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _startRealtimeProbe() {
    _appStreamSub?.cancel();
    _probeTimeout?.cancel();

    _appStreamSub = _db
        .from('applications')
        .stream(primaryKey: ['id'])
        .order('submitted_at', ascending: false)
        .listen(
      (rows) {
        if (!mounted) return;
        setState(() {
          _realtimeConnected = true;
          _realtimeEvents += 1;
          _lastRealtimePayloadSize = rows.length;
          _lastRealtimeEventAt = DateTime.now();
          _realtimeError = null;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _realtimeConnected = false;
          _realtimeError = 'Realtime stream error: $e';
        });
      },
    );

    _probeTimeout = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_realtimeEvents == 0) {
        setState(() {
          _realtimeConnected = false;
          _realtimeError = 'No realtime event received within 10 seconds.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        title: Text(
          'Admin Health Check',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _runChecks,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  if (_error != null)
                    _card(
                      title: 'Errors',
                      child: Text(
                        _error!,
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  _card(
                    title: 'Role Resolution',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Current user id', _userId ?? 'N/A'),
                        _row('Profile role', _profileRole ?? 'N/A'),
                        _row('RPC is_admin()', _isAdminByRpc == null ? 'N/A' : _isAdminByRpc! ? 'true' : 'false'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: 'Policy-Visible Rows',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('applications', _applicationsVisible?.toString() ?? 'N/A'),
                        _row('documents', _documentsVisible?.toString() ?? 'N/A'),
                        _row('notifications (admin role)', _adminNotificationsVisible?.toString() ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _card(
                    title: 'Realtime Probe',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row('Connected', _realtimeConnected ? 'yes' : 'no'),
                        _row('Events received', _realtimeEvents.toString()),
                        _row('Last payload size', _lastRealtimePayloadSize.toString()),
                        _row(
                          'Last event',
                          _lastRealtimeEventAt == null
                              ? 'N/A'
                              : _lastRealtimeEventAt!.toIso8601String(),
                        ),
                        if (_realtimeError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _realtimeError!,
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _runChecks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Run Checks Again'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 190,
            child: Text(
              '$label:',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 13.5,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
