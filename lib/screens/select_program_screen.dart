import 'dart:async';
import 'package:flutter/material.dart';
import 'package:au_connect/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:au_connect/services/supabase_service.dart';
import 'payments_screen.dart';
import 'package:au_connect/theme/app_theme.dart';

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
const _kGreen        = AppTheme.statusApproved;
const _kGold         = Color(0xFFC89B3C);

// ─── programme data model ─────────────────────────────────────────────────────
class _ProgDef {
  final String name, faculty, years;
  final IconData icon;
  const _ProgDef({
    required this.name,
    required this.faculty,
    required this.years,
    required this.icon,
  });

  factory _ProgDef.fromRow(Map<String, dynamic> r) {
    final fac = r['faculty'] as String? ?? '';
    final dur = r['duration_years'] as int? ?? 4;
    return _ProgDef(
      name: r['name'] as String? ?? '',
      faculty: fac,
      years: '$dur Year${dur != 1 ? "s" : ""}',
      icon: _iconForFaculty(fac),
    );
  }
}

IconData _iconForFaculty(String f) {
  if (f.contains('Commerce'))             return Icons.business_outlined;
  if (f.contains('Science and Tech'))     return Icons.computer_outlined;
  if (f.contains('Health'))               return Icons.local_hospital_outlined;
  if (f.contains('Law'))                  return Icons.balance_outlined;
  return Icons.menu_book_outlined;
}

// ─── featured programme ───────────────────────────────────────────────────────
const _kFeaturedName    = 'Bachelor of Science Honours in Computer Science';
const _kFeaturedFaculty = 'Faculty of Science and Technology';

// ─── step definitions ─────────────────────────────────────────────────────────
enum _StepStatus { done, current, upcoming }

class _StepDef {
  final String name;
  final _StepStatus status;
  const _StepDef(this.name, this.status);
}

const _kSteps = <_StepDef>[
  _StepDef('Personal Details',       _StepStatus.done),
  _StepDef('Educational Background', _StepStatus.done),
  _StepDef('Documents Upload',       _StepStatus.done),
  _StepDef('Select Program',         _StepStatus.current),
  _StepDef('Review & Submit',        _StepStatus.upcoming),
];

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class SelectProgramScreen extends StatefulWidget {
  const SelectProgramScreen({super.key, this.nextRoute});
  final WidgetBuilder? nextRoute;

  @override
  State<SelectProgramScreen> createState() => _SelectProgramScreenState();
}

class _SelectProgramScreenState extends State<SelectProgramScreen> {
  String? _selectedName;
  String? _selectedFaculty;
  bool _saving = false;

  final _searchCtrl = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  StreamSubscription<List<Map<String, dynamic>>>? _sub;

  // ── qualifications form ───────────────────────────────────────────────────
  final List<TextEditingController> _subjectCtrls = [TextEditingController()];
  final List<String> _gradeVals = ['C'];

  // ── eligibility check state ───────────────────────────────────────────────
  bool  _checking  = false;
  bool? _qualifies;                          // null=unchecked, true/false
  List<Map<String, String>> _failedReqs = []; // {subject, required, got}
  List<_ProgDef> _suggestions = [];

