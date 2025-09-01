import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../bloc/session_bloc.dart';
import '../bloc/session_event.dart';
import '../bloc/session_state.dart' as states;
import '../widgets/countdown_overlay.dart';
import 'active_session_screen.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SessionBloc>().add(const SessionInitialized());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionBloc, states.SessionBlocState>(
      listener: (context, state) {
        if (state is states.SessionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is states.SessionActive) {
          return ActiveSessionScreen(
            remainingTime: state.remainingTime,
            totalDuration: state.config.duration,
            startTime: state.startTime,
            onSessionComplete: () {
              context.read<SessionBloc>().add(const SessionCompleted());
            },
            onEmergencyExit: () {
              context.read<SessionBloc>().add(const SessionCancelled());
            },
          );
        }

        if (state is states.SessionCompleted) {
          return ActiveSessionScreen(
            remainingTime: Duration.zero,
            totalDuration: state.config.duration,
            startTime: state.completedAt.subtract(state.config.duration),
            onSessionComplete: () {
              context.read<SessionBloc>().add(const SessionReset());
            },
          );
        }

        if (state is states.SessionCountdown) {
          return Stack(
            children: [
              _buildConfigurationScreen(state),
              CountdownOverlay(
                secondsRemaining: state.secondsRemaining,
                onCancel: () {
                  context.read<SessionBloc>().add(const CountdownCancelled());
                },
              ),
            ],
          );
        }

        return _buildConfigurationScreen(state);
      },
    );
  }

  Widget _buildConfigurationScreen(states.SessionBlocState state) {
    final bg = const Color(0xFFF1F0EF);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // top header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // left spacer
                  Text(
                    'Focus Lock',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF5E504C),
                      letterSpacing: 2,
                    ),
                  ),
                  InkWell(
                    onTap: () => ProfileDialog.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF5E504C)),
                    ),
                  ),
                ],
              ),
            ),

            // preview card - FIXED DIMENSIONS AND LAYOUT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _PreviewCard(configState: state),
            ),

            const SizedBox(height: 18),

            // presets + vertical dial + fine controls row
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // presets grid (left)
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: _PresetTile(
                                    labelTop: '15',
                                    labelBottom: 'Minutes',
                                    selected:
                                    state.config.duration == const Duration(minutes: 15),
                                    onTap: () => context
                                        .read<SessionBloc>()
                                        .add(PresetSelected(const Duration(minutes: 15))),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PresetTile(
                                    labelTop: '30',
                                    labelBottom: 'Minutes',
                                    selected:
                                    state.config.duration == const Duration(minutes: 30),
                                    onTap: () => context
                                        .read<SessionBloc>()
                                        .add(PresetSelected(const Duration(minutes: 30))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: _PresetTile.small(
                                          labelTop: '1',
                                          labelBottom: 'Hour',
                                          selected:
                                          state.config.duration == const Duration(hours: 1),
                                          onTap: () => context
                                              .read<SessionBloc>()
                                              .add(PresetSelected(const Duration(hours: 1))),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Expanded(
                                        child: _PresetTile.small(
                                          labelTop: '2',
                                          labelBottom: 'Hours',
                                          selected:
                                          state.config.duration == const Duration(hours: 2),
                                          onTap: () => context
                                              .read<SessionBloc>()
                                              .add(PresetSelected(const Duration(hours: 2))),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _PresetTile(
                                    labelTop: '3',
                                    labelBottom: 'Hours',
                                    selected:
                                    state.config.duration == const Duration(hours: 3),
                                    onTap: () => context
                                        .read<SessionBloc>()
                                        .add(PresetSelected(const Duration(hours: 3))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // vertical dial + arrow buttons (right)
                    SizedBox(
                      width: 92,
                      child: Column(
                        children: [
                          Expanded(
                            child: _VerticalDial(
                              selectedDuration: state.config.duration,
                              onChanged: (d) {
                                context.read<SessionBloc>().add(TimeChanged(d));
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          _ArrowButton(
                            icon: Icons.keyboard_arrow_up,
                            onTap: () {
                              final next = _adjustMinutes(state.config.duration, 1);
                              context.read<SessionBloc>().add(TimeChanged(next));
                            },
                          ),
                          const SizedBox(height: 10),
                          _ArrowButton(
                            icon: Icons.keyboard_arrow_down,
                            onTap: () {
                              final next = _adjustMinutes(state.config.duration, -1);
                              context.read<SessionBloc>().add(TimeChanged(next));
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // bottom nav + start/play button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        _SmallCircle(icon: Icons.timer),
                        const SizedBox(width: 12),
                        _SmallCircle(icon: Icons.show_chart, filled: false),
                        const SizedBox(width: 12),
                        _SmallCircle(icon: Icons.settings, filled: false),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // big play
                  GestureDetector(
                    onTap: () {
                      context.read<SessionBloc>().add(const SessionStartRequested());
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1B1A),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                        ],
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _adjustMinutes(Duration d, int delta) {
    final minutes = (d.inMinutes + delta).clamp(1, 8 * 60);
    return Duration(minutes: minutes);
  }
}

/* ------------------ FIXED PREVIEW CARD ------------------ */

class _PreviewCard extends StatelessWidget {
  final states.SessionBlocState configState;
  const _PreviewCard({required this.configState});

  String _format(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${d.inMinutes}';
  }

  @override
  Widget build(BuildContext context) {
    final duration = configState.config.duration;
    final difficulty = configState.config.difficultyLabel;

    return Container(
      height: 180, // Increased height for better proportions
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Left side - Time display (takes up more space)
            Expanded(
              flex: 7,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hours display
                  Text(
                    duration.inHours > 0
                        ? duration.inHours.toString().padLeft(2, '0')
                        : '00',
                    style: const TextStyle(
                      fontSize: 72,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5E504C),
                    ),
                  ),
                  // Minutes display
                  Text(
                    (duration.inMinutes % 60).toString().padLeft(2, '0'),
                    style: const TextStyle(
                      fontSize: 72,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF5E504C),
                    ),
                  ),
                ],
              ),
            ),

            // Right side - Difficulty and ticks
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Difficulty tag with proper arrow styling
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5E504C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          difficulty,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Vertical ticks indicator
                  Container(
                    width: 24,
                    height: 80,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        9, // Reduced number of ticks for better spacing
                            (i) {
                          final isMiddle = i == 4;
                          final isQuarter = i == 2 || i == 6;
                          return Container(
                            width: isMiddle ? 16.0 : (isQuarter ? 12.0 : 8.0),
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: isMiddle
                                  ? const Color(0xFFFF6B30) // Orange for center
                                  : (isQuarter ? const Color(0xFF5E504C) : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ------------------ OTHER WIDGETS (unchanged) ------------------ */

class _PresetTile extends StatelessWidget {
  final String labelTop;
  final String labelBottom;
  final bool selected;
  final VoidCallback onTap;
  final bool small;

  const _PresetTile({
    required this.labelTop,
    required this.labelBottom,
    required this.selected,
    required this.onTap,
  }) : small = false;

  const _PresetTile.small({
    required this.labelTop,
    required this.labelBottom,
    required this.selected,
    required this.onTap,
  }) : small = true;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF4C4441) : Colors.white;
    final textColor = selected ? Colors.white : const Color(0xFF7A7170);
    final radius = 16.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              labelTop,
              style: TextStyle(
                fontSize: small ? 34 : 44,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labelBottom,
              style: TextStyle(
                fontSize: small ? 12 : 14,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDial extends StatefulWidget {
  final Duration selectedDuration;
  final ValueChanged<Duration> onChanged;

  const _VerticalDial({
    super.key,
    required this.selectedDuration,
    required this.onChanged,
  });

  @override
  State<_VerticalDial> createState() => _VerticalDialState();
}

class _VerticalDialState extends State<_VerticalDial> {
  late ScrollController _controller;
  late List<int> marks; // each mark = minutes
  static const double itemHeight = 18;

  @override
  void initState() {
    super.initState();
    marks = List<int>.generate(61, (i) => i * 5); // 0..300 minutes step 5
    final initialIndex = (widget.selectedDuration.inMinutes / 5).round().clamp(0, marks.length - 1);
    _controller = ScrollController(initialScrollOffset: initialIndex * itemHeight);
  }

  @override
  void didUpdateWidget(covariant _VerticalDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDuration != widget.selectedDuration) {
      final idx = (widget.selectedDuration.inMinutes / 5).round().clamp(0, marks.length - 1);
      _controller.animateTo(idx * itemHeight, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  void _onScrollEnd() {
    final offset = _controller.offset;
    final idx = (offset / itemHeight).round().clamp(0, marks.length - 1);
    final minutes = marks[idx];
    widget.onChanged(Duration(minutes: minutes));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (n) {
          _onScrollEnd();
          return true;
        },
        child: ListView.builder(
          controller: _controller,
          physics: const ClampingScrollPhysics(),
          itemExtent: itemHeight,
          itemCount: marks.length + 4,
          itemBuilder: (context, index) {
            if (index < 2 || index >= marks.length + 2) return const SizedBox(height: itemHeight);
            final mark = marks[index - 2];
            final isCenter = ((index - 2) == (widget.selectedDuration.inMinutes / 5).round());
            return Center(
              child: Container(
                width: 40,
                height: 6,
                margin: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isCenter ? const Color(0xFFFF6B30) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: const Color(0xFF6F6664)),
      ),
    );
  }
}

class _SmallCircle extends StatelessWidget {
  final IconData icon;
  final bool filled;
  const _SmallCircle({required this.icon, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF5E504C) : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: filled ? Colors.white : const Color(0xFF6F6664), size: 18),
    );
  }
}