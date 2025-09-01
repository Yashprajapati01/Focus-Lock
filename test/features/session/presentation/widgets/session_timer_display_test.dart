import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/presentation/widgets/session_timer_display.dart';

void main() {
  group('SessionTimerDisplay', () {
    Widget createWidgetUnderTest({
      Duration? remainingTime,
      Duration? totalDuration,
      bool showProgress = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SessionTimerDisplay(
            remainingTime: remainingTime ?? const Duration(minutes: 15),
            totalDuration: totalDuration ?? const Duration(minutes: 30),
            showProgress: showProgress,
          ),
        ),
      );
    }

    testWidgets('displays time in MM:SS format for minutes only', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 5, seconds: 30),
        ),
      );

      expect(find.text('05:30'), findsOneWidget);
    });

    testWidgets('displays time in HH:MM:SS format for hours', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(hours: 1, minutes: 30, seconds: 45),
        ),
      );

      expect(find.text('01:30:45'), findsOneWidget);
    });

    testWidgets('displays remaining label', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('remaining'), findsOneWidget);
    });

    testWidgets('shows progress circle when showProgress is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 10),
          totalDuration: const Duration(minutes: 30),
          showProgress: true,
        ),
      );

      final progressIndicator = find.byType(CircularProgressIndicator);
      expect(progressIndicator, findsOneWidget);

      final progressWidget = tester.widget<CircularProgressIndicator>(
        progressIndicator,
      );
      expect(progressWidget.value, closeTo(0.67, 0.01)); // (30-10)/30 = 2/3
    });

    testWidgets('hides progress circle when showProgress is false', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(showProgress: false));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('displays progress percentage when showProgress is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 12),
          totalDuration: const Duration(minutes: 30),
          showProgress: true,
        ),
      );

      expect(find.text('60% complete'), findsOneWidget);
    });

    testWidgets('hides progress percentage when showProgress is false', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(showProgress: false));

      expect(find.textContaining('% complete'), findsNothing);
    });

    testWidgets('calculates progress correctly', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 5),
          totalDuration: const Duration(minutes: 20),
        ),
      );

      final progressIndicator = find.byType(CircularProgressIndicator);
      final progressWidget = tester.widget<CircularProgressIndicator>(
        progressIndicator,
      );
      expect(progressWidget.value, equals(0.75)); // (20-5)/20 = 3/4
    });

    testWidgets('handles zero remaining time', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: Duration.zero,
          totalDuration: const Duration(minutes: 30),
        ),
      );

      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('100% complete'), findsOneWidget);

      final progressIndicator = find.byType(CircularProgressIndicator);
      final progressWidget = tester.widget<CircularProgressIndicator>(
        progressIndicator,
      );
      expect(progressWidget.value, equals(1.0));
    });

    testWidgets('handles full remaining time', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 30),
          totalDuration: const Duration(minutes: 30),
        ),
      );

      expect(find.text('30:00'), findsOneWidget);
      expect(find.text('0% complete'), findsOneWidget);

      final progressIndicator = find.byType(CircularProgressIndicator);
      final progressWidget = tester.widget<CircularProgressIndicator>(
        progressIndicator,
      );
      expect(progressWidget.value, equals(0.0));
    });

    testWidgets('pads single digit minutes and seconds with zero', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 5, seconds: 7),
        ),
      );

      expect(find.text('05:07'), findsOneWidget);
    });

    testWidgets('pads single digit hours with zero', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(hours: 2, minutes: 5, seconds: 7),
        ),
      );

      expect(find.text('02:05:07'), findsOneWidget);
    });

    testWidgets('has correct container dimensions', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final container = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(container);

      expect(containerWidget.constraints?.maxWidth, equals(280));
      expect(containerWidget.constraints?.maxHeight, equals(280));
    });

    testWidgets('uses correct text styles', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Main time display should use displayLarge style
      final timeText = find.text('15:00');
      expect(timeText, findsOneWidget);

      // Remaining label should use bodyLarge style
      final remainingText = find.text('remaining');
      expect(remainingText, findsOneWidget);

      // Progress percentage should use bodyMedium style
      final progressText = find.text('50% complete');
      expect(progressText, findsOneWidget);
    });

    testWidgets('handles edge case of very long duration', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(hours: 23, minutes: 59, seconds: 59),
        ),
      );

      expect(find.text('23:59:59'), findsOneWidget);
    });

    testWidgets('rounds progress percentage correctly', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(seconds: 199), // 3:19
          totalDuration: const Duration(seconds: 300), // 5:00
        ),
      );

      // Progress should be (300-199)/300 = 101/300 = 0.3367 = 34% when rounded
      expect(find.text('34% complete'), findsOneWidget);
    });

    testWidgets('clamps progress value between 0 and 1', (tester) async {
      // Test with remaining time greater than total (edge case)
      await tester.pumpWidget(
        createWidgetUnderTest(
          remainingTime: const Duration(minutes: 40),
          totalDuration: const Duration(minutes: 30),
        ),
      );

      final progressIndicator = find.byType(CircularProgressIndicator);
      final progressWidget = tester.widget<CircularProgressIndicator>(
        progressIndicator,
      );
      expect(progressWidget.value, equals(0.0)); // Should be clamped to 0
    });
  });
}
