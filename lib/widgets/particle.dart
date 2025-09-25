import 'dart:math';
import 'package:android/utils/colors.dart';
import 'package:flutter/material.dart';

class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int particleCount = 70;
  final List<Particle> particles = [];
  final Random random = Random();
  Size screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();
  }

  void _initializeParticles() {
    particles.clear();
    for (int i = 0; i < particleCount; i++) {
      particles.add(Particle(
        position: Offset(random.nextDouble() * screenSize.width, random.nextDouble() * screenSize.height),
        speed: 0.2 + random.nextDouble() * 0.6,
        size: 2 + random.nextDouble() * 10,
        shape: ParticleShape.circle,
        color: AppColors.green500.withAlpha(20 + random.nextInt(100)),
      ));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSize = MediaQuery.of(context).size;
    if (screenSize != newSize) {
      screenSize = newSize;
      _initializeParticles();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        for (var p in particles) {
          double dy = p.position.dy + p.speed;
          if (dy > screenSize.height) {
            dy = 0;
            p.position = Offset(random.nextDouble() * screenSize.width, dy);
          } else {
            p.position = Offset(p.position.dx, dy);
          }
        }

        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(particles),
        );
      },
    );
  }
}

enum ParticleShape { circle }

class Particle {
  Offset position;
  double speed;
  double size;
  ParticleShape shape;
  Color color;

  Particle({
    required this.position,
    required this.speed,
    required this.size,
    required this.shape,
    required this.color,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()..color = p.color;
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