  static const _gradeScore = {'A': 5, 'B': 4, 'C': 3, 'D': 2, 'E': 1, 'U': 0};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _query = _searchCtrl.text.toLowerCase()),
    );
    _sub = SupabaseService.streamProgrammes().listen((rows) {
      setState(() {
        _rows = rows.where((r) => r['status'] == 'Active').toList();
        _loading = false;
      });
    }, onError: (_) => setState(() => _loading = false));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    for (final c in _subjectCtrls) { c.dispose(); }
    _sub?.cancel();
    super.dispose();
  }

  // ── data helpers ─────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _rows;
    return _rows.where((r) {
      final name = (r['name'] as String? ?? '').toLowerCase();
      final fac  = (r['faculty'] as String? ?? '').toLowerCase();
      return name.contains(_query) || fac.contains(_query);
    }).toList();
  }

  bool get _showFeatured {
    if (_query.isEmpty) return true;
    return _kFeaturedName.toLowerCase().contains(_query) ||
        _kFeaturedFaculty.toLowerCase().contains(_query);
  }

  List<Map<String, dynamic>> get _nonFeatured =>
      _filtered.where((r) => r['name'] != _kFeaturedName).toList();

  Map<String, List<Map<String, dynamic>>> get _grouped {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final r in _nonFeatured) {
      final fac = r['faculty'] as String? ?? 'Other';
      (result[fac] ??= []).add(r);
    }
    return result;
  }

  // ── selection ────────────────────────────────────────────────────────────────

  void _select(String name, String faculty) {
    if (_selectedName == name) {
      setState(() {
        _selectedName   = null;
        _selectedFaculty = null;
        _qualifies      = null;
        _failedReqs     = [];
        _suggestions    = [];
      });
    } else {
      setState(() {
        _selectedName   = name;
        _selectedFaculty = faculty;
        _qualifies      = null;
        _failedReqs     = [];
        _suggestions    = [];
      });
      _checkEligibility(name, faculty);
    }
  }

  // ── grade helpers ─────────────────────────────────────────────────────────────

  String _gradeStr(int val) {
    const map = {5: 'A', 4: 'B', 3: 'C', 2: 'D', 1: 'E', 0: 'U'};
    return map[val] ?? 'U';
  }

  // ── eligibility check ─────────────────────────────────────────────────────────

  Future<void> _checkEligibility(String name, String faculty) async {
    setState(() { _checking = true; });

    try {
      // Build lookup: subject (lowercase) → score from the form
      final enteredMap = <String, int>{};
      for (int i = 0; i < _subjectCtrls.length; i++) {
        final subj = _subjectCtrls[i].text.trim().toLowerCase();
        if (subj.isNotEmpty) {
          enteredMap[subj] = _gradeScore[_gradeVals[i]] ?? 0;
        }
      }

      // Fetch requirements
      final reqs = await SupabaseService.getProgrammeRequirements(name);
      final compulsory = reqs.where((r) => r['is_compulsory'] == true).toList();

      // No requirements defined → auto-qualify
      if (compulsory.isEmpty) {
        if (mounted) setState(() { _qualifies = true; _checking = false; });
        return;
      }

      // Check each compulsory requirement
      final failed = <Map<String, String>>[];
      for (final req in compulsory) {
        final subj    = (req['subject'] as String? ?? '').toLowerCase();
        final minGrade = req['minimum_grade'] as String? ?? 'U';
        final minVal  = _gradeScore[minGrade] ?? 0;
        final gotVal  = enteredMap[subj];
        if (gotVal == null || gotVal < minVal) {
          failed.add({
            'subject':  req['subject'] as String? ?? '',
            'required': minGrade,
            'got':      gotVal == null ? 'Not entered' : _gradeStr(gotVal),
          });
        }
      }

      if (failed.isEmpty) {
        if (mounted) setState(() { _qualifies = true; _failedReqs = []; _checking = false; });
        return;
      }

      // Find up to 3 qualifying alternatives in the same faculty
      final alternatives = await SupabaseService.getProgrammesByFaculty(faculty);
      final suggestions  = <_ProgDef>[];
      for (final r in alternatives) {
        final altName = r['name'] as String? ?? '';
        if (altName == name) continue;
        final altReqs = await SupabaseService.getProgrammeRequirements(altName);
        final altCompulsory = altReqs.where((x) => x['is_compulsory'] == true).toList();
        var qualifiesAlt = true;
        for (final req in altCompulsory) {
          final subj   = (req['subject'] as String? ?? '').toLowerCase();
          final minVal = _gradeScore[req['minimum_grade'] as String? ?? 'U'] ?? 0;
          final gotVal = enteredMap[subj] ?? -1;
          if (gotVal < minVal) { qualifiesAlt = false; break; }
        }
        if (qualifiesAlt) {
          suggestions.add(_ProgDef.fromRow(r));
          if (suggestions.length >= 3) break;
        }
      }

      if (mounted) {
        setState(() {
          _qualifies   = false;
          _failedReqs  = failed;
          _suggestions = suggestions;
          _checking    = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _checking = false; });
    }
  }

  // ── save & continue ──────────────────────────────────────────────────────────

  Future<void> _saveAndContinue() async {
    if (_selectedName == null || _saving) return;
    setState(() => _saving = true);
    try {
      final app = await SupabaseService.getMyApplication();
      if (app != null) {
        await SupabaseService.updateApplicationProgramme(
          app['id'] as String,
          programme: _selectedName!,
          faculty: _selectedFaculty ?? '',
        );
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: widget.nextRoute ?? (_) => const PaymentsScreen()),
    );
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kParchment,
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (_, cons) {
                final wide = cons.maxWidth >= 860;
                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1020),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 80),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _Sidebar(),
                                  const SizedBox(width: 32),
                                  Expanded(child: _buildMain()),
                                ],
                              )
                            : _buildMain(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMain() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Programs',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 30, fontWeight: FontWeight.w600, color: _kInk,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Curate your future. Select the program that aligns with your vision.',
          style: GoogleFonts.dmSans(fontSize: 13.5, color: _kMuted, height: 1.6),
        ),
        const SizedBox(height: 22),

        // ── qualifications form ─────────────────────────────────────────────
        _QualificationsCard(
          subjectCtrls: _subjectCtrls,
          gradeVals: _gradeVals,
          onGradeChanged: (i, v) => setState(() => _gradeVals[i] = v),
          onAdd: () => setState(() {
            _subjectCtrls.add(TextEditingController());
            _gradeVals.add('C');
          }),
          onRemove: (i) => setState(() {
            if (_subjectCtrls.length > 1) {
              _subjectCtrls[i].dispose();
              _subjectCtrls.removeAt(i);
              _gradeVals.removeAt(i);
            }
          }),
        ),
        const SizedBox(height: 20),

        _SearchBar(controller: _searchCtrl),
        const SizedBox(height: 20),

        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator(color: _kCrimson)),
          )
        else
          _buildGroupedList(),

        // ── eligibility result ──────────────────────────────────────────────
        if (_selectedName != null) ...[
          const SizedBox(height: 20),
          _EligibilityBanner(
            checking:    _checking,
            qualifies:   _qualifies,
            failedReqs:  _failedReqs,
            suggestions: _suggestions,
            onSelectSuggestion: (p) => _select(p.name, p.faculty),
          ),
        ],

        const SizedBox(height: 32),

        _FooterNav(
          onBack: () => Navigator.pop(context),
          onContinue: _saveAndContinue,
          hasSelection: _selectedName != null,
          saving: _saving,
          qualifies: _qualifies,
        ),
      ],
    );
  }

  Widget _buildGroupedList() {
    final grouped = _grouped;
    final hasResults = _showFeatured || grouped.isNotEmpty;

    if (!hasResults) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'No programs match your search.',
            style: GoogleFonts.dmSans(color: _kMuted, fontSize: 14),
          ),
        ),
      );
    }

    final widgets = <Widget>[];

    // Featured card
    if (_showFeatured) {
      widgets.add(_FeaturedCard(
        selected: _selectedName == _kFeaturedName,
        onTap: () => _select(_kFeaturedName, _kFeaturedFaculty),
      ));
      widgets.add(const SizedBox(height: 24));
    }

    // Faculty groups
    for (final entry in grouped.entries) {
      if (entry.value.isEmpty) continue;

      // Faculty section header
      widgets.add(_FacultyHeader(faculty: entry.key));
      widgets.add(const SizedBox(height: 10));

      // 2-column grid
      widgets.add(LayoutBuilder(
        builder: (_, bc) {
          final cols = bc.maxWidth >= 560 ? 2 : 1;
          return _buildGrid(entry.value, cols);
        },
      ));
      widgets.add(const SizedBox(height: 24));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items, int cols) {
    final rows = <Widget>[];
    for (int r = 0; r < items.length; r += cols) {
      final rowItems = <Widget>[];
      for (int c = 0; c < cols; c++) {
        final idx = r + c;
        if (idx < items.length) {
          final prog = _ProgDef.fromRow(items[idx]);
          rowItems.add(
            Expanded(
              child: _ProgCard(
                prog: prog,
                selected: _selectedName == prog.name,
                onTap: () => _select(prog.name, prog.faculty),
              ),
            ),
          );
        } else {
          rowItems.add(const Expanded(child: SizedBox()));
        }
        if (c < cols - 1) rowItems.add(const SizedBox(width: 14));
      }
      rows.add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: rowItems));
      if (r + cols < items.length) rows.add(const SizedBox(height: 14));
    }
    return Column(children: rows);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Faculty section header
