import 'package:equatable/equatable.dart';

class PermissionProgress extends Equatable {
  final int totalPermissions;
  final int grantedPermissions;
  final double progressPercentage;
  final bool isComplete;

  const PermissionProgress({
    required this.totalPermissions,
    required this.grantedPermissions,
    required this.progressPercentage,
    required this.isComplete,
  });

  factory PermissionProgress.initial() {
    return const PermissionProgress(
      totalPermissions: 4,
      grantedPermissions: 0,
      progressPercentage: 0.0,
      isComplete: false,
    );
  }

  factory PermissionProgress.fromGrantedCount(
    int grantedCount,
    int totalCount,
  ) {
    final percentage = totalCount > 0 ? (grantedCount / totalCount) : 0.0;
    return PermissionProgress(
      totalPermissions: totalCount,
      grantedPermissions: grantedCount,
      progressPercentage: percentage,
      isComplete: grantedCount == totalCount,
    );
  }

  PermissionProgress copyWith({
    int? totalPermissions,
    int? grantedPermissions,
    double? progressPercentage,
    bool? isComplete,
  }) {
    return PermissionProgress(
      totalPermissions: totalPermissions ?? this.totalPermissions,
      grantedPermissions: grantedPermissions ?? this.grantedPermissions,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  int get remainingPermissions => totalPermissions - grantedPermissions;

  @override
  List<Object> get props => [
    totalPermissions,
    grantedPermissions,
    progressPercentage,
    isComplete,
  ];
}
