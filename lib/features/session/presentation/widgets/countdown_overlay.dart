import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CountdownOverlay extends StatefulWidget {
  final int secondsRemaining;
  final VoidCallback onCancel;
  final VoidCallback? onCountdownComplete;

  const CountdownOverlay({
    super.key,
    required this.secondsRemaining,
    required this.onCancel,
    this.onCountdownComplete,
  });

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start entrance animation
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void didUpdateWidget(CountdownOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger pulse animation when countdown changes
    if (oldWidget.secondsRemaining != widget.secondsRemaining) {
      _triggerPulseAnimation();

      // Trigger haptic feedback
      if (widget.secondsRemaining > 0) {
        HapticFeedback.selectionClick();
      }

      // Check if countdown completed
      if (widget.secondsRemaining == 0) {
        widget.onCountdownComplete?.call();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _triggerPulseAnimation() {
    _scaleController.reset();
    _scaleController.forward();
  }

  void _handleCancel() {
    // Trigger exit animation
    _fadeController.reverse().then((_) {
      widget.onCancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.9),
            child: SafeArea(
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Zen mode message
                      Text(
                        'Zen mode starting soon',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w300,
                            ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 60),

                      // Countdown circle
                      AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: _CountdownCircle(
                              secondsRemaining: widget.secondsRemaining,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 60),

                      // Motivational message
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _getMotivationalMessage(),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.white70, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Cancel button
                      _CancelButton(onPressed: _handleCancel),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMotivationalMessage() {
    final messages = [
      'Take a deep breath and prepare to focus',
      'Your future self will thank you for this',
      'Great things happen when you eliminate distractions',
      'This is your time to achieve something meaningful',
      'Focus is a superpower in a distracted world',
    ];

    // Use seconds remaining to pick a consistent message
    final index = widget.secondsRemaining % messages.length;
    return messages[index];
  }
}

class _CountdownCircle extends StatelessWidget {
  final int secondsRemaining;

  const _CountdownCircle({required this.secondsRemaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
      ),
      child: Stack(
        children: [
          // Progress circle
          Positioned.fill(
            child: CircularProgressIndicator(
              value: (10 - secondsRemaining) / 10,
              strokeWidth: 4,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),

          // Countdown number
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Text(
                    '$secondsRemaining',
                    key: ValueKey(secondsRemaining),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 64,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  secondsRemaining == 1 ? 'second' : 'seconds',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _CancelButton({required this.onPressed});

  @override
  State<_CancelButton> createState() => _CancelButtonState();
}

class _CancelButtonState extends State<_CancelButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.close,
                    color: Colors.white.withOpacity(0.9),
                    size: 20,
                  ),

                  const SizedBox(width: 8),

                  Text(
                    'Cancel',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
