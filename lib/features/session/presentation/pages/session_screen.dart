import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 350;
    final isMediumScreen = screenSize.width >= 350 && screenSize.width < 400;
    final isLargeScreen = screenSize.width >= 400;

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
              _buildConfigurationScreen(state, screenSize, isSmallScreen, isMediumScreen, isLargeScreen),
              CountdownOverlay(
                secondsRemaining: state.secondsRemaining,
                onCancel: () {
                  context.read<SessionBloc>().add(const CountdownCancelled());
                },
              ),
            ],
          );
        }

        return _buildConfigurationScreen(state, screenSize, isSmallScreen, isMediumScreen, isLargeScreen);
      },
    );
  }

  Widget _buildConfigurationScreen(
      states.SessionBlocState state,
      Size screenSize,
      bool isSmallScreen,
      bool isMediumScreen,
      bool isLargeScreen
      ) {
    final bg = const Color(0xFFF1F0EF);

    // Calculate responsive values
    final titleFontSize = isSmallScreen ? 22.0 : isMediumScreen ? 24.0 : 28.0;
    final previewCardHeight = isSmallScreen ? 150.0 : isMediumScreen ? 160.0 : 180.0;
    final presetNumberFontSize = isSmallScreen ? 36.0 : isMediumScreen ? 44.0 : 52.0;
    final presetLabelFontSize = isSmallScreen ? 12.0 : isMediumScreen ? 14.0 : 16.0;
    final verticalDialWidth = isSmallScreen ? 80.0 : isMediumScreen ? 90.0 : 100.0;
    final arrowButtonSize = isSmallScreen ? 50.0 : isMediumScreen ? 54.0 : 64.0;
    final arrowButtonHeight = isSmallScreen ? 38.0 : isMediumScreen ? 42.0 : 46.0;
    final playButtonSize = isSmallScreen ? 56.0 : isMediumScreen ? 60.0 : 64.0;
    final playIconSize = isSmallScreen ? 30.0 : isMediumScreen ? 32.0 : 36.0;
    final smallCircleSize = isSmallScreen ? 32.0 : 36.0;
    final smallCircleIconSize = isSmallScreen ? 16.0 : 18.0;

    final isValidDuration = state.config.duration.inMinutes >= 1;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // top header
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.05,
                  vertical: screenSize.height * 0.015
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // left spacer
                  Text(
                    'Focus Lock',
                    style: TextStyle(
                      fontSize: titleFontSize,
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

            // preview card
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.04,
                  vertical: screenSize.height * 0.015
              ),
              child: SizedBox(
                height: previewCardHeight,
                child: _PreviewCard(
                  configState: state,
                  isSmallScreen: isSmallScreen,
                  isMediumScreen: isMediumScreen,
                  isLargeScreen: isLargeScreen,
                ),
              ),
            ),

            SizedBox(height: screenSize.height * 0.02),

            // presets + vertical dial + fine controls row
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04),
                child: Row(
                  children: [
                    // presets grid (left)
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.read<SessionBloc>().add(
                                          PresetSelected(
                                            const Duration(minutes: 15),
                                          ),
                                        ),
                                    child: Container(
                                      height: double.infinity,
                                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                                      decoration: BoxDecoration(
                                        color:
                                        state.config.duration ==
                                            const Duration(minutes: 15)
                                            ? const Color(0xFF4C4441)
                                            : Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(40),
                                          bottomLeft: Radius.circular(40),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "15",
                                            style: TextStyle(
                                              fontSize: presetNumberFontSize,
                                              fontWeight: FontWeight.w700,
                                              color:
                                              state.config.duration ==
                                                  const Duration(
                                                    minutes: 15,
                                                  )
                                                  ? Colors.white
                                                  : const Color(0xFF7A7170),
                                            ),
                                          ),
                                          SizedBox(height: isSmallScreen ? 4.0 : 8.0),
                                          Text(
                                            "Minutes",
                                            style: TextStyle(
                                              fontSize: presetLabelFontSize,
                                              color:
                                              state.config.duration ==
                                                  const Duration(
                                                    minutes: 15,
                                                  )
                                                  ? Colors.white
                                                  : const Color(0xFF7A7170),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.read<SessionBloc>().add(
                                          PresetSelected(
                                            const Duration(minutes: 30),
                                          ),
                                        ),
                                    child: Container(
                                      height: double.infinity,
                                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                                      decoration: BoxDecoration(
                                        color:
                                        state.config.duration ==
                                            const Duration(minutes: 30)
                                            ? const Color(0xFF4C4441)
                                            : Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          topRight: Radius.circular(40),
                                          bottomRight: Radius.circular(40),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "30",
                                            style: TextStyle(
                                              fontSize: presetNumberFontSize,
                                              fontWeight: FontWeight.w700,
                                              color:
                                              state.config.duration ==
                                                  const Duration(
                                                    minutes: 30,
                                                  )
                                                  ? Colors.white
                                                  : const Color(0xFF7A7170),
                                            ),
                                          ),
                                          SizedBox(height: isSmallScreen ? 4.0 : 8.0),
                                          Text(
                                            "Minutes",
                                            style: TextStyle(
                                              fontSize: presetLabelFontSize,
                                              color:
                                              state.config.duration ==
                                                  const Duration(
                                                    minutes: 30,
                                                  )
                                                  ? Colors.white
                                                  : const Color(0xFF7A7170),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                          Expanded(
                            flex: 5,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              context.read<SessionBloc>().add(
                                                PresetSelected(
                                                  const Duration(hours: 1),
                                                ),
                                              ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(isSmallScreen ? 14.0 : 18.0),
                                            decoration: BoxDecoration(
                                              color:
                                              state.config.duration ==
                                                  const Duration(hours: 1)
                                                  ? const Color(0xFF4C4441)
                                                  : Colors.white,
                                              borderRadius:
                                              const BorderRadius.only(
                                                topLeft: Radius.circular(
                                                  40,
                                                ),
                                                topRight: Radius.circular(
                                                  20,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "1",
                                                  style: TextStyle(
                                                    fontSize: presetNumberFontSize * 0.8,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                    state.config.duration ==
                                                        const Duration(
                                                          hours: 1,
                                                        )
                                                        ? Colors.white
                                                        : const Color(
                                                      0xFF7A7170,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: isSmallScreen ? 4.0 : 6.0),
                                                Text(
                                                  "Hour",
                                                  style: TextStyle(
                                                    fontSize: presetLabelFontSize * 0.85,
                                                    color:
                                                    state.config.duration ==
                                                        const Duration(
                                                          hours: 1,
                                                        )
                                                        ? Colors.white
                                                        : const Color(
                                                      0xFF7A7170,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () =>
                                              context.read<SessionBloc>().add(
                                                PresetSelected(
                                                  const Duration(hours: 2),
                                                ),
                                              ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: EdgeInsets.all(isSmallScreen ? 14.0 : 18.0),
                                            decoration: BoxDecoration(
                                              color:
                                              state.config.duration ==
                                                  const Duration(hours: 2)
                                                  ? const Color(0xFF4C4441)
                                                  : Colors.white,
                                              borderRadius:
                                              const BorderRadius.only(
                                                bottomLeft: Radius.circular(
                                                  40,
                                                ),
                                                bottomRight:
                                                Radius.circular(20),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  "2",
                                                  style: TextStyle(
                                                    fontSize: presetNumberFontSize * 0.8,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                    state.config.duration ==
                                                        const Duration(
                                                          hours: 2,
                                                        )
                                                        ? Colors.white
                                                        : const Color(
                                                      0xFF7A7170,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: isSmallScreen ? 4.0 : 6.0),
                                                Text(
                                                  "Hours",
                                                  style: TextStyle(
                                                    fontSize: presetLabelFontSize * 0.85,
                                                    color:
                                                    state.config.duration ==
                                                        const Duration(
                                                          hours: 2,
                                                        )
                                                        ? Colors.white
                                                        : const Color(
                                                      0xFF7A7170,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: isSmallScreen ? 6.0 : 8.0),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () =>
                                        context.read<SessionBloc>().add(
                                          PresetSelected(
                                            const Duration(hours: 3),
                                          ),
                                        ),
                                    child: Container(
                                      height: double.infinity,
                                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                                      decoration: BoxDecoration(
                                        color:
                                        state.config.duration ==
                                            const Duration(hours: 3)
                                            ? const Color(0xFF4C4441)
                                            : Colors.white,
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(10),
                                          topRight: Radius.circular(40),
                                          bottomRight: Radius.circular(40),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "3",
                                            style: TextStyle(
                                              fontSize: presetNumberFontSize * 1.1,
                                              fontWeight: FontWeight.w700,
                                              color:
                                              state.config.duration ==
                                                  const Duration(hours: 3)
                                                  ? Colors.white
                                                  : const Color(0xFF7A7170),
                                            ),
                                          ),
                                          SizedBox(height: isSmallScreen ? 4.0 : 8.0),
                                          Text(
                                            "Hours",
                                            style: TextStyle(
                                              fontSize: presetLabelFontSize,
                                              color:
                                              state.config.duration ==
                                                  const Duration(hours: 3)
                                                  ? Colors.white
                                                  : const Color(0xFF7A7170),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: isSmallScreen ? 8.0 : 10.0),

                    // vertical dial + arrow buttons (right)
                    SizedBox(
                      width: verticalDialWidth,
                      child: Column(
                        children: [
                          Expanded(
                            child: _VerticalDial(
                              selectedDuration: state.config.duration,
                              onChanged: (d) {
                                context.read<SessionBloc>().add(TimeChanged(d));
                              },
                              isSmallScreen: isSmallScreen,
                              isMediumScreen: isMediumScreen,
                              isLargeScreen: isLargeScreen,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 8.0 : 10.0),
                          _ArrowButton(
                            icon: Icons.keyboard_arrow_up,
                            onTap: () {
                              final next = _adjustMinutes(
                                state.config.duration,
                                1,
                              );
                              context.read<SessionBloc>().add(
                                TimeChanged(next),
                              );
                            },
                            size: arrowButtonSize,
                            height: arrowButtonHeight,
                          ),
                          SizedBox(height: isSmallScreen ? 6.0 : 8.0),
                          _ArrowButton(
                            icon: Icons.keyboard_arrow_down,
                            onTap: () {
                              final next = _adjustMinutes(
                                state.config.duration,
                                -1,
                              );
                              context.read<SessionBloc>().add(
                                TimeChanged(next),
                              );
                            },
                            size: arrowButtonSize,
                            height: arrowButtonHeight,
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
              padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.045,
                  vertical: screenSize.height * 0.02
              ),
              child: Row(
                children: [
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 10.0 : 12.0,
                      vertical: isSmallScreen ? 6.0 : 8.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      children: [
                        _SmallCircle(
                            icon: Icons.timer,
                            size: smallCircleSize,
                            iconSize: smallCircleIconSize
                        ),
                        SizedBox(width: isSmallScreen ? 10.0 : 12.0),
                        _SmallCircle(
                            icon: Icons.show_chart,
                            filled: false,
                            size: smallCircleSize,
                            iconSize: smallCircleIconSize
                        ),
                        SizedBox(width: isSmallScreen ? 10.0 : 12.0),
                        _SmallCircle(
                            icon: Icons.settings,
                            filled: false,
                            size: smallCircleSize,
                            iconSize: smallCircleIconSize
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12.0 : 15.0),
                  // big play
                  GestureDetector(
                    onTap: () => isValidDuration
                        ? context.read<SessionBloc>().add(
                      const SessionStartRequested(),
                    )
                        : null,
                    child: Container(
                      width: playButtonSize,
                      height: playButtonSize,
                      decoration: BoxDecoration(
                        color: isValidDuration ? const Color(0xFF1E1B1A) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: playIconSize,
                      ),
                    ),
                  ),
                  Spacer(),
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

class _PreviewCard extends StatefulWidget {
  final states.SessionBlocState configState;
  final bool isSmallScreen;
  final bool isMediumScreen;
  final bool isLargeScreen;

  const _PreviewCard({
    required this.configState,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.isLargeScreen,
  });

  @override
  State<_PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<_PreviewCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  String _format(Duration d) {
    if (d.inHours > 0) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${d.inMinutes}';
  }

  double _getDifficultyPosition(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return widget.isSmallScreen ? 90.0 : widget.isMediumScreen ? 100.0 : 110.0;
      case 'intermediate':
        return widget.isSmallScreen ? 70.0 : widget.isMediumScreen ? 80.0 : 85.0;
      case 'expert':
        return widget.isSmallScreen ? 50.0 : widget.isMediumScreen ? 55.0 : 60.0;
      case 'legendary':
        return widget.isSmallScreen ? 30.0 : widget.isMediumScreen ? 32.0 : 35.0;
      default:
        return widget.isSmallScreen ? 90.0 : widget.isMediumScreen ? 100.0 : 110.0;
    }
  }

  int _getActiveDifficultyIndex(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 3;
      case 'intermediate':
        return 2;
      case 'expert':
        return 1;
      case 'legendary':
        return 0;
      default:
        return 3;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return const Color(0xFF4CAF50);
      case 'intermediate':
        return const Color(0xFFFF9800);
      case 'expert':
        return const Color(0xFFFF5722);
      case 'legendary':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF5E504C);
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(_PreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.configState.config.difficultyLabel !=
        widget.configState.config.difficultyLabel) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.configState.config.duration;
    final difficulty = widget.configState.config.difficultyLabel;
    final activeDifficultyIndex = _getActiveDifficultyIndex(difficulty);
    final difficultyColor = _getDifficultyColor(difficulty);
    final tagPosition = _getDifficultyPosition(difficulty);

    // Calculate responsive values
    final timeFontSize = widget.isSmallScreen ? 56.0 : widget.isMediumScreen ? 64.0 : 72.0;
    final tagFontSize = widget.isSmallScreen ? 10.0 : 12.0;
    final lineContainerHeight = widget.isSmallScreen ? 100.0 : widget.isMediumScreen ? 110.0 : 120.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(widget.isSmallScreen ? 16.0 : 20.0),
            child: Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        duration.inHours > 0
                            ? duration.inHours.toString().padLeft(2, '0')
                            : '00',
                        style: TextStyle(
                          fontSize: timeFontSize,
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF5E504C),
                        ),
                      ),
                      Text(
                        (duration.inMinutes % 60).toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontSize: timeFontSize,
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF5E504C),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: widget.isSmallScreen ? 20.0 : 24.0,
                        height: lineContainerHeight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(
                            17,
                                (i) {
                              final isBlackLine =
                                  i == 3 || i == 7 || i == 11 || i == 15;
                              int blackLineIndex = -1;

                              if (i == 15)
                                blackLineIndex = 0;
                              else if (i == 11)
                                blackLineIndex = 1;
                              else if (i == 7)
                                blackLineIndex = 2;
                              else if (i == 3)
                                blackLineIndex = 3;

                              final isActiveBlackLine =
                                  isBlackLine &&
                                      blackLineIndex == activeDifficultyIndex;

                              return AnimatedBuilder(
                                animation: _scaleAnimation,
                                builder: (context, child) {
                                  final scale = isActiveBlackLine
                                      ? _scaleAnimation.value
                                      : 1.0;

                                  return Transform.scale(
                                    scale: scale,
                                    child: Container(
                                      width: isBlackLine
                                          ? (isActiveBlackLine ?
                                      (widget.isSmallScreen ? 14.0 : 18.0)
                                          : (widget.isSmallScreen ? 12.0 : 14.0))
                                          : (widget.isSmallScreen ? 6.0 : 8.0),
                                      height: isBlackLine ? 3.0 : 1.5,
                                      decoration: BoxDecoration(
                                        color: isBlackLine
                                            ? (isActiveBlackLine
                                            ? difficultyColor
                                            : const Color(0xFF5E504C))
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: isActiveBlackLine
                                            ? [
                                          BoxShadow(
                                            color: difficultyColor
                                                .withOpacity(0.4),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                            : null,
                                      ),
                                    ),
                                  );
                                },
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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            top: tagPosition,
            right: widget.isSmallScreen ? 50.0 : widget.isMediumScreen ? 60.0 : 70.0,
            child: AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: ClipPath(
                    clipper: ChevronClipper(),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isSmallScreen ? 16.0 : 20.0,
                        vertical: widget.isSmallScreen ? 8.0 : 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5E504C),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        difficulty,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: tagFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChevronClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width - 12, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 12, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _VerticalDial extends StatefulWidget {
  final Duration selectedDuration;
  final ValueChanged<Duration> onChanged;
  final bool isSmallScreen;
  final bool isMediumScreen;
  final bool isLargeScreen;

  const _VerticalDial({
    super.key,
    required this.selectedDuration,
    required this.onChanged,
    required this.isSmallScreen,
    required this.isMediumScreen,
    required this.isLargeScreen,
  });

  @override
  State<_VerticalDial> createState() => _VerticalDialState();
}

class _VerticalDialState extends State<_VerticalDial>
    with TickerProviderStateMixin {
  late ScrollController _controller;
  late List<int> marks;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  double get itemHeight => widget.isSmallScreen ? 16.0 : widget.isMediumScreen ? 17.0 : 18.0;
  int _currentIndex = 0;
  int _previousIndex = -1;
  bool _isSnapping = false;

  @override
  void initState() {
    super.initState();
    marks = List<int>.generate(61, (i) => i * 5);
    final initialIndex = (widget.selectedDuration.inMinutes / 5).round().clamp(
      0,
      marks.length - 1,
    );
    _currentIndex = initialIndex;
    _previousIndex = initialIndex;

    _controller = ScrollController(
      initialScrollOffset: initialIndex * itemHeight,
    );

    _snapController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _snapAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _snapController,
      curve: Curves.easeOutBack,
    ));

    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant _VerticalDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDuration != widget.selectedDuration) {
      final idx = (widget.selectedDuration.inMinutes / 5).round().clamp(
        0,
        marks.length - 1,
      );
      _animateToIndex(idx);
    }
  }

  void _onScroll() {
    if (_isSnapping) return;

    final offset = _controller.offset;
    final newIndex = (offset / itemHeight).round().clamp(0, marks.length - 1);

    if (newIndex != _currentIndex) {
      _currentIndex = newIndex;

      if (_previousIndex != _currentIndex) {
        _triggerHapticFeedback();
        _previousIndex = _currentIndex;
      }
    }
  }

  void _triggerHapticFeedback() {
    HapticFeedback.mediumImpact();

    if (marks[_currentIndex] % 15 == 0 && marks[_currentIndex] > 0) {
      Future.delayed(const Duration(milliseconds: 50), () {
        HapticFeedback.heavyImpact();
      });
    }

    if (marks[_currentIndex] % 60 == 0 && marks[_currentIndex] > 0) {
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.vibrate();
      });
    }
  }

  void _animateToIndex(int index) {
    _isSnapping = true;
    final targetOffset = index * itemHeight;

    _controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
    ).then((_) {
      _isSnapping = false;
      _currentIndex = index;
      _previousIndex = index;
    });
  }

  void _onScrollEnd() {
    if (_isSnapping) return;

    final offset = _controller.offset;
    final targetIndex = (offset / itemHeight).round().clamp(0, marks.length - 1);

    _snapToIndex(targetIndex);
  }

  void _snapToIndex(int index) {
    _isSnapping = true;
    final targetOffset = index * itemHeight;

    HapticFeedback.selectionClick();

    _controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
    ).then((_) {
      _isSnapping = false;
      _currentIndex = index;
      _previousIndex = index;

      final minutes = marks[index];
      widget.onChanged(Duration(minutes: minutes));

      HapticFeedback.lightImpact();
    });
  }

  void _onTapPosition(int index) {
    HapticFeedback.mediumImpact();
    _snapToIndex(index);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    _snapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: NotificationListener<ScrollEndNotification>(
        onNotification: (notification) {
          if (!_isSnapping) {
            Future.delayed(const Duration(milliseconds: 50), () {
              _onScrollEnd();
            });
          }
          return true;
        },
        child: NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            if (_controller.position.pixels <= 0 ||
                _controller.position.pixels >= _controller.position.maxScrollExtent) {
              HapticFeedback.lightImpact();
            }
            return false;
          },
          child: ListView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            itemExtent: itemHeight,
            itemCount: marks.length + 4,
            itemBuilder: (context, index) {
              if (index < 2 || index >= marks.length + 2) {
                return SizedBox(height: itemHeight);
              }

              final markIndex = index - 2;
              final mark = marks[markIndex];
              final isCenter = markIndex == _currentIndex;

              return GestureDetector(
                onTap: () => _onTapPosition(markIndex),
                child: Center(
                  child: Container(
                    width: widget.isSmallScreen ? 32.0 : 40.0,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: isCenter ? const Color(0xFFFF6B30) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final double height;

  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.size,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: height,
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
  final double size;
  final double iconSize;

  const _SmallCircle({
    required this.icon,
    this.filled = true,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF5E504C) : Colors.transparent,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        icon,
        color: filled ? Colors.white : const Color(0xFF6F6664),
        size: iconSize,
      ),
    );
  }
}