import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PresetButtons extends StatelessWidget {
  final Duration selectedDuration;
  final Function(Duration) onPresetSelected;

  const PresetButtons({
    super.key,
    required this.selectedDuration,
    required this.onPresetSelected,
  });

  static const List<Duration> presets = [
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  static final Map<Duration, String> presetLabels = {
    const Duration(minutes: 1): '1m',
    const Duration(minutes: 5): '5m',
    const Duration(minutes: 15): '15m',
    const Duration(minutes: 30): '30m',
    const Duration(hours: 1): '1h',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final preset = presets[index];
          final isSelected = preset == selectedDuration;

          return _PresetButton(
            duration: preset,
            label: presetLabels[preset]!,
            isSelected: isSelected,
            onTap: () {
              HapticFeedback.selectionClick();
              onPresetSelected(preset);
            },
          );
        },
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  final Duration duration;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.duration,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.primaryColor
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? theme.primaryColor
                    : theme.colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: theme.textTheme.labelLarge!.copyWith(
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}
