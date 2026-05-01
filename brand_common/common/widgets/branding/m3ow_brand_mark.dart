import 'package:raspucat/utils/constants/exports.dart';

class M3OWBrandMark extends StatelessWidget {
  final double size;
  final Color? color;

  const M3OWBrandMark({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 3,
      height: size,
      child: CustomPaint(
        painter: _M3OWPainter(color: color ?? EColors.primary),
      ),
    );
  }
}

class _M3OWPainter extends CustomPainter {
  final Color color;

  _M3OWPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.square;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    final unit = size.height;

    // Simplified Geometric "M"
    path.moveTo(0, unit);
    path.lineTo(0, 0);
    path.lineTo(unit * 0.5, unit * 0.5);
    path.lineTo(unit, 0);
    path.lineTo(unit, unit);

    // Stylized "3"
    double start3 = unit * 1.2;
    path.moveTo(start3, 0);
    path.lineTo(start3 + unit * 0.8, 0);
    path.lineTo(start3 + unit * 0.4, unit * 0.5);
    path.lineTo(start3 + unit * 0.8, unit * 0.5);
    path.lineTo(start3 + unit * 0.4, unit);
    path.lineTo(start3, unit);

    // Simplified Geometric "W" (inverted M basically)
    double startW = unit * 2.2;
    path.moveTo(startW, 0);
    path.lineTo(startW, unit);
    path.lineTo(startW + unit * 0.4, unit * 0.5);
    path.lineTo(startW + unit * 0.8, unit);
    path.lineTo(startW + unit * 0.8, 0);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
