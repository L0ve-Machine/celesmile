import 'package:flutter/material.dart';
import '../constants/colors.dart';

class TopOrangeWave extends StatelessWidget {
  const TopOrangeWave({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width * 0.55,
                 MediaQuery.of(context).size.height * 0.28),
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

    // Right edge
    path.lineTo(size.width, size.height * 0.5);

    // Bottom curved edge - smoother wave
    path.cubicTo(
      size.width * 0.7, size.height * 0.9,  // Control point 1
      size.width * 0.3, size.height * 1.0,  // Control point 2
      size.width * 0.1, size.height * 0.7,  // End point
    );

    // Continue curve to left edge
    path.quadraticBezierTo(
      size.width * 0.05, size.height * 0.6,
      size.width * 0.15, size.height * 0.3,
    );

    // Back to top
    path.lineTo(size.width * 0.3, 0);
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
      size: Size(MediaQuery.of(context).size.width * 0.45,
                 MediaQuery.of(context).size.height * 0.25),
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

    // Left edge
    path.lineTo(0, size.height * 0.5);

    // Top curved edge - smoother wave
    path.cubicTo(
      size.width * 0.3, size.height * 0.1,  // Control point 1
      size.width * 0.7, size.height * 0.0,  // Control point 2
      size.width * 0.9, size.height * 0.3,  // End point
    );

    // Continue to right edge
    path.quadraticBezierTo(
      size.width * 0.95, size.height * 0.4,
      size.width * 0.85, size.height * 0.7,
    );

    // Back to bottom
    path.lineTo(size.width * 0.7, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}