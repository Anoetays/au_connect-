import 'package:flutter/material.dart';

/// Custom fade and slide page transition
class FadeSlidePageRoute<T> extends PageRoute<T> {
  FadeSlidePageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 400),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String get barrierLabel => '';

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}

/// Custom scale and fade page transition
class ScaleFadePageRoute<T> extends PageRoute<T> {
  ScaleFadePageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 400),
  });

  final WidgetBuilder builder;
  final Duration duration;

  @override
  Color? get barrierColor => null;

  @override
  String get barrierLabel => '';

  @override
  bool get maintainState => true;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}

/// Helper to navigate with animation
void navigateWithAnimation(
  BuildContext context,
  Widget Function(BuildContext) builder, {
  bool useScaleFade = false,
  Duration duration = const Duration(milliseconds: 400),
}) {
  final route = useScaleFade
      ? ScaleFadePageRoute<void>(builder: builder, duration: duration)
      : FadeSlidePageRoute<void>(builder: builder, duration: duration);

  Navigator.of(context).push(route);
}

/// Helper to navigate and return a result with animation
Future<T?> navigateWithAnimationForResult<T>(
  BuildContext context,
  Widget Function(BuildContext) builder, {
  bool useScaleFade = false,
  Duration duration = const Duration(milliseconds: 400),
}) {
  final route = useScaleFade
      ? ScaleFadePageRoute<T>(builder: builder, duration: duration)
      : FadeSlidePageRoute<T>(builder: builder, duration: duration);

  return Navigator.of(context).push(route);
}
