import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum DifficultyLevel {
  easy, // 15-30 minutes
  intermediate, // 1-2 hours
  expert, // 3-4 hours
  legendary, // 5+ hours
}

class SessionConfig extends Equatable {
  final Duration duration;
  final DateTime? lastUsed;

  const SessionConfig({required this.duration, this.lastUsed});

  // Computed property for difficulty level based on duration
  DifficultyLevel get difficulty {
    final minutes = duration.inMinutes;
    if (minutes <= 30) {
      return DifficultyLevel.easy;
    } else if (minutes <= 120) {
      return DifficultyLevel.intermediate;
    } else if (minutes <= 240) {
      return DifficultyLevel.expert;
    } else {
      return DifficultyLevel.legendary;
    }
  }

  // Formatted time display
  String get formattedTime {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      } else {
        return '${hours}h';
      }
    } else {
      return '${minutes}m';
    }
  }

  // Difficulty color coding
  Color get difficultyColor {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.intermediate:
        return Colors.orange;
      case DifficultyLevel.expert:
        return Colors.red;
      case DifficultyLevel.legendary:
        return Colors.purple;
    }
  }

  // Difficulty label
  String get difficultyLabel {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.intermediate:
        return 'Intermediate';
      case DifficultyLevel.expert:
        return 'Expert';
      case DifficultyLevel.legendary:
        return 'Legendary';
    }
  }

  SessionConfig copyWith({Duration? duration, DateTime? lastUsed}) {
    return SessionConfig(
      duration: duration ?? this.duration,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  @override
  List<Object?> get props => [duration, lastUsed];
}
