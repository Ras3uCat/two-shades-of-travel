import 'package:raspucat/utils/constants/exports.dart';

class TrianglePainter extends CustomPainter {
  TrianglePainter(
    this.color, {
    this.strokeWidth = 1.0,
    this.isHovered = false,
    this.gradientDirection = 0,
  });

  final Color color;
  final double strokeWidth;
  final bool isHovered;
  final int gradientDirection;

  Path _trianglePath(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (isHovered) {
      /// --- GLOW EFFECT --- ///
      ///
      ///
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawPath(_trianglePath(size), glowPaint);
    }

    /// --- GRADIENT DIRECTION --- ///
    ///
    ///
    Alignment begin, end;
    switch (gradientDirection) {
      case 0: // Top to bottom
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
        break;
      case 1: // Right to left
        begin = Alignment.centerRight;
        end = Alignment.centerLeft;
        break;
      case 2: // Bottom to top
        begin = Alignment.bottomCenter;
        end = Alignment.topCenter;
        break;
      case 3: // Left to right
        begin = Alignment.centerLeft;
        end = Alignment.centerRight;
        break;
      default:
        begin = Alignment.topCenter;
        end = Alignment.bottomCenter;
    }

    /// --- GRADIENT --- ///
    ///
    ///
    final gradient = LinearGradient(
      begin: begin,
      end: end,
      colors: [color.withOpacity(0.1), color.withOpacity(0.5), color],
      stops: const [0.0, 0.4, 1.0],
    );

    /// --- PAINT --- ///
    ///
    ///
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    /// --- PATH  --- ///
    ///
    ///

    canvas.drawPath(_trianglePath(size), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
