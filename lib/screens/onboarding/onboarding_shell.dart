import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'onboarding_constants.dart';

class OnboardingShell extends StatelessWidget {
  final Widget child;
  final Widget? footer;
  const OnboardingShell({super.key, required this.child, this.footer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: kIsWeb
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: child,
                      ),
                    )
                  : child,
            ),
            if (footer != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: kBorder)),
                ),
                child: kIsWeb
                    ? Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: footer!,
                        ),
                      )
                    : footer!,
              ),
          ],
        ),
      ),
    );
  }
}
