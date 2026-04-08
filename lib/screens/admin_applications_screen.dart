import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const Color _kDark = AppTheme.textPrimary;
const Color _kMuted = AppTheme.textMuted;
const Color _kBorder = Color(0x21B91C1C);
const Color _kBg = AppTheme.background;
const Color _kGreen = AppTheme.statusApproved;
const Color _kAmber = AppTheme.statusPending;
const Color _kRed = AppTheme.primaryCrimson;

class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({Key? key}) : super(key: key);

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  final _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';
  int _currentPage = 0;
  final int _pageSize = 20;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() { _loading = true; _error = null; });
    try {
      final offset = _currentPage * _pageSize;

      // Build query — filters must come before order/range
      var query = _supabase.from('applications').select('*');
      if (_statusFilter != 'all') {
        query = query.eq('status', _statusFilter);
      }

      final rows = await query
          .order('submitted_at', ascending: false)
          .range(offset, offset + _pageSize - 1);

      final list = List<Map<String, dynamic>>.from(rows as List);

      // If we got a full page there may be more; bump total to show Next button
      setState(() {
        _applications = list;
        // Estimate total: if full page returned assume at least one more page
        if (list.length == _pageSize) {
          _totalCount = offset + _pageSize + 1;
        } else {
          _totalCount = offset + list.length;
        }
      });
    } catch (e) {
      setState(() => _error = 'Error loading applications: $e');
      debugPrint('_loadApplications error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateApplicationStatus(dynamic appId, String newStatus) async {
    try {
      await _supabase
          .from('applications')
          .update({'status': newStatus})
          .eq('id', appId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application updated to $newStatus'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadApplications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _kGreen;
      case 'rejected':
        return _kRed;
      case 'review':
      case 'under_review':
        return _kAmber;
      default:
        return _kMuted;
    }
  }

  String _applicantName(Map<String, dynamic> app) {
    final full = (app['full_name'] as String?)?.trim() ?? '';
    if (full.isNotEmpty) return full;
    final first = app['first_name'] ?? '';
    final last = app['last_name'] ?? '';
    final combined = '$first $last'.trim();
    return combined.isNotEmpty ? combined : (app['email'] ?? 'Unknown');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final totalPages =
        _totalCount == 0 ? 1 : ((_totalCount + _pageSize - 1) / _pageSize).ceil();

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Applications Management',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _kDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: _kBorder, width: 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    items: [
                      DropdownMenuItem(
                          value: 'all',
                          child: Text('All Applications',
                              style: GoogleFonts.poppins(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'draft',
                          child: Text('Draft',
                              style: GoogleFonts.poppins(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'submitted',
                          child: Text('Submitted',
                              style: GoogleFonts.poppins(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending',
                              style: GoogleFonts.poppins(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'review',
                          child: Text('Under Review',
                              style: GoogleFonts.poppins(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'approved',
                          child: Text('Approved',
                              style: GoogleFonts.poppins(fontSize: 12))),
                      DropdownMenuItem(
                          value: 'rejected',
                          child: Text('Rejected',
                              style: GoogleFonts.poppins(fontSize: 12))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _statusFilter = value ?? 'all';
                        _currentPage = 0;
                      });
                      _loadApplications();
                    },
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: _kRed, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: GoogleFonts.poppins(color: _kRed),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadApplications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _applications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined,
                              size: 64, color: _kMuted),
                          const SizedBox(height: 12),
                          Text('No applications found',
                              style: GoogleFonts.poppins(color: _kMuted)),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                '$_totalCount application${_totalCount == 1 ? '' : 's'}',
                                style: GoogleFonts.poppins(
                                    fontSize: 13, color: _kMuted),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: isMobile
                                ? _buildMobileList()
                                : _buildDesktopTable(),
                          ),
                        ),
                        // Pagination
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _currentPage > 0
                                    ? () {
                                        setState(() => _currentPage--);
                                        _loadApplications();
                                      }
                                    : null,
                                child: const Text('Previous'),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Page ${_currentPage + 1} of $totalPages',
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: (_currentPage + 1) < totalPages
                                    ? () {
                                        setState(() => _currentPage++);
                                        _loadApplications();
                                      }
                                    : null,
                                child: const Text('Next'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
                label: Text('Applicant',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            DataColumn(
                label: Text('Programme',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            DataColumn(
                label: Text('Level',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            DataColumn(
                label: Text('Type',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            DataColumn(
                label: Text('Status',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            DataColumn(
                label: Text('Submitted',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            DataColumn(
                label: Text('Actions',
                    style:
                        GoogleFonts.poppins(fontWeight: FontWeight.w600))),
          ],
          rows: _applications.map<DataRow>((app) {
            final status = app['status'] ?? 'draft';
            final date = app['submitted_at'] ?? app['created_at'];
            return DataRow(
              cells: [
                DataCell(Text(_applicantName(app),
                    style: GoogleFonts.poppins(fontSize: 12))),
                DataCell(Text(app['programme'] ?? '—',
                    style: GoogleFonts.poppins(fontSize: 12))),
                DataCell(Text(app['study_level'] ?? '—',
                    style: GoogleFonts.poppins(fontSize: 12))),
                DataCell(Text(app['applicant_type'] ?? '—',
                    style: GoogleFonts.poppins(fontSize: 12))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toString().toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
                DataCell(Text(
                  date != null ? _formatDate(date) : '—',
                  style: GoogleFonts.poppins(fontSize: 12),
                )),
                DataCell(
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _updateApplicationStatus(app['id'], value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: 'review',
                          child: Text('Move to Review')),
                      PopupMenuItem(
                          value: 'approved', child: Text('Approve')),
                      PopupMenuItem(
                          value: 'rejected', child: Text('Reject')),
                    ],
                    child: const Icon(Icons.more_vert, size: 18),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _applications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final app = _applications[index];
        final status = app['status'] ?? 'draft';
        final date = app['submitted_at'] ?? app['created_at'];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _applicantName(app),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _updateApplicationStatus(app['id'], value),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                          value: 'review', child: Text('Move to Review')),
                      PopupMenuItem(
                          value: 'approved', child: Text('Approve')),
                      PopupMenuItem(
                          value: 'rejected', child: Text('Reject')),
                    ],
                    child: const Icon(Icons.more_vert, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${app['programme'] ?? '—'} • ${app['study_level'] ?? '—'} • ${app['applicant_type'] ?? '—'}',
                style: GoogleFonts.poppins(fontSize: 12, color: _kMuted),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date != null ? 'Submitted: ${_formatDate(date)}' : 'Not submitted',
                    style: GoogleFonts.poppins(fontSize: 11, color: _kMuted),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status.toString().toUpperCase(),
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
