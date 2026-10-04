import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';

/// Úvodní obrazovka s logem. Po krátké chvíli se plynule skryje
/// a odhalí aplikaci pod sebou.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  static const _hold = Duration(milliseconds: 1800);

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();
  bool _done = false;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(_hold, () {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (!_gone)
        IgnorePointer(
          ignoring: _done,
          child: AnimatedOpacity(
            opacity: _done ? 0 : 1,
            onEnd: () {
              if (_done && mounted) setState(() => _gone = true);
            },
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            child: ColoredBox(
              color: scheme.primary,
              child: Center(
                child: FadeTransition(
                  opacity: _intro,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(
                      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const RebusarnaLogo(size: 120),
                        const SizedBox(height: 24),
                        Text(
                          kAppName,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: scheme.onPrimary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Testovací logo – později stačí nahradit obsahem tohoto widgetu
/// (např. `Image.asset('assets/images/logo.png', width: size)`).
class RebusarnaLogo extends StatelessWidget {
  const RebusarnaLogo({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.onPrimary,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.extension_rounded, size: size * 0.66, color: scheme.primary),
          Positioned(
            right: size * 0.16,
            top: size * 0.08,
            child: Text(
              '?',
              style: TextStyle(
                fontSize: size * 0.34,
                fontWeight: FontWeight.w900,
                color: difficultyColor(3),
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
