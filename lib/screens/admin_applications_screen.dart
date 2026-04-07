import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  State<AdminApplicationsScreen> createState() => _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  List<dynamic> _applications = [];
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
    setState(() => _loading = true);
    try {
      final statusQuery = _statusFilter == 'all' ? '' : '&status=$_statusFilter';
      final offset = _currentPage * _pageSize;
      
      final response = await http.get(
        Uri.parse(
          'http://localhost:3000/api/admin/applications?offset=$offset&limit=$_pageSize$statusQuery'
        ),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _applications = data['data'] ?? [];
          _totalCount = data['pagination']['total'] ?? 0;
          _error = null;
        });
      } else {
        setState(() => _error = 'Failed to load applications');
      }
    } catch (e) {
      setState(() => _error = 'Error: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateApplicationStatus(int appId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/admin/applications/$appId/review'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': newStatus,
          'reviewNotes': 'Application $newStatus by admin',
          'reviewedBy': 'admin',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application updated to $newStatus')),
        );
        _loadApplications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

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
                            style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'pending',
                        child: Text('Pending',
                            style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'review',
                        child: Text('Under Review',
                            style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'approved',
                        child: Text('Approved',
                            style: GoogleFonts.poppins(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 'rejected',
                        child: Text('Rejected',
                            style: GoogleFonts.poppins(fontSize: 12)),
                      ),
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
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: GoogleFonts.poppins(color: _kRed)),
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
                      child: Text(
                        'No applications found',
                        style: GoogleFonts.poppins(color: _kMuted),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          // Table/List
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: isMobile
                                ? _buildMobileList()
                                : _buildDesktopTable(),
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
                                  'Page ${_currentPage + 1} of ${((_totalCount + _pageSize - 1) / _pageSize).ceil()}',
                                  style: GoogleFonts.poppins(),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: ((_currentPage + 1) * _pageSize) < _totalCount
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
                    ),
    );
  }

  Widget _buildDesktopTable() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(
              label: Text('Applicant',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            DataColumn(
              label: Text('Programme',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            DataColumn(
              label: Text('Type',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            DataColumn(
              label: Text('Status',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            DataColumn(
              label: Text('Submitted',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
            DataColumn(
              label: Text('Actions',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
          rows: _applications.map<DataRow>((app) {
            return DataRow(
              cells: [
                DataCell(
                  Text(app['applicant_name'] ?? 'N/A',
                      style: GoogleFonts.poppins(fontSize: 12)),
                ),
                DataCell(
                  Text(app['programme'] ?? 'N/A',
                      style: GoogleFonts.poppins(fontSize: 12)),
                ),
                DataCell(
                  Text(app['type'] ?? 'N/A',
                      style: GoogleFonts.poppins(fontSize: 12)),
                ),
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(app['status'] ?? ''),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      app['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    app['submitted_at'] != null
                        ? _formatDate(app['submitted_at'])
                        : 'N/A',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                DataCell(
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      _updateApplicationStatus(app['id'], value);
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'review',
                        child: Text('Move to Review'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'approved',
                        child: Text('Approve'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'rejected',
                        child: Text('Reject'),
                      ),
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
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: _kBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app['applicant_name'] ?? 'N/A',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${app['programme'] ?? 'N/A'} • ${app['type'] ?? 'N/A'}',
                    style: GoogleFonts.poppins(fontSize: 12, color: _kMuted),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(app['status'] ?? ''),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      app['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Submitted: ${app['submitted_at'] != null ? _formatDate(app['submitted_at']) : 'N/A'}',
                style: GoogleFonts.poppins(fontSize: 11, color: _kMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