// ─────────────────────────────────────────────────────────────────────────────
class _FacultyHeader extends StatelessWidget {
  final String faculty;
  const _FacultyHeader({required this.faculty});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _kParchDeep,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(children: [
        Icon(_iconForFaculty(faculty), size: 13, color: _kCrimson),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            faculty,
            style: GoogleFonts.dmSans(
              fontSize: 11.5, fontWeight: FontWeight.w600,
              color: _kInkMid, letterSpacing: 0.2,
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: _kParchment.withValues(alpha: 0.96),
        border: const Border(bottom: BorderSide(color: _kBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kCrimsonPale,
              border: Border.all(color: _kCrimson.withValues(alpha: 0.2), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              'A',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 13, fontWeight: FontWeight.w600, color: _kCrimson,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'AU Connect',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 19, fontWeight: FontWeight.w600,
              letterSpacing: 0.05 * 19, color: _kInk,
            ),
          ),
          const Spacer(),
          _IconBtn(
            child: const Icon(Icons.info_outline_rounded, size: 14, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final Widget child;
  const _IconBtn({required this.child});

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 30, height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          border: Border.all(
            color: _hover ? _kCrimson : _kBorder, width: 1.5,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D1A1208),
              blurRadius: 12, offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'APPLICATION\nSTATUS',
                  style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w500,
                    letterSpacing: 0.14 * 10, color: _kMuted, height: 1.4,
                  ),
                ),
                Text(
                  '60%',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 18, fontWeight: FontWeight.w600, color: _kCrimson,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: _kBorder, borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                widthFactor: 0.6,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kCrimsonLight, _kCrimson],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSteps(),
          ],
        ),
      ),
    );
  }

  Widget _buildSteps() {
    return Stack(
      children: [
        Positioned(
          left: 10, top: 20, bottom: 20,
          child: Container(
            width: 1.5,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kGreen, _kBorder],
                stops: [0.4, 0.7],
              ),
            ),
          ),
        ),
        Column(
          children: [
            for (int i = 0; i < _kSteps.length; i++)
              _StepRow(step: _kSteps[i], number: i + 1),
          ],
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final _StepDef step;
  final int number;
  const _StepRow({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    final isCurrent = step.status == _StepStatus.current;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? _kCrimsonPale : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _StepDot(step: step, number: number),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              step.name,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: step.status == _StepStatus.done
                    ? _kInkMid
                    : step.status == _StepStatus.current
                        ? _kCrimson
                        : _kMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final _StepDef step;
  final int number;
  const _StepDot({required this.step, required this.number});

  @override
  Widget build(BuildContext context) {
    switch (step.status) {
      case _StepStatus.done:
        return Container(
          width: 22, height: 22,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: _kGreen),
          child: const Icon(Icons.check_rounded, size: 11, color: Colors.white),
        );
      case _StepStatus.current:
        return Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: _kCrimson,
            boxShadow: [BoxShadow(color: _kCrimson.withValues(alpha: 0.3),
              blurRadius: 6, offset: const Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: Text('$number', style: GoogleFonts.cormorantGaramond(
            fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
        );
      case _StepStatus.upcoming:
        return Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle, color: _kParchDeep,
            border: Border.all(color: _kBorder, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text('$number', style: GoogleFonts.cormorantGaramond(
            fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _focused ? _kCrimson : _kBorder, width: 1.5),
        boxShadow: _focused
            ? [BoxShadow(color: _kCrimson.withValues(alpha: 0.08), blurRadius: 0, spreadRadius: 3)]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, size: 15, color: _kMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Focus(
              onFocusChange: (f) => setState(() => _focused = f),
              child: TextField(
                controller: widget.controller,
                style: GoogleFonts.dmSans(fontSize: 13.5, color: _kInk),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Search by program name or faculty…',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 13.5, color: const Color(0xFFC4BAB0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured card (BSc Computer Science Honours)
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCard extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  const _FeaturedCard({required this.selected, required this.onTap});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kCrimsonLight, _kCrimson],
            ),
            borderRadius: BorderRadius.circular(14),
            border: widget.selected
                ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: _kCrimson.withValues(alpha: _hover ? 0.42 : 0.3),
                blurRadius: _hover ? 28 : 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kGold, borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'MOST POPULAR',
                          style: GoogleFonts.dmSans(
                            fontSize: 9.5, fontWeight: FontWeight.w600,
                            letterSpacing: 0.12 * 9.5, color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _kFeaturedName,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _kFeaturedFaculty,
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _FeatTag(icon: Icons.calendar_month_outlined, label: '4 Years'),
                      const SizedBox(width: 16),
                      _FeatTag(icon: Icons.school_outlined, label: 'Undergraduate'),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: 0, bottom: 0,
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2), width: 1.5,
                      ),
                    ),
                    child: Icon(
                      widget.selected ? Icons.check_rounded : Icons.add_rounded,
                      size: 16, color: Colors.white,
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
}

class _FeatTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.65)),
        const SizedBox(width: 5),
        Text(label, style: GoogleFonts.dmSans(
          fontSize: 12, color: Colors.white.withValues(alpha: 0.65))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Program card
// ─────────────────────────────────────────────────────────────────────────────
class _ProgCard extends StatefulWidget {
  final _ProgDef prog;
  final bool selected;
  final VoidCallback onTap;
  const _ProgCard({required this.prog, required this.selected, required this.onTap});

  @override
  State<_ProgCard> createState() => _ProgCardState();
}

class _ProgCardState extends State<_ProgCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: sel ? _kCrimsonPale : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: sel ? _kCrimson : _hover ? _kCrimson : _kBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: sel || _hover
                    ? _kCrimson.withValues(alpha: 0.1)
                    : const Color(0x0A1A1208),
                blurRadius: sel || _hover ? 16 : 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: sel ? _kCrimsonPale : _kParchDeep,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: sel ? _kCrimson.withValues(alpha: 0.2) : _kBorder,
                  ),
                ),
                child: Icon(
                  widget.prog.icon, size: 16,
                  color: sel ? _kCrimson : _kInkMid,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.prog.name,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: _kInk, height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.prog.faculty,
                style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.calendar_month_outlined, size: 12, color: _kMuted),
                    const SizedBox(width: 5),
                    Text(widget.prog.years,
                        style: GoogleFonts.dmSans(fontSize: 11.5, color: _kMuted)),
                  ]),
                  _SelectBtn(selected: sel, onTap: widget.onTap),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectBtn extends StatefulWidget {
  final bool selected;
  final VoidCallback onTap;
  const _SelectBtn({required this.selected, required this.onTap});

  @override
  State<_SelectBtn> createState() => _SelectBtnState();
}

class _SelectBtnState extends State<_SelectBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected || _hover;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit:  (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: active ? _kCrimson : _kParchment,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? _kCrimson : _kBorder, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.selected ? 'Selected ✓' : 'Select',
            style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: active ? Colors.white : _kInkMid,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer nav
// ─────────────────────────────────────────────────────────────────────────────
class _FooterNav extends StatefulWidget {
  final VoidCallback onBack;
  final Future<void> Function() onContinue;
  final bool hasSelection;
  final bool saving;
  final bool? qualifies; // null=unchecked, true=ok, false=blocked
  const _FooterNav({
    required this.onBack,
    required this.onContinue,
    required this.hasSelection,
    required this.saving,
    this.qualifies,
  });

  @override
  State<_FooterNav> createState() => _FooterNavState();
}

class _FooterNavState extends State<_FooterNav> {
  bool _hoverSave = false;
  bool _hoverBack = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canContinue = widget.hasSelection && !widget.saving && widget.qualifies != false;
    return Column(
      children: [
        Container(height: 1, color: _kBorder),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MouseRegion(
              onEnter: (_) => setState(() => _hoverBack = true),
              onExit:  (_) => setState(() => _hoverBack = false),
              child: GestureDetector(
                onTap: widget.onBack,
                child: Row(children: [
                  AnimatedSlide(
                    offset: _hoverBack ? const Offset(-0.15, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.arrow_back_rounded, size: 15, color: _kMuted),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Back to Documents',
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: _hoverBack ? _kInk : _kMuted,
                    ),
                  ),
                ]),
              ),
            ),
            MouseRegion(
              onEnter: (_) => setState(() => _hoverSave = true),
              onExit:  (_) => setState(() => _hoverSave = false),
              child: GestureDetector(
                onTap: canContinue ? widget.onContinue : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  transform: _hoverSave && canContinue
                      ? Matrix4.translationValues(0, -1, 0)
                      : Matrix4.identity(),
                  decoration: BoxDecoration(
                    gradient: canContinue
                        ? const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [_kCrimsonLight, _kCrimson],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFD6CFC6), Color(0xFFC4BBAF)],
                          ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _kCrimson.withValues(alpha: _hoverSave && canContinue ? 0.38 : 0.28),
                        blurRadius: _hoverSave && canContinue ? 20 : 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.saving)
                        const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2,
                          ),
                        )
                      else
                        Text(
                          l10n.saveAndContinue,
                          style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w500,
                            letterSpacing: 0.04 * 14, color: Colors.white,
                          ),
                        ),
                      const SizedBox(width: 9),
                      if (!widget.saving)
                        const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Qualifications card
// ─────────────────────────────────────────────────────────────────────────────
class _QualificationsCard extends StatelessWidget {
  final List<TextEditingController> subjectCtrls;
  final List<String> gradeVals;
  final void Function(int, String) onGradeChanged;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _QualificationsCard({
    required this.subjectCtrls,
    required this.gradeVals,
    required this.onGradeChanged,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
        boxShadow: const [
          BoxShadow(color: Color(0x0A1A1208), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _kCrimsonPale,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: _kCrimson.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.school_outlined, size: 14, color: _kCrimson),
            ),
            const SizedBox(width: 10),
            Text('Your Qualifications',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 17, fontWeight: FontWeight.w600, color: _kInk)),
            const SizedBox(width: 8),
            Text('(O-Level / A-Level)',
              style: GoogleFonts.dmSans(fontSize: 11, color: _kMuted)),
          ]),
          const SizedBox(height: 4),
          Text(
            'Enter your subjects and grades to check programme eligibility.',
            style: GoogleFonts.dmSans(fontSize: 12, color: _kMuted, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(flex: 5,
              child: Text('Subject', style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: _kInkMid, letterSpacing: 0.1))),
            const SizedBox(width: 10),
            SizedBox(width: 80, child: Text('Grade', style: GoogleFonts.dmSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: _kInkMid, letterSpacing: 0.1))),
            const SizedBox(width: 32),
          ]),
          const SizedBox(height: 6),
          for (int i = 0; i < subjectCtrls.length; i++)
            _SubjectRow(
              controller:     subjectCtrls[i],
              grade:          gradeVals[i],
              onGradeChanged: (v) => onGradeChanged(i, v),
              onRemove: subjectCtrls.length > 1 ? () => onRemove(i) : null,
            ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onAdd,
            child: Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: _kCrimsonPale,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kCrimson.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.add_rounded, size: 14, color: _kCrimson),
              ),
              const SizedBox(width: 8),
              Text('Add Another Subject',
                style: GoogleFonts.dmSans(fontSize: 12.5,
                  fontWeight: FontWeight.w500, color: _kCrimson)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Subject row inside qualifications card
// ─────────────────────────────────────────────────────────────────────────────
class _SubjectRow extends StatelessWidget {
  final TextEditingController controller;
  final String grade;
  final ValueChanged<String> onGradeChanged;
  final VoidCallback? onRemove;

  static const _grades = ['A', 'B', 'C', 'D', 'E', 'U'];

  const _SubjectRow({
    required this.controller,
    required this.grade,
    required this.onGradeChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: controller,
              style: GoogleFonts.dmSans(fontSize: 13, color: _kInk),
              decoration: InputDecoration(
                hintText: 'e.g. Mathematics',
                hintStyle: GoogleFonts.dmSans(fontSize: 13, color: _kMuted),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: _kCrimsonLight, width: 1.5)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          height: 38,
          child: DropdownButtonFormField<String>(
            initialValue: _grades.contains(grade) ? grade : 'C',
            isDense: true,
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              isDense: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: _kCrimsonLight, width: 1.5)),
            ),
            items: _grades
                .map((g) => DropdownMenuItem(
                    value: g,
                    child: Text(g,
                        style: GoogleFonts.dmSans(fontSize: 13))))
                .toList(),
            onChanged: (v) { if (v != null) onGradeChanged(v); },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24, height: 24,
          child: onRemove != null
              ? GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.remove_circle_outline_rounded,
                      size: 18, color: _kMuted),
                )
              : const SizedBox(),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Eligibility result banner
