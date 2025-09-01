import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';
import 'package:focuslock/features/permissions/widgets/permission_card.dart';
import 'package:focuslock/features/permissions/widgets/permission_progress_indicator.dart';
import 'package:focuslock/features/shared/widgets/error_display.dart';

import '../bloc/permission_bloc_exports.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  static const routeName = '/permissions';

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    // Load permissions when screen initializes
    context.read<PermissionBloc>().add(const LoadAllPermissions());

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Refresh permissions when app resumes from background
    if (state == AppLifecycleState.resumed) {
      // Add a small delay to ensure the app is fully resumed
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          context.read<PermissionBloc>().add(const LoadAllPermissions());
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<PermissionBloc, PermissionState>(
        listener: (context, state) {
          if (state is PermissionError && state.permissions.isNotEmpty) {
            // Show error for individual permission requests
            _showPermissionErrorSnackBar(context, state.message);
          } else if (state is PermissionAllGranted) {
            // Show celebration animation or feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 8),
                    Text('All permissions granted! 🎉'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else if (state is PermissionLoaded || state is PermissionUpdated) {
            // Check if all permissions are granted on load/update
            final permissions = state is PermissionLoaded
                ? state.permissions
                : (state as PermissionUpdated).permissions;
            final allGranted =
                permissions.isNotEmpty && permissions.every((p) => p.isGranted);

            if (state is PermissionUpdated) {
              // Check if a permission was just granted and show feedback
              final grantedPermissions = permissions
                  .where((p) => p.isGranted)
                  .length;
              final previousGranted =
                  (state as PermissionUpdated).progress.grantedPermissions;

              if (grantedPermissions > previousGranted) {
                // A new permission was granted
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Permission granted!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            }
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(context, state),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PermissionState state) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          if (state is PermissionLoaded ||
              state is PermissionUpdated ||
              state is PermissionAllGranted ||
              state is PermissionRequestInProgress ||
              (state is PermissionError && state.permissions.isNotEmpty)) ...[
            _buildProgressSection(state),
            const SizedBox(height: 32),
            _buildPermissionsList(state),
          ] else if (state is PermissionLoading) ...[
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ] else if (state is PermissionError && state.permissions.isEmpty) ...[
            Expanded(
              child: ErrorDisplay(
                message: state.message,
                errorType: ErrorType.permission,
                onRetry: () {
                  context.read<PermissionBloc>().add(
                    const LoadAllPermissions(),
                  );
                },
              ),
            ),
          ] else ...[
            Expanded(
              child: ErrorDisplay(
                message:
                    'Unable to load permissions. Please check your connection and try again.',
                errorType: ErrorType.network,
                onRetry: () {
                  context.read<PermissionBloc>().add(
                    const LoadAllPermissions(),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildContinueButton(state),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.security, size: 64, color: Colors.blue.shade600),
        const SizedBox(height: 16),
        Text(
          'App Permissions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Grant these permissions to unlock all features',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressSection(PermissionState state) {
    final progress = _getProgress(state);
    if (progress == null) return const SizedBox.shrink();

    return PermissionProgressIndicator(
      progress: progress,
      fadeController: _fadeController,
    );
  }

  Widget _buildPermissionsList(PermissionState state) {
    final permissions = _getPermissions(state);
    if (permissions.isEmpty) return const SizedBox.shrink();

    return Expanded(
      child: ListView.separated(
        itemCount: permissions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final permission = permissions[index];
          final isRequesting =
              state is PermissionRequestInProgress &&
              state.requestingType == permission.type;

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 300 + (index * 150)),
            tween: Tween<double>(begin: 0.0, end: 1.0),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: PermissionCard(
                    permission: permission,
                    isRequesting: isRequesting,
                    onTap: () {
                      _requestPermission(context, permission);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildContinueButton(PermissionState state) {
    final progress = _getProgress(state);
    final isComplete = progress?.isComplete ?? false;

    return Column(
      children: [
        if (!isComplete) ...[
          Text(
            'Grant all permissions to unlock the full experience',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isComplete
                ? () {
                    // Add scale animation on press
                    _slideController.reverse().then((_) {
                      if (mounted) {
                        // Navigate to main app
                        Navigator.of(context).pushReplacementNamed('/home');
                      }
                    });
                  }
                : () {
                    // Show helpful message when not complete
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Please grant the remaining permissions to continue',
                        ),
                        backgroundColor: Colors.orange,
                        action: SnackBarAction(
                          label: 'OK',
                          textColor: Colors.white,
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          },
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isComplete ? Colors.green : Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Row(
                key: ValueKey(isComplete),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isComplete) ...[
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                  ] else ...[
                    const Icon(Icons.arrow_forward, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isComplete ? 'Continue to App' : 'Continue Anyway',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isComplete) ...[
          const SizedBox(height: 12),
          Text(
            'You can grant permissions later in settings',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  List<Permission> _getPermissions(PermissionState state) {
    if (state is PermissionLoaded) return state.permissions;
    if (state is PermissionUpdated) return state.permissions;
    if (state is PermissionAllGranted) return state.permissions;
    if (state is PermissionRequestInProgress) return state.permissions;
    if (state is PermissionError) return state.permissions;
    return [];
  }

  PermissionProgress? _getProgress(PermissionState state) {
    if (state is PermissionLoaded) return state.progress;
    if (state is PermissionUpdated) return state.progress;
    if (state is PermissionAllGranted) return state.progress;
    if (state is PermissionRequestInProgress) return state.progress;
    if (state is PermissionError) return state.progress;
    return null;
  }

  void _requestPermission(BuildContext context, Permission permission) {
    // Show loading feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (permission.isDenied) {
      // Show confirmation dialog for denied permissions
      _showRetryPermissionDialog(context, permission);
    } else if (permission.isPending) {
      // Request permission normally
      context.read<PermissionBloc>().add(
        RequestPermissionEvent(type: permission.type),
      );
    } else {
      // Permission is already granted, show info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${permission.title} is already granted'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showRetryPermissionDialog(BuildContext context, Permission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(permission.icon, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Expanded(child: Text('${permission.title} Permission')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This permission was denied. To use all features of Focus Lock, please grant this permission.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      permission.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PermissionBloc>().add(
                RequestPermissionEvent(type: permission.type),
              );
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<PermissionBloc>().add(
                OpenPermissionSettingsEvent(type: permission.type),
              );
            },
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Determine error type based on message content
    IconData icon = Icons.security;
    Color backgroundColor = Colors.red.shade600;

    if (message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('connection')) {
      icon = Icons.wifi_off;
      backgroundColor = Colors.orange.shade600;
    } else if (message.toLowerCase().contains('denied') ||
        message.toLowerCase().contains('permission')) {
      icon = Icons.block;
      backgroundColor = Colors.purple.shade600;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            context.read<PermissionBloc>().add(const LoadAllPermissions());
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
