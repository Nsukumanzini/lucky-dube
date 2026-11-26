import 'dart:async';
import 'dart:math' as math;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/app_language.dart';
import '../../shared/components/premium_surface.dart';

/// Branded app launch screen. The school name is used as a temporary
/// wordmark; the screen intentionally does not imitate an unapproved crest.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  Timer? opening;
  bool? reducedMotion;

  @override
  void initState() {
    super.initState();
    opening = Timer(const Duration(milliseconds: 2800), _openHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce == reducedMotion) return;
    reducedMotion = reduce;
    if (reduce) {
      motion
        ..stop()
        ..value = .28;
    } else {
      motion.repeat();
    }
  }

  void _openHome() {
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    opening?.cancel();
    motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 600;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 20 : 32,
              vertical: 22,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: LiquidGlassSurface(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 22 : 42,
                  vertical: compact ? 24 : 34,
                ),
                borderRadius: BorderRadius.circular(34),
                tint: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xeefcfdff)
                    : const Color(0xec18253a),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: motion,
                      builder: (context, _) {
                        final artWidth = math
                            .max(
                              150.0,
                              math.min(size.width - (compact ? 92 : 180), 490),
                            )
                            .toDouble();
                        return CustomPaint(
                          size: Size(artWidth, artWidth * .54),
                          painter: _WelcomeLearnersPainter(motion.value),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(context, 'Lucky Dube'),
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: compact ? 34 : 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'LEARN • CREATE • GROW'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Theme.of(context).colorScheme.secondary,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: .13),
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton.icon(
                      onPressed: _openHome,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: Text(tr(context, 'Continue')),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tr(context, 'Powered by OG Technologies SA'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            letterSpacing: .2,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeLearnersPainter extends CustomPainter {
  final double phase;
  const _WelcomeLearnersPainter(this.phase);

  static const _palette = [
    Color(0xff4c5fe8),
    Color(0xff0ca995),
    Color(0xfff08756),
    Color(0xff9a5de0),
    Color(0xffe4a11b),
    Color(0xffed6682),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 500, size.height / 270);
    final p = Paint()..isAntiAlias = true;
    canvas.drawOval(const Rect.fromLTWH(65, 221, 370, 22),
        p..color = const Color(0x143c5495));
    canvas.drawCircle(
        const Offset(250, 132), 112, p..color = const Color(0x187e9eff));
    canvas.drawCircle(
        const Offset(250, 132), 87, p..color = const Color(0x20ffffff));

    // Floating art marks orbit around the learners and drift gently as the
    // launch animation plays.
    final marks = <(Offset, IconData, Color)>[
      (const Offset(92, 75), Icons.auto_awesome_rounded, _palette[4]),
      (const Offset(400, 67), Icons.music_note_rounded, _palette[3]),
      (const Offset(436, 151), Icons.palette_rounded, _palette[5]),
      (const Offset(66, 159), Icons.lightbulb_rounded, _palette[0]),
    ];
    for (var i = 0; i < marks.length; i++) {
      final (base, icon, color) = marks[i];
      final offset = Offset(
        math.sin(phase * math.pi * 2 + i) * 4,
        math.cos(phase * math.pi * 2 + i * .8) * 5,
      );
      final center = base + offset;
      canvas.drawCircle(center, 21, p..color = color.withValues(alpha: .16));
      final iconPainter = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
            fontFamily: icon.fontFamily,
            package: icon.fontPackage,
            fontSize: 21,
            color: color,
          ),
        )
        ..layout();
      iconPainter.paint(
        canvas,
        center - Offset(iconPainter.width / 2, iconPainter.height / 2),
      );
    }

    void learner({
      required double x,
      required double y,
      required Color shirt,
      required Color skin,
      required Color hair,
      required double bob,
      required bool wave,
    }) {
      canvas.save();
      canvas.translate(x, y + bob);
      // body and sleeves
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-28, 56, 56, 83), const Radius.circular(23)),
        p..color = shirt,
      );
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-22, 112, 44, 63), const Radius.circular(14)),
          p..color = const Color(0xff405170));
      // head, ears and hair
      canvas.drawCircle(const Offset(0, 37), 25, p..color = skin);
      canvas.drawCircle(const Offset(-24, 40), 5, p..color = skin);
      canvas.drawCircle(const Offset(24, 40), 5, p..color = skin);
      canvas.drawOval(const Rect.fromLTWH(-25, 10, 50, 23), p..color = hair);
      canvas.drawCircle(const Offset(-17, 26), 9, p..color = hair);
      canvas.drawCircle(const Offset(0, 22), 11, p);
      canvas.drawCircle(const Offset(17, 26), 9, p);
      // eyes and cheerful smile
      canvas.drawCircle(
          const Offset(-8, 39), 1.8, p..color = const Color(0xff293045));
      canvas.drawCircle(const Offset(8, 39), 1.8, p);
      final smile = Path()
        ..moveTo(-7, 49)
        ..quadraticBezierTo(0, 56, 8, 49);
      canvas.drawPath(
          smile,
          p
            ..color = const Color(0xff7e3946)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      p.style = PaintingStyle.fill;
      // arms reaching in to share the book; one learner waves hello.
      final arm = Paint()
        ..color = skin
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 12;
      canvas.drawLine(const Offset(-23, 71), const Offset(-48, 104), arm);
      canvas.drawLine(const Offset(23, 71),
          wave ? const Offset(46, 40) : const Offset(46, 101), arm);
      if (wave) {
        canvas.drawLine(const Offset(46, 40), const Offset(53, 25), arm);
      }
      canvas.restore();
    }

    // A soft rhythm of vertical bobbing makes the trio feel welcoming without
    // adding photographic dependencies or distracting motion.
    learner(
      x: 139,
      y: 42,
      shirt: _palette[2],
      skin: const Color(0xff9b5c3d),
      hair: const Color(0xff282436),
      bob: math.sin(phase * math.pi * 2) * 3,
      wave: true,
    );
    learner(
      x: 250,
      y: 22,
      shirt: _palette[1],
      skin: const Color(0xff78442f),
      hair: const Color(0xff201b29),
      bob: math.sin(phase * math.pi * 2 + 1.8) * 2,
      wave: false,
    );
    learner(
      x: 361,
      y: 42,
      shirt: _palette[3],
      skin: const Color(0xffb67a55),
      hair: const Color(0xff352326),
      bob: math.sin(phase * math.pi * 2 + 3.2) * 3,
      wave: false,
    );

    // Open book in the foreground.
    final leftPage = Path()
      ..moveTo(137, 174)
      ..quadraticBezierTo(191, 154, 249, 179)
      ..lineTo(249, 226)
      ..quadraticBezierTo(190, 202, 137, 222)
      ..close();
    final rightPage = Path()
      ..moveTo(251, 179)
      ..quadraticBezierTo(309, 154, 363, 174)
      ..lineTo(363, 222)
      ..quadraticBezierTo(310, 202, 251, 226)
      ..close();
    canvas.drawShadow(leftPage, const Color(0x30344b87), 7, true);
    canvas.drawPath(leftPage, p..color = const Color(0xfffffff7));
    canvas.drawPath(rightPage, p..color = const Color(0xfffffff1));
    canvas.drawPath(
        Path()
          ..moveTo(250, 179)
          ..lineTo(250, 226),
        p
          ..color = const Color(0xffd7dced)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;
    for (var i = 0; i < 3; i++) {
      final y = 190 + i * 10.0;
      canvas.drawLine(Offset(159, y), Offset(225, y - 3),
          p..color = _palette[i].withValues(alpha: .6));
      canvas.drawLine(Offset(276, y - 3), Offset(340, y),
          p..color = _palette[i + 2].withValues(alpha: .6));
    }
    p.style = PaintingStyle.fill;
    // Tiny coloured paper tabs accent the open book.
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(222 + i * 15.0, 168 - (i % 2) * 5, 11, 24),
              const Radius.circular(4)),
          p..color = _palette[i]);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WelcomeLearnersPainter oldDelegate) =>
      oldDelegate.phase != phase;
}
