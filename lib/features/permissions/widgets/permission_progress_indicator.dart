import 'package:flutter/material.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';

class PermissionProgressIndicator extends StatefulWidget {
  const PermissionProgressIndicator({
    super.key,
    required this.progress,
    required this.fadeController,
  });

  final PermissionProgress progress;
  final AnimationController fadeController;

  @override
  State<PermissionProgressIndicator> createState() =>
      _PermissionProgressIndicatorState();
}

class _PermissionProgressIndicatorState
    extends State<PermissionProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation =
        Tween<double>(
          begin: 0.0,
          end: widget.progress.progressPercentage,
        ).animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Start progress animation
    _progressController.forward();
  }

  @override
  void didUpdateWidget(PermissionProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress.progressPercentage !=
        widget.progress.progressPercentage) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.progress.progressPercentage,
            end: widget.progress.progressPercentage,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeOutCubic,
            ),
          );
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.progress.isComplete
            ? Colors.green.shade50
            : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.progress.isComplete
              ? Colors.green.shade200
              : Colors.blue.shade200,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.progress.isComplete
                    ? 'All permissions granted!'
                    : 'Permission Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.progress.isComplete
                      ? Colors.green.shade800
                      : Colors.blue.shade800,
                ),
              ),
              if (widget.progress.isComplete)
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 24)
              else
                Text(
                  '${widget.progress.grantedPermissions}/${widget.progress.totalPermissions}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  LinearProgressIndicator(
                    value: _progressAnimation.value,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.progress.isComplete
                          ? Colors.green
                          : Colors.blue.shade600,
                    ),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.progress.isComplete
                            ? 'Ready to continue!'
                            : '${widget.progress.remainingPermissions} permissions remaining',
                        style: TextStyle(
                          fontSize: 14,
                          color: widget.progress.isComplete
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${(_progressAnimation.value * 100).round()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.progress.isComplete
                              ? Colors.green.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
