import 'package:flutter/material.dart';
import 'onboarding_constants.dart';
import 'onboarding_scope.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingScope.of(context).autoAdvanceSplash();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCrimson,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(Icons.school_rounded, size: 100, color: Color(0xFFB91C1C)),
            ),
            const SizedBox(height: 24),
            const Text('AU Connect', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Africa University • Admissions Portal', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 14)),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                _Dot(delay: 0),
                SizedBox(width: 8),
                _Dot(delay: 180),
                SizedBox(width: 8),
                _Dot(delay: 360),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    Future<void>.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1).animate(_controller),
      child: const CircleAvatar(radius: 4, backgroundColor: Color(0x99FFFFFF)),
    );
  }
}
