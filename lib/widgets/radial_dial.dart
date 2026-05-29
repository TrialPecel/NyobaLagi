import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class RadialDial extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String positionText;
  final String durationText;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final void Function(double)? onSeek;

  const RadialDial({
    Key? key,
    required this.progress,
    required this.positionText,
    required this.durationText,
    required this.isPlaying,
    required this.onTogglePlay,
    this.onSeek,
  }) : super(key: key);

  void _handlePan(Offset localPosition, Size size) {
    if (onSeek == null) return;
    
    final center = Offset(size.width / 2, size.height);
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    // Calculate angle using atan2
    // Angle goes from -pi (left) to 0 (right)
    double angle = math.atan2(dy, dx);

    // If angle is positive, it means they dragged below the center line.
    // Snap to 0% if on the left half, 100% if on the right half.
    double newProgress;
    if (angle > 0) {
      newProgress = dx < 0 ? 0.0 : 1.0;
    } else {
      // Map angle from [-pi, 0] to [0.0, 1.0]
      newProgress = (angle + math.pi) / math.pi;
    }

    newProgress = newProgress.clamp(0.0, 1.0);
    onSeek!(newProgress);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: 300,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: GestureDetector(
              onPanStart: (details) => _handlePan(details.localPosition, const Size(300, 150)),
              onPanUpdate: (details) => _handlePan(details.localPosition, const Size(300, 150)),
              child: Container(
                color: Colors.transparent, // Required to catch gestures over empty space
                child: CustomPaint(
                  size: const Size(300, 150),
                  painter: _DialPainter(progress: progress),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: onTogglePlay,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1E1E1E),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      positionText,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      durationText,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white54,
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

class _DialPainter extends CustomPainter {
  final double progress;

  _DialPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    final paintTicks = Paint()
      ..color = Colors.white30
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintIndicator = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw dotted semicircle (180 degrees)
    // Start from left (pi) to right (0)
    int numTicks = 60;
    for (int i = 0; i <= numTicks; i++) {
      double angle = math.pi + (math.pi * i / numTicks);
      
      // Calculate start and end of each tick
      double tickLength = i % 5 == 0 ? 12.0 : 6.0;
      double startX = center.dx + (radius - tickLength) * math.cos(angle);
      double startY = center.dy + (radius - tickLength) * math.sin(angle);
      double endX = center.dx + radius * math.cos(angle);
      double endY = center.dy + radius * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paintTicks);
    }

    // Draw progress indicator line
    // Angle goes from math.pi (0%) to 0 (100%)
    double progressAngle = math.pi + (math.pi * progress);
    double startX = center.dx + (radius - 20) * math.cos(progressAngle);
    double startY = center.dy + (radius - 20) * math.sin(progressAngle);
    double endX = center.dx + (radius + 10) * math.cos(progressAngle);
    double endY = center.dy + (radius + 10) * math.sin(progressAngle);

    canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paintIndicator);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
