import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/session_timer_display.dart';

class ActiveSessionScreen extends StatefulWidget {
  final Duration remainingTime;
  final Duration totalDuration;
  final DateTime startTime;
  final VoidCallback? onSessionComplete;
  final VoidCallback? onEmergencyExit;

  const ActiveSessionScreen({
    super.key,
    required this.remainingTime,
    required this.totalDuration,
    required this.startTime,
    this.onSessionComplete,
    this.onEmergencyExit,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late AnimationController _progressController;
  late Animation<double> _breathingAnimation;
  late Animation<double> _progressAnimation;

  int _currentTipIndex = 0;
  Timer? _tipCyclingTimer;
  final List<String> _focusTips = [
    'Take deep breaths to stay centered',
    'Focus on one task at a time',
    'Your mind is your most powerful tool',
    'Every moment of focus builds discipline',
    'You are in control of your attention',
    'Progress happens one focused minute at a time',
    'Distractions are temporary, focus is forever',
    'This is your time to create something meaningful',
  ];

  @override
  void initState() {
    super.initState();

    // Hide system UI for immersive experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _breathingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _breathingAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_progressController);

    // Start breathing animation
    _breathingController.repeat(reverse: true);

    // Set initial progress
    final initialProgress =
        1.0 - (widget.remainingTime.inSeconds / widget.totalDuration.inSeconds);
    _progressController.value = initialProgress.clamp(0.0, 1.0);

    // Cycle through tips every 30 seconds
    _startTipCycling();
  }

  @override
  void didUpdateWidget(ActiveSessionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.remainingTime != widget.remainingTime) {
      _updateProgress();

      // Check if session completed
      if (widget.remainingTime.inSeconds <= 0) {
        _handleSessionComplete();
      }
    }
  }

  @override
  void dispose() {
    // Restore system UI when leaving the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _tipCyclingTimer?.cancel();
    _breathingController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final progress =
        1.0 - (widget.remainingTime.inSeconds / widget.totalDuration.inSeconds);
    _progressController.animateTo(progress.clamp(0.0, 1.0));

    // Update the lock screen service with remaining time
    _updateLockScreenService();
  }

  void _updateLockScreenService() {
    // This will be handled by the native Android code
    // The overlay service will automatically update its timer
  }

  void _startTipCycling() {
    _tipCyclingTimer?.cancel();
    _tipCyclingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _focusTips.length;
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _handleSessionComplete() {
    // Trigger completion celebration
    HapticFeedback.heavyImpact();
    widget.onSessionComplete?.call();
  }

  void _handleEmergencyExit() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EmergencyExitDialog(
        onConfirm: () {
          Navigator.of(context).pop();
          widget.onEmergencyExit?.call();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.remainingTime.inSeconds <= 0;

    return PopScope(
      canPop: false, // Prevent back navigation
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: isCompleted
              ? _buildCompletionView()
              : _buildActiveSessionView(),
        ),
      ),
    );
  }

  Widget _buildActiveSessionView() {
    return Stack(
      children: [
        // Main content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Session status
              Text(
                'Focus Session Active',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                ),
              ),

              const SizedBox(height: 40),

              // Timer display with breathing animation
              AnimatedBuilder(
                animation: _breathingAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _breathingAnimation.value,
                    child: SessionTimerDisplay(
                      remainingTime: widget.remainingTime,
                      totalDuration: widget.totalDuration,
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              // Progress bar
              _buildProgressBar(),

              const SizedBox(height: 40),

              // Focus tip
              _buildFocusTip(),
            ],
          ),
        ),

        // Emergency exit button (hidden, activated by specific gesture)
        Positioned(
          top: 20,
          right: 20,
          child: GestureDetector(
            onLongPress: _handleEmergencyExit,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Completion icon
          Icon(Icons.check_circle, size: 120, color: Colors.green.shade400),

          const SizedBox(height: 32),

          // Completion message
          Text(
            'Session Complete!',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // Duration completed
          Text(
            'You focused for ${_formatDuration(widget.totalDuration)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white70),
          ),

          const SizedBox(height: 32),

          // Celebration message
          Text(
            'Great job! You\'ve strengthened your focus muscle.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      width: 280,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return LinearProgressIndicator(
            value: _progressAnimation.value,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            minHeight: 8,
          );
        },
      ),
    );
  }

  Widget _buildFocusTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Text(
          _focusTips[_currentTipIndex],
          key: ValueKey(_currentTipIndex),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white60,
            fontStyle: FontStyle.italic,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

class _EmergencyExitDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _EmergencyExitDialog({required this.onConfirm, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade900,
      title: Text('Emergency Exit', style: TextStyle(color: Colors.white)),
      content: Text(
        'Are you sure you want to end your focus session early? This will unlock your device.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Continue Session',
            style: TextStyle(color: Theme.of(context).primaryColor),
          ),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
          child: const Text('End Session'),
        ),
      ],
    );
  }
}
