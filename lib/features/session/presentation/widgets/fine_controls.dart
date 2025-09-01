import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FineControls extends StatefulWidget {
  final Duration selectedDuration;
  final Function(Duration) onDurationChanged;
  final Duration minDuration;
  final Duration maxDuration;
  final Duration increment;

  const FineControls({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
    this.minDuration = const Duration(minutes: 1),
    this.maxDuration = const Duration(hours: 8),
    this.increment = const Duration(minutes: 1),
  });

  @override
  State<FineControls> createState() => _FineControlsState();
}

class _FineControlsState extends State<FineControls> {
  Timer? _longPressTimer;
  Timer? _accelerationTimer;
  bool _isLongPressing = false;
  int _accelerationLevel = 1;

  void _increment() {
    final newDuration = widget.selectedDuration + widget.increment;
    if (newDuration <= widget.maxDuration) {
      HapticFeedback.selectionClick();
      widget.onDurationChanged(newDuration);
    }
  }

  void _decrement() {
    final newDuration = widget.selectedDuration - widget.increment;
    if (newDuration >= widget.minDuration) {
      HapticFeedback.selectionClick();
      widget.onDurationChanged(newDuration);
    }
  }

  void _startLongPress(bool isIncrement) {
    _isLongPressing = true;
    _accelerationLevel = 1;

    // Initial delay before starting continuous adjustment
    _longPressTimer = Timer(const Duration(milliseconds: 500), () {
      _startContinuousAdjustment(isIncrement);
    });
  }

  void _startContinuousAdjustment(bool isIncrement) {
    if (!_isLongPressing) return;

    // Perform the adjustment
    if (isIncrement) {
      _increment();
    } else {
      _decrement();
    }

    // Calculate next interval with acceleration
    int interval = 200 ~/ _accelerationLevel;
    interval = interval.clamp(50, 200); // Min 50ms, max 200ms

    _accelerationTimer = Timer(Duration(milliseconds: interval), () {
      if (_isLongPressing) {
        // Increase acceleration level every few adjustments
        if (_accelerationLevel < 4) {
          _accelerationLevel++;
        }
        _startContinuousAdjustment(isIncrement);
      }
    });
  }

  void _stopLongPress() {
    _isLongPressing = false;
    _accelerationLevel = 1;
    _longPressTimer?.cancel();
    _accelerationTimer?.cancel();
    _longPressTimer = null;
    _accelerationTimer = null;
  }

  @override
  void dispose() {
    _stopLongPress();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canIncrement = widget.selectedDuration < widget.maxDuration;
    final canDecrement = widget.selectedDuration > widget.minDuration;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decrement button
          _FineControlButton(
            icon: Icons.remove,
            enabled: canDecrement,
            onTap: _decrement,
            onLongPressStart: () => _startLongPress(false),
            onLongPressEnd: _stopLongPress,
            tooltip:
                'Decrease by ${widget.increment.inMinutes} minute${widget.increment.inMinutes != 1 ? 's' : ''}',
          ),

          // Current duration display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Text(
              _formatDuration(widget.selectedDuration),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          // Increment button
          _FineControlButton(
            icon: Icons.add,
            enabled: canIncrement,
            onTap: _increment,
            onLongPressStart: () => _startLongPress(true),
            onLongPressEnd: _stopLongPress,
            tooltip:
                'Increase by ${widget.increment.inMinutes} minute${widget.increment.inMinutes != 1 ? 's' : ''}',
          ),
        ],
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

class _FineControlButton extends StatefulWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;
  final String tooltip;

  const _FineControlButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
    required this.tooltip,
  });

  @override
  State<_FineControlButton> createState() => _FineControlButtonState();
}

class _FineControlButtonState extends State<_FineControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.enabled) {
      setState(() => _isPressed = true);
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onLongPressStart: widget.enabled
            ? (_) => widget.onLongPressStart()
            : null,
        onLongPressEnd: widget.enabled ? (_) => widget.onLongPressEnd() : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.enabled
                      ? (_isPressed
                            ? Theme.of(context).primaryColor.withOpacity(0.8)
                            : Theme.of(context).primaryColor)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: widget.enabled
                        ? Theme.of(context).primaryColor
                        : Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                    width: widget.enabled ? 0 : 1,
                  ),
                  boxShadow: widget.enabled
                      ? [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.enabled
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                  size: 24,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
