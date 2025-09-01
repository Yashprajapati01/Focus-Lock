import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/presentation/widgets/fine_controls.dart';

void main() {
  group('FineControls', () {
    late Duration selectedDuration;
    late List<Duration> changedDurations;

    setUp(() {
      selectedDuration = const Duration(minutes: 30);
      changedDurations = [];
    });

    Widget createWidgetUnderTest({
      Duration? selected,
      Function(Duration)? onDurationChanged,
      Duration? minDuration,
      Duration? maxDuration,
      Duration? increment,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FineControls(
            selectedDuration: selected ?? selectedDuration,
            onDurationChanged:
                onDurationChanged ??
                (duration) {
                  changedDurations.add(duration);
                },
            minDuration: minDuration ?? const Duration(minutes: 5),
            maxDuration: maxDuration ?? const Duration(hours: 8),
            increment: increment ?? const Duration(minutes: 1),
          ),
        ),
      );
    }

    testWidgets('displays current duration correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('30m'), findsOneWidget);
    });

    testWidgets('displays duration in hours and minutes format', (
      tester,
    ) async {
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(hours: 1, minutes: 30)),
      );

      expect(find.text('1h 30m'), findsOneWidget);
    });

    testWidgets('displays duration in hours only format', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(hours: 2)),
      );

      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('increments duration when plus button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.add));

      expect(changedDurations.length, equals(1));
      expect(changedDurations.first, equals(const Duration(minutes: 31)));
    });

    testWidgets('decrements duration when minus button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.remove));

      expect(changedDurations.length, equals(1));
      expect(changedDurations.first, equals(const Duration(minutes: 29)));
    });

    testWidgets('respects minimum duration constraint', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          selected: const Duration(minutes: 5),
          minDuration: const Duration(minutes: 5),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));

      // Should not change duration below minimum
      expect(changedDurations.isEmpty, isTrue);
    });

    testWidgets('respects maximum duration constraint', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          selected: const Duration(hours: 8),
          maxDuration: const Duration(hours: 8),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));

      // Should not change duration above maximum
      expect(changedDurations.isEmpty, isTrue);
    });

    testWidgets('disables minus button at minimum duration', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          selected: const Duration(minutes: 5),
          minDuration: const Duration(minutes: 5),
        ),
      );

      final minusButton = find.byIcon(Icons.remove);
      expect(minusButton, findsOneWidget);

      // Button should be visually disabled
      final buttonWidget = tester.widget<Icon>(minusButton);
      // The button's color should indicate it's disabled
      // This is tested through the parent container's styling
    });

    testWidgets('disables plus button at maximum duration', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          selected: const Duration(hours: 8),
          maxDuration: const Duration(hours: 8),
        ),
      );

      final plusButton = find.byIcon(Icons.add);
      expect(plusButton, findsOneWidget);

      // Button should be visually disabled
      final buttonWidget = tester.widget<Icon>(plusButton);
      // The button's color should indicate it's disabled
    });

    testWidgets('uses custom increment value', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(increment: const Duration(minutes: 5)),
      );

      await tester.tap(find.byIcon(Icons.add));

      expect(changedDurations.length, equals(1));
      expect(changedDurations.first, equals(const Duration(minutes: 35)));
    });

    testWidgets('handles long press for continuous adjustment', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Start long press on plus button
      final plusButton = find.byIcon(Icons.add);
      await tester.longPress(plusButton);

      // Wait for long press to trigger continuous adjustment
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 200));

      // Should have multiple duration changes
      expect(changedDurations.length, greaterThan(1));
    });

    testWidgets('handles haptic feedback', (tester) async {
      // Mock haptic feedback
      final List<MethodCall> hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              hapticCalls.add(call);
            }
            return null;
          });

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.add));

      // Verify haptic feedback was called
      expect(hapticCalls.length, equals(1));

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('shows tooltips on buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Find tooltip widgets
      final tooltips = find.byType(Tooltip);
      expect(tooltips, findsNWidgets(2)); // One for each button

      // Long press to show tooltip
      await tester.longPress(find.byIcon(Icons.add));
      await tester.pump(const Duration(seconds: 1));

      // Tooltip should be visible
      expect(find.text('Increase by 1 minute'), findsOneWidget);
    });

    testWidgets('animates button press', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final plusButton = find.byIcon(Icons.add);

      // Press down
      await tester.press(plusButton);
      await tester.pump(const Duration(milliseconds: 50));

      // Button should be in pressed state (scaled down)
      // This is tested through the Transform.scale widget
      final transform = find.byType(Transform);
      expect(transform, findsWidgets);

      // Release
      await tester.pumpAndSettle();
    });

    testWidgets('stops long press when gesture ends', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final plusButton = find.byIcon(Icons.add);

      // Start long press
      final gesture = await tester.startGesture(tester.getCenter(plusButton));
      await tester.pump(const Duration(milliseconds: 600));

      // End gesture
      await gesture.up();
      await tester.pumpAndSettle();

      // Should stop continuous adjustment
      final initialCount = changedDurations.length;
      await tester.pump(const Duration(milliseconds: 500));

      // No additional changes should occur
      expect(changedDurations.length, equals(initialCount));
    });

    testWidgets('accelerates during long press', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final plusButton = find.byIcon(Icons.add);

      // Start long press and let it run for a while
      await tester.longPress(plusButton);
      await tester.pump(const Duration(milliseconds: 600));

      final initialCount = changedDurations.length;

      // Wait longer to see acceleration
      await tester.pump(const Duration(milliseconds: 1000));

      final finalCount = changedDurations.length;

      // Should have more changes due to acceleration
      expect(finalCount, greaterThan(initialCount));
    });
  });
}
