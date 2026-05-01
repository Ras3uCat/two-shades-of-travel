import 'package:raspucat/utils/constants/exports.dart';

class TriangleModel {
  Offset position;
  double size;
  double rotation;
  Color color;
  Color originalColor;
  bool isHovered;
  bool isPopping;
  int gradientDirection; // 0: top, 1: right, 2: bottom, 3: left

  TriangleModel({
    required this.position,
    required this.size,
    required this.rotation,
    required this.color,
    required this.originalColor,
    this.isHovered = false,
    this.isPopping = false,
    this.gradientDirection = 0,
  });
}
