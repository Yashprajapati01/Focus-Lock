import 'package:flutter/material.dart';

enum ErrorType { network, authentication, permission, general }

class ErrorDisplay extends StatefulWidget {
  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
    this.errorType = ErrorType.general,
    this.showAnimation = true,
  });

  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final ErrorType errorType;
  final bool showAnimation;

  @override
  State<ErrorDisplay> createState() => _ErrorDisplayState();
}

class _ErrorDisplayState extends State<ErrorDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    if (widget.showAnimation) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData get _errorIcon {
    if (widget.icon != null) return widget.icon!;

    switch (widget.errorType) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.authentication:
        return Icons.account_circle_outlined;
      case ErrorType.permission:
        return Icons.security;
      case ErrorType.general:
        return Icons.error_outline;
    }
  }

  Color get _errorColor {
    switch (widget.errorType) {
      case ErrorType.network:
        return Colors.orange.shade400;
      case ErrorType.authentication:
        return Colors.blue.shade400;
      case ErrorType.permission:
        return Colors.purple.shade400;
      case ErrorType.general:
        return Colors.red.shade400;
    }
  }

  String get _errorTitle {
    switch (widget.errorType) {
      case ErrorType.network:
        return 'Connection Problem';
      case ErrorType.authentication:
        return 'Authentication Failed';
      case ErrorType.permission:
        return 'Permission Error';
      case ErrorType.general:
        return 'Oops! Something went wrong';
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_errorIcon, size: 64, color: _errorColor),
          const SizedBox(height: 16),
          Text(
            _errorTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildHelpText(),
        ],
      ),
    );

    if (!widget.showAnimation) return content;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(scale: _scaleAnimation, child: content),
        );
      },
    );
  }

  Widget _buildHelpText() {
    String helpText;
    switch (widget.errorType) {
      case ErrorType.network:
        helpText = 'Check your internet connection and try again';
        break;
      case ErrorType.authentication:
        helpText = 'Make sure you have a valid Google account';
        break;
      case ErrorType.permission:
        helpText = 'You can grant permissions later in settings';
        break;
      case ErrorType.general:
        helpText = 'If the problem persists, please contact support';
        break;
    }

    return Text(
      helpText,
      style: TextStyle(
        fontSize: 14,
        color: Colors.grey.shade500,
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }
}
