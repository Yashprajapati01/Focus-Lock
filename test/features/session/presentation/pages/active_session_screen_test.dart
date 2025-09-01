import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/presentation/pages/active_session_screen.dart';
import 'package:focuslock/features/session/presentation/widgets/session_timer_display.dart';

void main() {
  group('ActiveSessionScreen', () {
    late bool sessionCompleteCalled;
    late bool emergencyExitCalled;
    late DateTime startTime;

    setUp(() {
      sessionCompleteCalled = false;
      emergencyExitCalled = false;
      startTime = DateTime.now();
    });

    Widget createWidgetUnderTest({
      Duration? remainingTime,
      Duration? totalDuration,
      DateTime? sessionStartTime,
      VoidCallback? onSessionComplete,
      VoidCallback? onEmergencyExit,
    }) {
      return MaterialApp(
        home: ActiveSessionScreen(
          remainingTime: remainingTime ?? const Duration(minutes: 25),
          totalDuration: totalDuration ?? const Duration(minutes: 30),
          startTime: sessionStartTime ?? startTime,
          onSessionComplete:
              onSessionComplete ?? () => sessionCompleteCalled = true,
          onEmergencyExit: onEmergencyExit ?? () => emergencyExitCalled = true,
        ),
      );
    }

    testWidgets('displays active session view when time remaining', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Focus Session Active'), findsOneWidget);
      expect(find.byType(SessionTimerDisplay), findsOneWidget);
    });

    testWidgets('displays completion view when time is zero', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(remainingTime: Duration.zero),
      );

      expect(find.text('Session Complete!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows session timer display', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 15),
          totalDuration: const Duration(minutes: 30),
        ),
      );

      final timerDisplay = find.byType(SessionTimerDisplay);
      expect(timerDisplay, findsOneWidget);

      final timerWidget = tester.widget<SessionTimerDisplay>(timerDisplay);
      expect(timerWidget.remainingTime, equals(const Duration(minutes: 15)));
      expect(timerWidget.totalDuration, equals(const Duration(minutes: 30)));
    });

    testWidgets('shows progress bar', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 15),
          totalDuration: const Duration(minutes: 30),
        ),
      );

      final progressIndicator = find.byType(LinearProgressIndicator);
      expect(progressIndicator, findsOneWidget);

      final progressWidget = tester.widget<LinearProgressIndicator>(
        progressIndicator,
      );
      expect(progressWidget.value, equals(0.5)); // 50% complete
    });

    testWidgets('displays focus tips', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Should find one of the focus tips
      final focusTips = [
        'Take deep breaths to stay centered',
        'Focus on one task at a time',
        'Your mind is your most powerful tool',
        'Every moment of focus builds discipline',
        'You are in control of your attention',
        'Progress happens one focused minute at a time',
        'Distractions are temporary, focus is forever',
        'This is your time to create something meaningful',
      ];

      bool foundTip = false;
      for (final tip in focusTips) {
        if (find.text(tip).evaluate().isNotEmpty) {
          foundTip = true;
          break;
        }
      }
      expect(foundTip, isTrue);
    });

    testWidgets('calls onSessionComplete when time reaches zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(remainingTime: const Duration(seconds: 1)),
      );

      // Update to zero time
      await tester.pumpWidget(
        createWidgetUnderTest(remainingTime: Duration.zero),
      );

      expect(sessionCompleteCalled, isTrue);
    });

    testWidgets('shows completion message with duration', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: Duration.zero,
          totalDuration: const Duration(minutes: 45),
        ),
      );

      expect(find.text('You focused for 45m'), findsOneWidget);
    });

    testWidgets('shows completion message with hours and minutes', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: Duration.zero,
          totalDuration: const Duration(hours: 1, minutes: 30),
        ),
      );

      expect(find.text('You focused for 1h 30m'), findsOneWidget);
    });

    testWidgets('shows completion message with hours only', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: Duration.zero,
          totalDuration: const Duration(hours: 2),
        ),
      );

      expect(find.text('You focused for 2h'), findsOneWidget);
    });

    testWidgets('prevents back navigation', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final willPopScope = find.byType(WillPopScope);
      expect(willPopScope, findsOneWidget);

      final willPopWidget = tester.widget<WillPopScope>(willPopScope);
      final result = await willPopWidget.onWillPop!();
      expect(result, isFalse);
    });

    testWidgets('has emergency exit gesture area', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find the emergency exit gesture detector
      final gestureDetectors = find.byType(GestureDetector);
      expect(gestureDetectors, findsWidgets);

      // Should have at least one gesture detector for emergency exit
      bool foundEmergencyGesture = false;
      for (int i = 0; i < tester.widgetList(gestureDetectors).length; i++) {
        final detector = tester.widget<GestureDetector>(gestureDetectors.at(i));
        if (detector.onLongPress != null) {
          foundEmergencyGesture = true;
          break;
        }
      }
      expect(foundEmergencyGesture, isTrue);
    });

    testWidgets('shows emergency exit dialog on long press', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find and long press the emergency exit area
      final emergencyArea = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      );

      await tester.longPress(emergencyArea);
      await tester.pump();

      expect(find.text('Emergency Exit'), findsOneWidget);
      expect(find.text('Continue Session'), findsOneWidget);
      expect(find.text('End Session'), findsOneWidget);
    });

    testWidgets('calls onEmergencyExit when confirmed', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Trigger emergency exit dialog
      final emergencyArea = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      );

      await tester.longPress(emergencyArea);
      await tester.pump();

      // Confirm exit
      await tester.tap(find.text('End Session'));
      await tester.pump();

      expect(emergencyExitCalled, isTrue);
    });

    testWidgets('dismisses dialog when cancelled', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Trigger emergency exit dialog
      final emergencyArea = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onLongPress != null,
      );

      await tester.longPress(emergencyArea);
      await tester.pump();

      // Cancel exit
      await tester.tap(find.text('Continue Session'));
      await tester.pump();

      expect(find.text('Emergency Exit'), findsNothing);
      expect(emergencyExitCalled, isFalse);
    });

    testWidgets('animates timer display with breathing effect', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Should have Transform.scale for breathing animation
      final transforms = find.byType(Transform);
      expect(transforms, findsWidgets);

      // Should have AnimatedBuilder for breathing animation
      final animatedBuilders = find.byType(AnimatedBuilder);
      expect(animatedBuilders, findsWidgets);
    });

    testWidgets('updates progress when remaining time changes', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 20),
          totalDuration: const Duration(minutes: 30),
        ),
      );

      // Let the widget build and set initial state
      await tester.pump();

      // Initial progress should be 1/3 complete
      final initialProgress = find.byType(LinearProgressIndicator);
      final initialWidget = tester.widget<LinearProgressIndicator>(
        initialProgress,
      );
      expect(initialWidget.value, closeTo(0.33, 0.01));

      // Update remaining time
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 10),
          totalDuration: const Duration(minutes: 30),
        ),
      );

      // Let the progress animation complete
      await tester.pump(const Duration(milliseconds: 600));

      // Progress should be 2/3 complete
      final updatedProgress = find.byType(LinearProgressIndicator);
      final updatedWidget = tester.widget<LinearProgressIndicator>(
        updatedProgress,
      );
      expect(updatedWidget.value, closeTo(0.67, 0.01));
    });

    testWidgets('cycles through focus tips', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Should have AnimatedSwitcher for tip cycling
      final animatedSwitcher = find.byType(AnimatedSwitcher);
      expect(animatedSwitcher, findsOneWidget);

      final switcherWidget = tester.widget<AnimatedSwitcher>(animatedSwitcher);
      expect(
        switcherWidget.duration,
        equals(const Duration(milliseconds: 500)),
      );
    });

    testWidgets('has black background', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final scaffold = find.byType(Scaffold);
      final scaffoldWidget = tester.widget<Scaffold>(scaffold);
      expect(scaffoldWidget.backgroundColor, equals(Colors.black));
    });

    testWidgets('handles haptic feedback on completion', (tester) async {
      // Mock haptic feedback
      final List<MethodCall> hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              hapticCalls.add(call);
            }
            return null;
          });

      await tester.pumpWidget(
        createWidgetUnderTest(remainingTime: const Duration(seconds: 1)),
      );

      // Update to completion
      await tester.pumpWidget(
        createWidgetUnderTest(remainingTime: Duration.zero),
      );

      // Verify heavy impact haptic was called
      expect(hapticCalls.length, equals(1));
      expect(
        hapticCalls.first.arguments,
        equals('HapticFeedbackType.heavyImpact'),
      );

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });
}
