import 'package:flutter/material.dart';
import 'package:au_connect/widgets/crimson_header.dart';
import 'package:au_connect/widgets/primary_button.dart';
import 'package:au_connect/widgets/progress_bar.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';
import 'onboarding_shell.dart';

class AcademicScreen extends StatefulWidget {
  const AcademicScreen({super.key});

  @override
  State<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends State<AcademicScreen> {
  late final TextEditingController _school;
  late final TextEditingController _grades;

  @override
  void initState() {
    super.initState();
    _school = TextEditingController();
    _grades = TextEditingController();
  }

  @override
  void dispose() {
    _school.dispose();
    _grades.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return OnboardingShell(
      footer: PrimaryButton(
        label: 'Continue →',
        onTap: () {
          c.state.school = _school.text.trim();
          c.state.grades = _grades.text.trim();
          c.goTo(17);
        },
      ),
      child: Column(
        children: [
          CrimsonHeader(icon: '📚', tag: 'Application • Step 5', title: 'Your Academic History', subtitle: 'Share your educational background', onBack: c.back),
          const ProgressBar(step: 5, total: 8, percent: 62),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('SCHOOL / INSTITUTION ATTENDED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMid)),
                const SizedBox(height: 6),
                TextField(controller: _school, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: kBackground)),
                const SizedBox(height: 12),
                const Text('QUALIFICATIONS & GRADES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextMid)),
                const SizedBox(height: 6),
                TextField(controller: _grades, maxLines: 4, decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), filled: true, fillColor: kBackground)),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async => c.pickCertificate(),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(border: Border.all(color: kBorder, width: 2), borderRadius: BorderRadius.circular(14)),
                    child: Column(
                      children: [
                        const Text('📎', style: TextStyle(fontSize: 28)),
                        const SizedBox(height: 8),
                        const Text('Tap to upload certificate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextMid)),
                        const SizedBox(height: 4),
                        const Text('PDF or image accepted', style: TextStyle(fontSize: 11, color: kTextLight)),
                        if (c.state.certificateFileName != null) ...[
                          const SizedBox(height: 6),
                          Text('📎 ${c.state.certificateFileName!}', style: const TextStyle(fontSize: 12, color: kCrimson)),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
