import 'package:classicspin/utils/BaseUrl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class LowerGroupScreen extends StatefulWidget {
  final int pid;
  final String fullname;
  final String phonenumber;
  final String emailaddress; // Add phone number parameter
  const LowerGroupScreen({
    super.key,
    required this.pid,
    required this.fullname,
    required this.phonenumber,
    required this.emailaddress,
  });
  @override
  State<LowerGroupScreen> createState() => _LowerGroupScreenState();
}

class _LowerGroupScreenState extends State<LowerGroupScreen> with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  int selectedMultiplier = -1; // -1 to indicate no spin has occurred yet
  Color selectedColor = Colors.transparent;
  String selectedColorName = "";
  bool isSpinning = false;
  bool waitingForPayment = false;
  String? currentTransactionId;
  
  // Payment configuration
  final double spinCost = 1.0; // Cost in KES to spin the wheel

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

  // Initiate C2B payment request
Future<void> _initiateMpesaPayment() async {
  try {
    // Build request body first
    final requestBody = {
      'phone': widget.phonenumber,
      'amount': spinCost,
      'User': widget.fullname,
      'Pid': widget.pid,
      'account_reference': 'Q_${widget.pid}_${DateTime.now().millisecondsSinceEpoch}',
      'transaction_desc': 'Queue Payment',
    };

    // Print request body for debugging
    print("Request Body: ${jsonEncode(requestBody)}");

    final response = await http.post(
      Uri.parse(BaseUrl.STKPUSH),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    // Print response details for debugging
    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        currentTransactionId = data['transaction_id'];
        waitingForPayment = true;
      });

      // Start continuous wheel spinning
      _startContinuousSpinning();

      // Start polling for payment status
      _pollPaymentStatus();
    } else {
      _showErrorDialog('Failed to initiate payment. Please try again.');
    }
  } catch (e) {
    print("Error: $e"); // Print exception for debugging
    _showErrorDialog('Network error. Please check your connection.');
  }
}

  // Start continuous spinning animation
  void _startContinuousSpinning() {
    _spinController.repeat();
  }

  // Stop spinning and determine final result
  void _stopSpinningAndDetermineResult() {
    _spinController.stop();
    
    // Generate random final rotation for the result
    final random = math.Random();
    final finalPosition = random.nextDouble();
    
    _spinAnimation = Tween<double>(
      begin: _spinController.value,
      end: _spinController.value + 2 + finalPosition, // 2 more rotations + final position
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
        final winningSegment = segments[segmentIndex];
        setState(() {
          isSpinning = false;
          waitingForPayment = false;
          selectedMultiplier = winningSegment.multiplier;
          selectedColor = winningSegment.color;
          selectedColorName = winningSegment.name;
        });
        
        // Post result to backend
        _postSpinResult(winningSegment.multiplier);
      }
    });
  }

  // Poll payment status every few seconds
  void _pollPaymentStatus() async {
    if (currentTransactionId == null) return;
    
    int pollCount = 0;
    const maxPolls = 60; // Poll for up to 5 minutes (60 * 5 seconds)
    
    while (waitingForPayment && pollCount < maxPolls) {
      await Future.delayed(const Duration(seconds: 5));
      
      if (!waitingForPayment || currentTransactionId == null) break;
      
      try {
        final response = await http.get(
          Uri.parse('${BaseUrl.PAYMENTSTATUS}/$currentTransactionId'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final status = data['status'];
          
          if (status == 'completed' || status == 'success') {
            // Payment successful - stop spinning and show result
            _stopSpinningAndDetermineResult();
            break;
          } else if (status == 'failed' || status == 'cancelled') {
            // Payment failed - stop spinning and show error
            setState(() {
              isSpinning = false;
              waitingForPayment = false;
            });
            _spinController.stop();
            _showErrorDialog('Payment failed or was cancelled.');
            break;
          }
          // If status is 'pending', continue polling
        }
      } catch (e) {
        // Continue polling on network errors
        print('Error polling payment status: $e');
      }
      
      pollCount++;
    }
    
    // If we've exceeded max polls, show timeout error
    if (pollCount >= maxPolls && waitingForPayment) {
      setState(() {
        isSpinning = false;
        waitingForPayment = false;
      });
      _spinController.stop();
      _showErrorDialog('Payment timeout. Please try again.');
    }
  }

  // Post spin result to backend
  Future<void> _postSpinResult(int multiplier) async {
    try {
      final response = await http.post(
        Uri.parse(BaseUrl.PAYMENTRESULTS),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'pid': widget.pid,
          'odd': multiplier, // Using 'odd' as requested
          'amount': spinCost * multiplier, // Calculate winnings
          'transaction_id': currentTransactionId,
        }),
      );

      if (response.statusCode != 200) {
        print('Failed to post spin result: ${response.body}');
      }
    } catch (e) {
      print('Error posting spin result: $e');
    }
  }

  // Show payment confirmation dialog
  void _showPaymentConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone: ${widget.phonenumber}'),
              Text('Amount: KES ${spinCost.toStringAsFixed(0)}'),
              const SizedBox(height: 16),
              const Text(
                'You will receive an M-Pesa prompt on your phone. Complete the payment to join the Queue.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  isSpinning = true;
                  selectedMultiplier = -1;
                  selectedColor = Colors.transparent;
                  selectedColorName = "";
                });
                _initiateMpesaPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
               
                    // Payment status
                    if (waitingForPayment)
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 8),
                              const Text(
                                'Waiting for M-Pesa Payment...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Check your phone and enter PIN',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                    const SizedBox(height: 20),
                    
                    // Spinning Wheel
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
                            Text(
                              "Winnings: KES ${(spinCost * selectedMultiplier).toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
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
                        onPressed: (isSpinning || waitingForPayment) ? null : _showPaymentConfirmationDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: waitingForPayment ? Colors.orange : Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          waitingForPayment 
                            ? "Waiting for Payment..." 
                            : isSpinning 
                              ? "Spinning..." 
                              : "PAY KES ${spinCost.toStringAsFixed(0)} & SPIN",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    if (waitingForPayment)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              waitingForPayment = false;
                              isSpinning = false;
                            });
                            _spinController.stop();
                            _spinController.reset();
                          },
                          child: const Text(
                            'Cancel Payment',
                            style: TextStyle(color: Colors.red),
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

// Pointer painter for the wheel
class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(-15, 30);
    path.lineTo(15, 30);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}