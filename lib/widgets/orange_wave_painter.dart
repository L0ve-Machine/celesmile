import 'package:flutter/material.dart';
import '../constants/colors.dart';

class TopOrangeWave extends StatelessWidget {
  const TopOrangeWave({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width * 0.4,
                 MediaQuery.of(context).size.height * 0.22),
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

    // Draw the wave curve
    path.lineTo(size.width, size.height * 0.7);

    // Curved bottom edge
    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.9,
      size.width * 0.5, size.height * 0.85,
    );

    path.quadraticBezierTo(
      size.width * 0.2, size.height * 0.8,
      0, size.height,
    );

    // Back to top
    path.lineTo(0, 0);
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
      size: Size(MediaQuery.of(context).size.width * 0.35,
                 MediaQuery.of(context).size.height * 0.18),
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

    // Draw the wave curve
    path.lineTo(0, size.height * 0.3);

    // Curved top edge
    path.quadraticBezierTo(
      size.width * 0.2, size.height * 0.1,
      size.width * 0.5, size.height * 0.15,
    );

    path.quadraticBezierTo(
      size.width * 0.8, size.height * 0.2,
      size.width, 0,
    );

    // Back to bottom
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}