// ─────────────────────────────────────────────────────────────────────────────
class _EligibilityBanner extends StatelessWidget {
  final bool checking;
  final bool? qualifies;
  final List<Map<String, String>> failedReqs;
  final List<_ProgDef> suggestions;
  final ValueChanged<_ProgDef> onSelectSuggestion;

  const _EligibilityBanner({
    required this.checking,
    required this.qualifies,
    required this.failedReqs,
    required this.suggestions,
    required this.onSelectSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (checking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kBorder),
        ),
        child: Row(children: [
          const SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kCrimson)),
          const SizedBox(width: 12),
          Text('Checking eligibility…',
            style: GoogleFonts.dmSans(fontSize: 13, color: _kMuted)),
        ]),
      );
    }

    if (qualifies == null) return const SizedBox.shrink();

    if (qualifies == true) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF22C55E), width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFF22C55E), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '✅  ${l10n.youQualify}',
              style: GoogleFonts.dmSans(
                fontSize: 13.5, fontWeight: FontWeight.w500,
                color: const Color(0xFF15803D)),
            ),
          ),
        ]),
      );
    }

    // ── not qualified ──────────────────────────────────────────────────────
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(Icons.cancel_rounded,
                      color: Color(0xFFEF4444), size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '❌  ${l10n.youDontQualify}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13.5, fontWeight: FontWeight.w600,
                      color: const Color(0xFFB91C1C)),
                  ),
                ),
              ]),
              if (failedReqs.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final f in failedReqs)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                          style: TextStyle(
                            color: Color(0xFFB91C1C), fontSize: 14,
                            fontWeight: FontWeight.w700)),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.dmSans(
                                fontSize: 12.5,
                                color: const Color(0xFFB91C1C)),
                              children: [
                                TextSpan(
                                  text: f['subject'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                                TextSpan(
                                  text: ' — you have ${f['got']},'
                                        ' minimum required is ${f['required']}'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            '${l10n.suggestedProgrammes} (same faculty)',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16, fontWeight: FontWeight.w600, color: _kInk),
          ),
          const SizedBox(height: 10),
          for (final p in suggestions)
            _SuggestionCard(prog: p, onSelect: () => onSelectSuggestion(p)),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Suggestion card (alternative programme)
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionCard extends StatefulWidget {
  final _ProgDef prog;
  final VoidCallback onSelect;
  const _SuggestionCard({required this.prog, required this.onSelect});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit:  (_) => setState(() => _hover = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border(
              left: const BorderSide(color: Color(0xFF22C55E), width: 3),
              top: BorderSide(
                  color: _hover ? const Color(0xFF22C55E) : _kBorder),
              right: BorderSide(
                  color: _hover ? const Color(0xFF22C55E) : _kBorder),
              bottom: BorderSide(
                  color: _hover ? const Color(0xFF22C55E) : _kBorder),
            ),
            boxShadow: [
              BoxShadow(
                color: _hover
                    ? const Color(0x1222C55E)
                    : const Color(0x081A1208),
                blurRadius: _hover ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.prog.name,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: _kInk, height: 1.2)),
                  const SizedBox(height: 3),
                  Text(widget.prog.faculty,
                    style: GoogleFonts.dmSans(
                      fontSize: 11, color: _kMuted)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: widget.onSelect,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: _hover
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: const Color(0xFF22C55E), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  l10n.selectThisInstead,
                  style: GoogleFonts.dmSans(
                    fontSize: 12, fontWeight: FontWeight.w500,
                    color: _hover
                        ? Colors.white
                        : const Color(0xFF15803D)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
