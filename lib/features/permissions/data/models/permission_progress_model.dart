import 'package:focuslock/features/permissions/domain/entities/permission_progress.dart';

import '../../../../core/utils/typedef.dart';

class PermissionProgressModel extends PermissionProgress {
  const PermissionProgressModel({
    required super.totalPermissions,
    required super.grantedPermissions,
    required super.progressPercentage,
    required super.isComplete,
  });

  factory PermissionProgressModel.fromJson(DataMap json) {
    return PermissionProgressModel(
      totalPermissions: json['totalPermissions'] as int,
      grantedPermissions: json['grantedPermissions'] as int,
      progressPercentage: (json['progressPercentage'] as num).toDouble(),
      isComplete: json['isComplete'] as bool,
    );
  }

  DataMap toJson() {
    return {
      'totalPermissions': totalPermissions,
      'grantedPermissions': grantedPermissions,
      'progressPercentage': progressPercentage,
      'isComplete': isComplete,
    };
  }

  factory PermissionProgressModel.fromEntity(PermissionProgress progress) {
    return PermissionProgressModel(
      totalPermissions: progress.totalPermissions,
      grantedPermissions: progress.grantedPermissions,
      progressPercentage: progress.progressPercentage,
      isComplete: progress.isComplete,
    );
  }

  factory PermissionProgressModel.initial() {
    return const PermissionProgressModel(
      totalPermissions: 4,
      grantedPermissions: 0,
      progressPercentage: 0.0,
      isComplete: false,
    );
  }

  factory PermissionProgressModel.fromGrantedCount(
    int grantedCount,
    int totalCount,
  ) {
    final percentage = totalCount > 0 ? (grantedCount / totalCount) : 0.0;
    return PermissionProgressModel(
      totalPermissions: totalCount,
      grantedPermissions: grantedCount,
      progressPercentage: percentage,
      isComplete: grantedCount == totalCount,
    );
  }

  @override
  PermissionProgressModel copyWith({
    int? totalPermissions,
    int? grantedPermissions,
    double? progressPercentage,
    bool? isComplete,
  }) {
    return PermissionProgressModel(
      totalPermissions: totalPermissions ?? this.totalPermissions,
      grantedPermissions: grantedPermissions ?? this.grantedPermissions,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
