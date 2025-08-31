import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';

class PermissionCard extends StatefulWidget {
  const PermissionCard({
    super.key,
    required this.permission,
    required this.onTap,
    this.isRequesting = false,
  });

  final Permission permission;
  final VoidCallback onTap;
  final bool isRequesting;

  @override
  State<PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<PermissionCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _statusAnimationController;
  late AnimationController _bounceController;
  late AnimationController _shakeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shakeAnimation;

  PermissionStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _previousStatus = widget.permission.status;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _statusAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _statusAnimationController.dispose();
    _bounceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PermissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if status changed and trigger appropriate animation
    if (_previousStatus != widget.permission.status) {
      _triggerStatusChangeAnimation(_previousStatus, widget.permission.status);
      _previousStatus = widget.permission.status;
    }
  }

  void _triggerStatusChangeAnimation(
    PermissionStatus? oldStatus,
    PermissionStatus newStatus,
  ) {
    if (oldStatus == PermissionStatus.pending &&
        newStatus == PermissionStatus.granted) {
      // Bounce animation for successful grant
      _bounceController.forward().then((_) => _bounceController.reverse());
    } else if (oldStatus == PermissionStatus.pending &&
        newStatus == PermissionStatus.denied) {
      // Shake animation for denial
      _shakeController.forward().then((_) => _shakeController.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _bounceAnimation,
        _shakeAnimation,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _bounceAnimation.value,
          child: Transform.translate(
            offset: Offset(sin(_shakeAnimation.value * pi * 6) * 5, 0),
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _animationController.reverse(),
              onTapCancel: () => _animationController.reverse(),
              onTap: widget.isRequesting
                  ? null
                  : () {
                      // Add haptic feedback
                      HapticFeedback.lightImpact();
                      widget.onTap();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getBackgroundColor(),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBorderColor(), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _getShadowColor(),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildIcon(),
                    const SizedBox(width: 16),
                    Expanded(child: _buildContent()),
                    const SizedBox(width: 16),
                    _buildStatusIndicator(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getIconBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          widget.permission.icon,
          key: ValueKey(widget.permission.status),
          color: _getIconColor(),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.permission.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.permission.description,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator() {
    if (widget.isRequesting) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    switch (widget.permission.status) {
      case PermissionStatus.granted:
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 600),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Color.lerp(Colors.orange, Colors.green, value),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3 * value),
                      blurRadius: 8 * value,
                      spreadRadius: 2 * value,
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.check,
                    key: const ValueKey('check'),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        );
      case PermissionStatus.denied:
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Column(
              children: [
                Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color.lerp(Colors.orange, Colors.red, value),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.2 * value),
                          blurRadius: 6 * value,
                          spreadRadius: 1 * value,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.close,
                        key: const ValueKey('close'),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedOpacity(
                  opacity: value,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      case PermissionStatus.pending:
        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            final pulseValue = (sin(value * 4 * pi) * 0.1) + 1.0;
            return Transform.scale(
              scale: pulseValue,
              child: Transform.translate(
                offset: Offset(sin(value * 2 * pi) * 3, 0),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Icon(
                      Icons.arrow_forward,
                      key: const ValueKey('arrow'),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            );
          },
        );
    }
  }

  Color _getBackgroundColor() {
    switch (widget.permission.status) {
      case PermissionStatus.granted:
        return Colors.green.shade50;
      case PermissionStatus.denied:
        return Colors.red.shade50;
      case PermissionStatus.pending:
        return Colors.white;
    }
  }

  Color _getBorderColor() {
    switch (widget.permission.status) {
      case PermissionStatus.granted:
        return Colors.green.shade200;
      case PermissionStatus.denied:
        return Colors.red.shade200;
      case PermissionStatus.pending:
        return Colors.blue.shade200;
    }
  }

  Color _getIconBackgroundColor() {
    switch (widget.permission.status) {
      case PermissionStatus.granted:
        return Colors.green.shade100;
      case PermissionStatus.denied:
        return Colors.red.shade100;
      case PermissionStatus.pending:
        return Colors.blue.shade100;
    }
  }

  Color _getIconColor() {
    switch (widget.permission.status) {
      case PermissionStatus.granted:
        return Colors.green.shade700;
      case PermissionStatus.denied:
        return Colors.red.shade700;
      case PermissionStatus.pending:
        return Colors.blue.shade700;
    }
  }

  Color _getShadowColor() {
    switch (widget.permission.status) {
      case PermissionStatus.granted:
        return Colors.green.withValues(alpha: 0.15);
      case PermissionStatus.denied:
        return Colors.red.withValues(alpha: 0.15);
      case PermissionStatus.pending:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }
}
