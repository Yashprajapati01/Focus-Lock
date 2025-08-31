import 'package:flutter/material.dart';
import 'package:focuslock/features/permissions/domain/entities/permission.dart';
import '../../../../core/utils/typedef.dart';

class PermissionModel extends Permission {
  const PermissionModel({
    required super.type,
    required super.status,
    required super.title,
    required super.description,
    required super.icon,
  });

  factory PermissionModel.fromJson(DataMap json) {
    return PermissionModel(
      type: PermissionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => PermissionType.notification,
      ),
      status: PermissionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PermissionStatus.pending,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      icon: IconData(
        json['iconCodePoint'] as int,
        fontFamily: json['iconFontFamily'] as String?,
        fontPackage: json['iconFontPackage'] as String?,
      ),
    );
  }

  DataMap toJson() {
    return {
      'type': type.toString(),
      'status': status.toString(),
      'title': title,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
    };
  }

  factory PermissionModel.fromEntity(Permission permission) {
    return PermissionModel(
      type: permission.type,
      status: permission.status,
      title: permission.title,
      description: permission.description,
      icon: permission.icon,
    );
  }

  @override
  PermissionModel copyWith({
    PermissionType? type,
    PermissionStatus? status,
    String? title,
    String? description,
    IconData? icon,
  }) {
    return PermissionModel(
      type: type ?? this.type,
      status: status ?? this.status,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
    );
  }

  factory PermissionModel.initial(PermissionType type) {
    return PermissionModel(
      type: type,
      status: PermissionStatus.pending,
      title: type.displayName,
      description: type.description,
      icon: type.icon,
    );
  }
}
