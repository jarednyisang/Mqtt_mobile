import 'package:flutter/material.dart';
import 'dart:math' as math;

class HigherGroupScreen extends StatefulWidget {
  final int pid;
  final String fullname;
  final String phonenumber;
  final String emailaddress;
  const HigherGroupScreen({
    super.key,
    required this.pid,
    required this.fullname,
    required this.phonenumber,
    required this.emailaddress,
  });
  @override
  State<HigherGroupScreen> createState() => _HigherGroupScreenState();
}

class _HigherGroupScreenState extends State<HigherGroupScreen> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  int selectedMultiplier = -1; // -1 to indicate no spin has occurred yet
  Color selectedColor = Colors.transparent;
  String selectedColorName = "";
  bool isSpinning = false;

  // Define the colors and their multipliers
  final List<SpinSegment> segments = [
    SpinSegment(color: Colors.red, multiplier: 1, name: "Red"),
    SpinSegment(color: Colors.grey, multiplier: 3, name: "Grey"),
    SpinSegment(color: Colors.blue, multiplier: 6, name: "Blue"),
    SpinSegment(color: Colors.green, multiplier: 9, name: "Green"),
  ];
  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _spinAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spin() {
    if (isSpinning) return;

    setState(() {
      isSpinning = true;
      selectedMultiplier = -1; // Reset result display
      selectedColor = Colors.transparent;
      selectedColorName = "";
    });
    // Generate random final rotation (multiple full rotations + random position)
    final random = math.Random();
    final extraRotations = 5 + random.nextInt(5); // 5-10 full rotations
    final finalPosition = random.nextDouble(); // Random position between 0-1

    _spinAnimation = Tween<double>(
      begin: _spinController.value,
      end: extraRotations + finalPosition,
    ).animate(CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOut,
    ));
    _spinController.reset();
    _spinController.forward().then((_) {
      // Calculate which segment we landed on
      final normalizedPosition = finalPosition;
      final segmentSize = 1.0 / segments.length;
      int segmentIndex = (normalizedPosition / segmentSize).floor();

      // Ensure index is within bounds
      if (segmentIndex >= segments.length) {
        segmentIndex = segments.length - 1;
      } else if (segmentIndex < 0) {
        segmentIndex = 0;
      }

      if (mounted) {
        setState(() {
          isSpinning = false;
          selectedMultiplier = segments[segmentIndex].multiplier;
          selectedColor = segments[segmentIndex].color;
          selectedColorName = segments[segmentIndex].name;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade100, Colors.white],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (isLandscape) const SizedBox(height: 20),
                    // Spinning Wheel
                    // A Stack is used to correctly position the pointer on top of the wheel
                    Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isLandscape ? constraints.maxWidth * 0.4 : constraints.maxWidth * 0.9,
                            maxHeight: constraints.maxHeight * 0.6,
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              // The wheel itself
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _spinAnimation,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _spinAnimation.value * 2 * math.pi,
                                        child: CustomPaint(
                                          size: Size.infinite,
                                          painter: WheelPainter(segments: segments),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Result Display
                    if (selectedMultiplier > 0)
                      Container(
                        width: isLandscape ? constraints.maxWidth * 0.5 : constraints.maxWidth * 0.9,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: selectedColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selectedColor, width: 2),
                        ),
                        child: Column(
                          children: [
                            Text(
                              "🎉 Winner! 🎉",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: selectedColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedColorName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: selectedColor,
                              ),
                            ),
                            Text(
                              "Multiplier: ${selectedMultiplier}x",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: selectedColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (selectedMultiplier == 0 && !isSpinning && selectedColor != Colors.transparent)
                      Container(
                        width: isLandscape ? constraints.maxWidth * 0.5 : constraints.maxWidth * 0.9,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "😞 You Lose! 😞",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedColorName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              "Multiplier: ${selectedMultiplier}x",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Spin Button
                    SizedBox(
                      width: isLandscape ? constraints.maxWidth * 0.3 : constraints.maxWidth * 0.8,
                      child: ElevatedButton(
                        onPressed: isSpinning ? null : _spin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          isSpinning ? "Spinning..." : "SPIN THE WHEEL",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SpinSegment {
  final Color color;
  final int multiplier;
  final String name;
  SpinSegment({
    required this.color,
    required this.multiplier,
    required this.name,
  });
}

class WheelPainter extends CustomPainter {
  final List<SpinSegment> segments;
  WheelPainter({required this.segments});
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / segments.length;
    // Draw wheel segments
    for (int i = 0; i < segments.length; i++) {
      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;
      final startAngle = i * segmentAngle - math.pi / 2; // Start from top

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );
      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );
      // Draw multiplier text
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.7;
      final textX = center.dx + textRadius * math.cos(textAngle);
      final textY = center.dy + textRadius * math.sin(textAngle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: "${segments[i].multiplier}x",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black,
                offset: Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          textX - textPainter.width / 2,
          textY - textPainter.height / 2,
        ),
      );
    }
    // Draw center circle
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 20, centerPaint);

    final centerBorderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 20, centerBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}