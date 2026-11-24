import '../../app/localization/app_language.dart';
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

const learnerAccents = [
  Color(0xff2563eb),
  Color(0xff0d9488),
  Color(0xffe76a45),
  Color(0xff8055d9)
];

/// Short entrance motion, with no recurring ticker or network assets.
class WelcomeBanner extends StatelessWidget {
  final VoidCallback onContinue;
  const WelcomeBanner({super.key, required this.onContinue});
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)), child: child)),
      child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(mobile ? 18 : 28),
          decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xffeaf3ff)
                  : const Color(0xff183454),
              borderRadius: BorderRadius.circular(mobile ? 24 : 26),
              border: Border.all(
                  color: Theme.of(context).brightness == Brightness.light
                      ? const Color(0xffc9dfff)
                      : Colors.white12),
              boxShadow: Theme.of(context).brightness == Brightness.light
                  ? const [
                      BoxShadow(
                          color: Color(0x172563eb),
                          blurRadius: 22,
                          offset: Offset(0, 8))
                    ]
                  : const []),
          child: LayoutBuilder(builder: (context, size) {
            final copy =
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const LText('LEARN • CREATE • GROW',
                  style: TextStyle(
                      color: Color(0xff2563eb),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 16),
              LText('Big ideas.\nBrighter possibilities.',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w800, height: 1.15)),
              const SizedBox(height: 14),
              const LText(
                  'A new skill, a creative spark, a step forward.\nMake today your next good chapter.',
                  style: TextStyle(height: 1.6)),
              const SizedBox(height: 22),
              FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const LText('Continue learning')),
            ]);
            if (size.maxWidth < 600) {
              final artWidth = size.maxWidth < 300 ? 78.0 : 104.0;
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const LText('LEARN • CREATE • GROW',
                              style: TextStyle(
                                  color: Color(0xff2563eb),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.3)),
                          const SizedBox(height: 10),
                          LText('Big ideas.\nBrighter possibilities.',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      fontSize: size.maxWidth < 300 ? 25 : 28,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -.7,
                                      height: 1.05)),
                          const SizedBox(height: 9),
                          const LText('Make today your next good chapter.',
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, height: 1.4)),
                          const SizedBox(height: 13),
                          FilledButton.icon(
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 46),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11),
                                  visualDensity: VisualDensity.compact,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14))),
                              onPressed: onContinue,
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                              label: const LText('Continue learning',
                                  maxLines: 1, overflow: TextOverflow.ellipsis))
                        ])),
                    const SizedBox(width: 4),
                    SizedBox(
                        width: artWidth,
                        height: 126,
                        child: Center(
                            child: SizedBox(
                                width: 150,
                                height: 104,
                                child: const LearningIllustration())))
                  ]);
            }
            return Row(children: [
              Expanded(flex: 3, child: copy),
              const Expanded(
                  flex: 2,
                  child: SizedBox(height: 250, child: LearningIllustration()))
            ]);
          })),
    );
  }
}

/// Original layered vector artwork; rendered locally and inexpensive to paint.
class LearningIllustration extends StatefulWidget {
  const LearningIllustration({super.key});
  @override
  State<LearningIllustration> createState() => _LearningIllustrationState();
}

class _LearningIllustrationState extends State<LearningIllustration> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => Semantics(
      label: tr(context,
          'An illustrated stack of colourful books with a creative spark'),
      image: true,
      child: MouseRegion(
          onEnter: (_) => setState(() => hover = true),
          onExit: (_) => setState(() => hover = false),
          child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              transform: Matrix4.identity()
                ..translateByDouble(0.0, hover ? -6.0 : 0.0, 0.0, 1.0)
                ..rotateZ(hover ? -.025 : 0),
              transformAlignment: Alignment.center,
              child: AspectRatio(
                  aspectRatio: 1.45,
                  child: CustomPaint(painter: _BooksPainter())))));
}

class _BooksPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 320, size.height / 220);
    final p = Paint();
    canvas.drawOval(const Rect.fromLTWH(50, 190, 230, 16),
        p..color = const Color(0xffceddf4));
    canvas.drawCircle(
        const Offset(166, 109), 92, p..color = const Color(0xffdceaff));
    void book(double x, double y, double width, Color colour) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 5, y + 7, width, 35), const Radius.circular(9)),
          p..color = colour.withValues(alpha: .22));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, width, 35), const Radius.circular(9)),
          p..color = colour);
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x + 20, y + 5, width - 23, 24),
              const Radius.circular(5)),
          p..color = const Color(0xfffffdf6));
      canvas.drawLine(
          Offset(x + 28, y + 13),
          Offset(x + width - 12, y + 13),
          p
            ..color = const Color(0xffd9dce5)
            ..strokeWidth = 2);
      canvas.drawLine(
          Offset(x + 28, y + 20), Offset(x + width - 12, y + 20), p);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x + 45, y + 5, 14, 40), const Radius.circular(2)),
          p..color = const Color(0xffffbe55));
    }

    book(70, 154, 198, const Color(0xff0d9488));
    book(50, 115, 188, const Color(0xff8055d9));
    book(77, 76, 180, const Color(0xff4b8af2));
    canvas.drawCircle(
        const Offset(253, 42), 27, p..color = const Color(0xffffd884));
    canvas.drawCircle(
        const Offset(253, 42), 16, p..color = const Color(0xfffff6d8));
    final star = Path()
      ..moveTo(48, 35)
      ..lineTo(53, 48)
      ..lineTo(66, 53)
      ..lineTo(53, 58)
      ..lineTo(48, 71)
      ..lineTo(43, 58)
      ..lineTo(30, 53)
      ..lineTo(43, 48)
      ..close();
    canvas.drawPath(star, p..color = const Color(0xfff08c71));
    canvas.drawCircle(
        const Offset(286, 118), 6, p..color = const Color(0xff9ccabf));
    canvas.drawCircle(
        const Offset(107, 40), 4, p..color = const Color(0xff8055d9));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
