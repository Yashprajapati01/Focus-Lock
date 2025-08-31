import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum PermissionType { notification, admin, overlay, calling }

enum PermissionStatus { pending, granted, denied }

class Permission extends Equatable {
  final PermissionType type;
  final PermissionStatus status;
  final String title;
  final String description;
  final IconData icon;

  const Permission({
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.icon,
  });

  Permission copyWith({
    PermissionType? type,
    PermissionStatus? status,
    String? title,
    String? description,
    IconData? icon,
  }) {
    return Permission(
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }

  bool get isGranted => status == PermissionStatus.granted;
  bool get isDenied => status == PermissionStatus.denied;
  bool get isPending => status == PermissionStatus.pending;

  @override
  List<Object> get props => [type, status, title, description, icon];
}

extension PermissionTypeExtension on PermissionType {
  String get displayName {
    switch (this) {
      case PermissionType.notification:
        return 'Notifications';
      case PermissionType.admin:
        return 'Device Admin';
      case PermissionType.overlay:
        return 'Display Over Apps';
      case PermissionType.calling:
        return 'App Usage Access';
    }
  }

  String get description {
    switch (this) {
      case PermissionType.notification:
        return 'Allow the app to send you notifications about focus sessions and app status';
      case PermissionType.admin:
        return 'Grant device administrator privileges to manage settings and enforce restrictions';
      case PermissionType.overlay:
        return 'Allow the app to display lock screens and blocking interfaces over other apps';
      case PermissionType.calling:
        return 'Allow the app to track which apps you use and how often to provide focus insights';
    }
  }

  IconData get icon {
    switch (this) {
      case PermissionType.notification:
        return Icons.notifications;
      case PermissionType.admin:
        return Icons.admin_panel_settings;
      case PermissionType.overlay:
        return Icons.layers;
      case PermissionType.calling:
        return Icons.analytics;
    }
  }
}
