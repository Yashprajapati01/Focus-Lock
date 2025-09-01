import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimeDial extends StatefulWidget {
  final Duration selectedDuration;
  final Function(Duration) onDurationChanged;
  final Duration minDuration;
  final Duration maxDuration;

  const TimeDial({
    super.key,
    required this.selectedDuration,
    required this.onDurationChanged,
    this.minDuration = const Duration(minutes: 1),
    this.maxDuration = const Duration(hours: 8),
  });

  @override
  State<TimeDial> createState() => _TimeDialState();
}

class _TimeDialState extends State<TimeDial> {
  late ScrollController _scrollController;
  late List<Duration> _timeOptions;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _generateTimeOptions();
    _selectedIndex = _findSelectedIndex();
    _scrollController = ScrollController(
      initialScrollOffset: _selectedIndex * _itemHeight,
    );
  }

  @override
  void didUpdateWidget(TimeDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDuration != widget.selectedDuration) {
      _selectedIndex = _findSelectedIndex();
      _scrollToSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  static const double _itemHeight = 50.0;
  static const int _visibleItems = 5;

  void _generateTimeOptions() {
    _timeOptions = [];

    // Generate 1-minute increments from 1 to 10 minutes
    for (int minutes = 1; minutes <= 10; minutes += 1) {
      _timeOptions.add(Duration(minutes: minutes));
    }

    // Generate 5-minute increments from 15 minutes to 2 hours
    for (int minutes = 15; minutes <= 120; minutes += 5) {
      _timeOptions.add(Duration(minutes: minutes));
    }

    // Generate 15-minute increments from 2h 15m to 4 hours
    for (int minutes = 135; minutes <= 240; minutes += 15) {
      _timeOptions.add(Duration(minutes: minutes));
    }

    // Generate 30-minute increments from 4h 30m to 8 hours
    for (int minutes = 270; minutes <= 480; minutes += 30) {
      _timeOptions.add(Duration(minutes: minutes));
    }

    // Filter by min/max duration
    _timeOptions = _timeOptions.where((duration) {
      return duration >= widget.minDuration && duration <= widget.maxDuration;
    }).toList();
  }

  int _findSelectedIndex() {
    for (int i = 0; i < _timeOptions.length; i++) {
      if (_timeOptions[i] == widget.selectedDuration) {
        return i;
      }
    }

    // Find closest duration if exact match not found
    int closestIndex = 0;
    int minDifference = (widget.selectedDuration - _timeOptions[0]).inMinutes
        .abs();

    for (int i = 1; i < _timeOptions.length; i++) {
      int difference = (widget.selectedDuration - _timeOptions[i]).inMinutes
          .abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _selectedIndex * _itemHeight,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final offset = _scrollController.offset;
    final newIndex = (offset / _itemHeight).round().clamp(
      0,
      _timeOptions.length - 1,
    );

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });

      HapticFeedback.selectionClick();
      widget.onDurationChanged(_timeOptions[_selectedIndex]);
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    } else {
      return '${duration.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _itemHeight * _visibleItems,
      child: Stack(
        children: [
          // Selection indicator
          Positioned(
            top: _itemHeight * 2,
            left: 0,
            right: 0,
            height: _itemHeight,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),

          // Scrollable list
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification) {
                _onScroll();
              }
              return true;
            },
            child: ListView.builder(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              itemExtent: _itemHeight,
              itemCount: _timeOptions.length + 4, // Add padding items
              itemBuilder: (context, index) {
                // Add padding items at start and end
                if (index < 2 || index >= _timeOptions.length + 2) {
                  return const SizedBox(height: _itemHeight);
                }

                final timeIndex = index - 2;
                final duration = _timeOptions[timeIndex];
                final isSelected = timeIndex == _selectedIndex;

                return _TimeDialItem(
                  duration: duration,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedIndex = timeIndex;
                    });
                    _scrollToSelected();
                    HapticFeedback.selectionClick();
                    widget.onDurationChanged(duration);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeDialItem extends StatelessWidget {
  final Duration duration;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeDialItem({
    required this.duration,
    required this.isSelected,
    required this.onTap,
  });

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}m';
      }
    } else {
      return '${duration.inMinutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: isSelected ? 20 : 16,
          ),
          child: Text(_formatDuration(duration)),
        ),
      ),
    );
  }
}
