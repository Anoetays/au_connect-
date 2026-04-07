import 'package:flutter/material.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';

class TrackerScreen extends StatelessWidget {
  const TrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnboardingScope.of(context);
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: kCrimson,
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('YOUR APPLICATION', style: TextStyle(fontSize: 11, color: Color(0x99FFFFFF), letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(c.state.programme, style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text('Africa University · Mutare, Zimbabwe', style: TextStyle(fontSize: 13, color: Color(0xB3FFFFFF))),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  _StepTile(done: true, marker: '✓', title: 'Application Submitted', subtitle: 'Received and under review'),
                  _StepTile(active: true, marker: '⏳', title: 'Under Review', subtitle: 'Admissions team is reviewing your documents'),
                  _StepTile(marker: '3', title: 'Decision', subtitle: 'Offer or feedback will be communicated'),
                  _StepTile(marker: '4', title: 'Enrolment', subtitle: 'Accept offer and complete registration'),
                  _StepTile(marker: '5', title: 'Welcome to AU! 🎓', subtitle: 'Begin your journey at Africa University', isLast: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final bool done;
  final bool active;
  final bool isLast;
  final String marker;
  final String title;
  final String subtitle;

  const _StepTile({
    required this.marker,
    required this.title,
    required this.subtitle,
    this.done = false,
    this.active = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = (done || active) ? kCrimson : kBorder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? const [BoxShadow(color: Color(0x33B22234), blurRadius: 0, spreadRadius: 4)]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(marker, style: TextStyle(color: done || active ? Colors.white : kTextLight, fontWeight: FontWeight.w700)),
              ),
              if (!isLast)
                Container(width: 2, height: 46, color: done ? kCrimson : kBorder),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: done || active ? kTextDark : kTextLight)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
