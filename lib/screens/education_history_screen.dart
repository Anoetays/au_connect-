import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:au_connect/theme/app_theme.dart';
import 'package:au_connect/models/school_record.dart';

class EducationHistoryScreen extends StatefulWidget {
  final List<SchoolRecord> initialRecords;

  const EducationHistoryScreen({
    super.key,
    this.initialRecords = const [],
  });

  @override
  State<EducationHistoryScreen> createState() => _EducationHistoryScreenState();
}

class _EducationHistoryScreenState extends State<EducationHistoryScreen>
    with TickerProviderStateMixin {
  late List<SchoolRecord> _records;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool get _isComplete => _records.any((r) => r.hasTranscript);

  @override
  void initState() {
    super.initState();
    _records = List.of(widget.initialRecords);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _addSchool() async {
    final record = await Navigator.push<SchoolRecord?>(
      context,
      MaterialPageRoute(builder: (_) => const _AddSchoolScreen()),
    );

    if (record != null) {
      setState(() {
        _records.add(record);
      });
    }
  }

  Future<void> _editSchool(int index) async {
    final existing = _records[index];
    final updatedRecord = await Navigator.push<SchoolRecord?>(
      context,
      MaterialPageRoute(builder: (_) => _AddSchoolScreen(initialRecord: existing)),
    );

    if (updatedRecord != null) {
      setState(() {
        _records[index] = updatedRecord;
      });
    }
  }

  void _saveAndReturn() {
    Navigator.pop(context, _records);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _records);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Education History'),
          backgroundColor: isDark ? AppTheme.backgroundDark : null,
          actions: [
            TextButton(
              onPressed: _saveAndReturn,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add the schools you have attended. You will need to upload transcripts or academic certificates for each institution.',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isComplete ? 'Complete' : 'Incomplete',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isComplete ? AppTheme.primary : (isDark ? Colors.grey[300] : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _records.isEmpty
                        ? Center(
                            child: Text(
                              'No schools added yet. Tap + Add School to begin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _records.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final record = _records[index];
                              return _SchoolCard(
                                record: record,
                                onEdit: () => _editSchool(index),
                              );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addSchool,
                  icon: const Icon(Icons.add),
                  label: const Text('+ Add School'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SchoolCard extends StatelessWidget {
  final SchoolRecord record;
  final VoidCallback? onEdit;

  const _SchoolCard({
    required this.record,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  record.schoolName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    record.hasTranscript ? Icons.check_circle : Icons.error_outline,
                    color: record.hasTranscript ? AppTheme.primary : (isDark ? Colors.grey[400] : const Color(0xFF94A3B8)),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    record.hasTranscript ? 'Transcript uploaded' : 'Transcript missing',
                    style: TextStyle(
                      fontSize: 12,
                      color: record.hasTranscript ? AppTheme.primary : (isDark ? Colors.grey[400] : const Color(0xFF94A3B8)),
                    ),
                  ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 12),
                    Tooltip(
                      message: 'Edit school',
                      child: InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: isDark ? Colors.grey[200] : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            record.qualification,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            record.currentlyStudying
                ? '${_formatDate(record.startDate)} - Present'
                : '${_formatDate(record.startDate)} - ${_formatDate(record.endDate ?? record.startDate)}',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _AddSchoolScreen extends StatefulWidget {
  final SchoolRecord? initialRecord;

  const _AddSchoolScreen({
    this.initialRecord,
  });

  @override
  State<_AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<_AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _fieldOfStudyController = TextEditingController();
  String? _country;
  InstitutionType? _institutionType;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _currentlyStudying = false;
  String? _transcriptFilePath;

  bool get _isEditing => widget.initialRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    if (record != null) {
      _schoolNameController.text = record.schoolName;
      _qualificationController.text = record.qualification;
      _fieldOfStudyController.text = record.fieldOfStudy ?? '';
      _country = record.country;
      _institutionType = record.institutionType;
      _startDate = record.startDate;
      _endDate = record.endDate;
      _currentlyStudying = record.currentlyStudying;
      _transcriptFilePath = record.transcriptFilePath;
    }
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _qualificationController.dispose();
    _fieldOfStudyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final initial = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickTranscriptFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    setState(() {
      _transcriptFilePath = file.path;
    });
  }

  void _saveRecord() {
    if (!_formKey.currentState!.validate()) return;

    if (_transcriptFilePath == null || _transcriptFilePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript required for this institution before continuing.')),
      );
      return;
    }

    final record = SchoolRecord(
      schoolName: _schoolNameController.text.trim(),
      country: _country ?? '',
      institutionType: _institutionType ?? InstitutionType.highSchool,
      qualification: _qualificationController.text.trim(),
      fieldOfStudy: _fieldOfStudyController.text.trim().isEmpty ? null : _fieldOfStudyController.text.trim(),
      startDate: _startDate ?? DateTime.now(),
      endDate: _currentlyStudying ? null : (_endDate ?? DateTime.now()),
      currentlyStudying: _currentlyStudying,
      transcriptFilePath: _transcriptFilePath ?? '',
    );

    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit School' : 'Add School'),
        backgroundColor: isDark ? AppTheme.backgroundDark : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  controller: _schoolNameController,
                  label: 'School Name',
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildDropdown<String>(
                  label: 'Country of Institution',
                  value: _country,
                  items: const ['Zimbabwe', 'United States', 'United Kingdom', 'Canada', 'Other'],
                  onChanged: (value) => setState(() => _country = value),
                ),
                const SizedBox(height: 16),
                _buildDropdown<InstitutionType>(
                  label: 'Type of Institution',
                  value: _institutionType,
                  items: InstitutionType.values,
                  itemLabel: (t) => t.label,
                  onChanged: (value) => setState(() => _institutionType = value),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _qualificationController,
                  label: 'Qualification or Program',
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _fieldOfStudyController,
                  label: 'Field of Study (optional)',
                  validator: (_) => null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildDatePicker(
                        context,
                        label: 'Start Date',
                        date: _startDate,
                        onTap: () => _pickDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDatePicker(
                        context,
                        label: 'End Date',
                        date: _currentlyStudying ? null : _endDate,
                        onTap: () {
                          if (_currentlyStudying) return;
                          _pickDate(context, false);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: _currentlyStudying,
                      onChanged: (value) => setState(() => _currentlyStudying = value ?? false),
                    ),
                    const Expanded(child: Text('Currently Studying')),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Transcript Upload',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickTranscriptFile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.upload_file, color: AppTheme.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Upload Transcript or Academic Record – PDF, JPG, or PNG – Maximum size 10MB.',
                                style: TextStyle(
                                  color: isDark ? Colors.grey[300] : const Color(0xFF475569),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_transcriptFilePath != null && _transcriptFilePath!.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      Uri.file(_transcriptFilePath!).pathSegments.last,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _transcriptFilePath = null;
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Remove transcript',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14.0),
                          child: Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          child: Text(_isEditing ? 'Update School Record' : 'Save School Record'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required void Function(T?) onChanged,
    String Function(T)? itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel?.call(item) ?? item.toString()),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Required' : null,
    );
  }

  Widget _buildDatePicker(
    BuildContext context, {
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final display = date == null ? 'Select date' : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label: $display',
                style: TextStyle(
                  color: date == null ? (isDark ? Colors.grey[400] : const Color(0xFF94A3B8)) : (isDark ? AppTheme.textLight : AppTheme.textDark),
                ),
              ),
            ),
            Icon(Icons.calendar_month, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
