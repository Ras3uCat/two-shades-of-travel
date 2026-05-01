import 'package:raspucat/utils/constants/exports.dart';

class TriangleNavigationPainter extends CustomPainter {
  final Color color;
  final bool isActive;
  final bool isHovered;

  TriangleNavigationPainter({
    required this.color,
    required this.isActive,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = isHovered || isActive
          ? PaintingStyle.fill
          : PaintingStyle.stroke;

    final strokePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isActive ? 2.0 : 1.0;

    // Calculate triangle points
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final triangleSize = isActive ? 12.0 : 8.0;

    // Create upward-pointing triangle
    final path = Path();
    path.moveTo(centerX, centerY - triangleSize); // Top point
    path.lineTo(
      centerX - triangleSize,
      centerY + triangleSize * 0.6,
    ); // Bottom left
    path.lineTo(
      centerX + triangleSize,
      centerY + triangleSize * 0.6,
    ); // Bottom right
    path.close();

    // Add glow effect for active triangle first (behind)
    if (isActive) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawPath(path, glowPaint);
    }

    // Fill the triangle
    canvas.drawPath(path, paint);

    // Add stroke for active triangle
    if (isActive) {
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(TriangleNavigationPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isHovered != isHovered ||
        oldDelegate.isActive != isActive;
  }
}
