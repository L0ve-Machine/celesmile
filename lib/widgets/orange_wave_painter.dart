import 'package:flutter/material.dart';
import '../constants/colors.dart';

class TopOrangeWave extends StatelessWidget {
  const TopOrangeWave({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width * 0.7,
                 MediaQuery.of(context).size.height * 0.35),
      painter: TopOrangeWavePainter(),
    );
  }
}

class TopOrangeWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from top-right corner
    path.moveTo(size.width, 0);

    // Right edge down to about 70% height
    path.lineTo(size.width, size.height * 0.7);

    // Create a large curved shape that comes down and left
    path.cubicTo(
      size.width * 0.9, size.height * 0.95,   // First control point
      size.width * 0.7, size.height * 1.0,    // Second control point
      size.width * 0.45, size.height * 0.95,  // End point
    );

    // Continue curving up to the left
    path.cubicTo(
      size.width * 0.25, size.height * 0.9,   // First control point
      size.width * 0.1, size.height * 0.7,    // Second control point
      size.width * 0.05, size.height * 0.4,   // End point
    );

    // Curve back to top
    path.cubicTo(
      size.width * 0.0, size.height * 0.2,    // First control point
      size.width * 0.1, size.height * 0.05,   // Second control point
      size.width * 0.3, 0,                    // End point at top
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BottomOrangeWave extends StatelessWidget {
  const BottomOrangeWave({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width * 0.6,
                 MediaQuery.of(context).size.height * 0.3),
      painter: BottomOrangeWavePainter(),
    );
  }
}

class BottomOrangeWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryOrange
      ..style = PaintingStyle.fill;

    final path = Path();

    // Start from bottom-left corner
    path.moveTo(0, size.height);

    // Left edge up to about 30% from bottom
    path.lineTo(0, size.height * 0.3);

    // Create a large curved shape that goes up and right
    path.cubicTo(
      size.width * 0.1, size.height * 0.05,   // First control point
      size.width * 0.3, size.height * 0.0,    // Second control point
      size.width * 0.55, size.height * 0.05,  // End point
    );

    // Continue curving down to the right
    path.cubicTo(
      size.width * 0.75, size.height * 0.1,   // First control point
      size.width * 0.9, size.height * 0.3,    // Second control point
      size.width * 0.95, size.height * 0.6,   // End point
    );

    // Curve back to bottom
    path.cubicTo(
      size.width * 1.0, size.height * 0.8,    // First control point
      size.width * 0.9, size.height * 0.95,   // Second control point
      size.width * 0.7, size.height,          // End point at bottom
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}