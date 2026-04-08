import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  VideoPlayerController? _controller;
  bool _navigated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.asset('assets/videos/intro.mp4');
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() => _controller = ctrl);
      ctrl.addListener(_onVideoProgress);
      await ctrl.play();
    } catch (e) {
      debugPrint('Intro video failed to load: $e');
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _onVideoProgress() {
    final ctrl = _controller;
    if (ctrl == null || _navigated) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur.inMilliseconds > 0 && pos.inMilliseconds >= dur.inMilliseconds) {
      _goNext();
    }
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed('/applicant_sign_up');
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Video unavailable',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  )
                : ctrl != null && ctrl.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: ctrl.value.aspectRatio,
                        child: VideoPlayer(ctrl),
                      )
                    : const CircularProgressIndicator(color: Colors.white),
          ),
          // Skip button — always visible so users are never stuck
          Positioned(
            bottom: 40,
            right: 24,
            child: TextButton(
              onPressed: _goNext,
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
