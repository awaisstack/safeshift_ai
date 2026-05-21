import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:ui';
import 'request_input_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Premium Mughal Indigo / Dark Slate Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // Deep Slate
                  Color(0xFF0A0F1D), // Dark Mughal Indigo
                ],
              ),
            ),
          ),
          // Glow effects
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFB5A1).withAlpha(45), // Soft Terracotta glow
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2E7D32).withAlpha(35), // Emerald glow
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(color: Colors.transparent),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header branding
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB5A1).withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFB5A1).withAlpha(50)),
                          ),
                          child: const Icon(Icons.shield_outlined, color: Color(0xFFFFB5A1), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "SafeShift AI",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
  
                    // Native graphic illustration (Shifting art: route line, truck, cartons)
                    Center(
                      child: FadeInDown(
                        duration: const Duration(milliseconds: 1000),
                        child: Container(
                          height: 240,
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(10),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(color: Colors.white.withAlpha(20)),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Custom route line representation
                              CustomPaint(
                                size: const Size(double.infinity, 180),
                                painter: _RoutePainter(),
                              ),
                              // Floating Shifting Truck Icon
                              Positioned(
                                top: 40,
                                left: 60,
                                child: FadeInLeft(
                                  delay: const Duration(milliseconds: 300),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB5A1),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFB5A1).withAlpha(100),
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF0F172A), size: 36),
                                  ),
                                ),
                              ),
                              // Safe Shield / Carton representation
                              Positioned(
                                bottom: 30,
                                right: 50,
                                child: FadeInRight(
                                  delay: const Duration(milliseconds: 600),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E7D32),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2E7D32).withAlpha(100),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 28),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
  
                    const SizedBox(height: 24),
  
                    // Copywriting
                    FadeInUp(
                      duration: const Duration(milliseconds: 800),
                      child: const Text(
                        "Move safely.\nAvoid hidden charges.\nProtect fragile items.",
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.0,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      duration: const Duration(milliseconds: 800),
                      child: const Text(
                        "SafeShift AI compares movers using route distance, review evidence, fragile-item risk, pricing transparency, and backup recovery.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFFCFC6B0),
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
  
                    // Plan My Move CTA
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      duration: const Duration(milliseconds: 800),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => const RequestInputScreen(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                transitionDuration: const Duration(milliseconds: 500),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFB5A1),
                            foregroundColor: const Color(0xFF0F172A),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFFFB5A1).withAlpha(80),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Plan My Move",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33CFC6B0)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(30, size.height - 40)
      ..cubicTo(size.width * 0.3, size.height * 0.1, size.width * 0.6, size.height * 0.9, size.width - 30, 40);

    canvas.drawPath(path, paint);

    final dashPaint = Paint()
      ..color = const Color(0xFFFFB5A1).withAlpha(150)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Draw active dotted segment
    final activePath = Path()
      ..moveTo(30, size.height - 40)
      ..cubicTo(size.width * 0.3, size.height * 0.1, size.width * 0.45, size.height * 0.5, size.width * 0.45, size.height * 0.5);
    canvas.drawPath(activePath, dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
