import 'dart:math';

import 'package:flutter/material.dart';

class LavaLampPage extends StatefulWidget {
  const LavaLampPage({super.key, this.showFab = true});

  final bool showFab;

  @override
  State<LavaLampPage> createState() => _LavaLampPageState();
}

class _LavaLampPageState extends State<LavaLampPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: LavaLampPainter(_controller.value),
            child: Container(),
          );
        },
      ),
    );
  }
}

class LavaLampPainter extends CustomPainter {
  final double t;
  LavaLampPainter(this.t);

  final List<Color> colors = [
    Colors.pinkAccent,
    Colors.deepPurpleAccent,
    Colors.orangeAccent,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.yellowAccent,
    Colors.cyanAccent,
    Colors.amberAccent,
    Colors.limeAccent,
    Colors.tealAccent,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = BlendMode.plus
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);

    final centerX = size.width / 2;
    final height = size.height;
    final blobs = 10;

    for (int i = 0; i < blobs; i++) {
      final color = colors[i % colors.length].withValues(alpha: 0.99);
      final phase = (t + i / blobs) % 1.0;
      final y = height * (0.2 + 0.6 * sin(2 * pi * phase));
      final x = centerX + sin(2 * pi * phase * 1.5 + i) * 80;
      final radius = 60 + 20 * sin(2 * pi * phase + i);
      paint.color = color;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LavaLampPainter oldDelegate) => true;
}
