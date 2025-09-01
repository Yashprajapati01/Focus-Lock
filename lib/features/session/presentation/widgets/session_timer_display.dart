import 'package:flutter/material.dart';

class SessionTimerDisplay extends StatelessWidget {
  final Duration remainingTime;
  final Duration totalDuration;
  final bool showProgress;

  const SessionTimerDisplay({
    super.key,
    required this.remainingTime,
    required this.totalDuration,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = 1.0 - (remainingTime.inSeconds / totalDuration.inSeconds);

    return Container(
      width: 280,
      height: 280,
      child: Stack(
        children: [
          // Background circle
          if (showProgress)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                strokeWidth: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),

          // Timer text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main time display
                Text(
                  _formatTime(remainingTime),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontSize: 56,
                    letterSpacing: -2,
                  ),
                ),

                const SizedBox(height: 8),

                // Remaining label
                Text(
                  'remaining',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white60,
                    letterSpacing: 1.5,
                  ),
                ),

                if (showProgress) ...[
                  const SizedBox(height: 16),

                  // Progress percentage
                  Text(
                    '${(progress * 100).round()}% complete',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}
