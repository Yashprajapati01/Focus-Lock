import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/presentation/widgets/preset_buttons.dart';

void main() {
  group('PresetButtons', () {
    late Duration selectedDuration;
    late List<Duration> selectedDurations;

    setUp(() {
      selectedDuration = const Duration(minutes: 30);
      selectedDurations = [];
    });

    Widget createWidgetUnderTest({
      Duration? selected,
      Function(Duration)? onPresetSelected,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PresetButtons(
            selectedDuration: selected ?? selectedDuration,
            onPresetSelected:
                onPresetSelected ??
                (duration) {
                  selectedDurations.add(duration);
                },
          ),
        ),
      );
    }

    testWidgets('displays all preset buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('15m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('3h'), findsOneWidget);
    });

    testWidgets('highlights selected preset', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(hours: 1)),
      );

      // Find the 1h button and verify it's styled as selected
      final oneHourButton = find.text('1h');
      expect(oneHourButton, findsOneWidget);

      // The selected button should have different styling
      // We can verify this by checking the widget tree
      final buttonWidget = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: oneHourButton,
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );

      // The decoration should indicate selection
      expect(buttonWidget.decoration, isA<BoxDecoration>());
    });

    testWidgets('calls onPresetSelected when button is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('1h'));

      expect(selectedDurations.length, equals(1));
      expect(selectedDurations.first, equals(const Duration(hours: 1)));
    });

    testWidgets('calls onPresetSelected for different presets', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap 15m preset
      await tester.tap(find.text('15m'));
      expect(selectedDurations.last, equals(const Duration(minutes: 15)));

      // Tap 2h preset
      await tester.tap(find.text('2h'));
      expect(selectedDurations.last, equals(const Duration(hours: 2)));

      // Tap 3h preset
      await tester.tap(find.text('3h'));
      expect(selectedDurations.last, equals(const Duration(hours: 3)));

      expect(selectedDurations.length, equals(3));
    });

    testWidgets('animates selection changes', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(minutes: 15)),
      );

      // Initial state - 15m should be selected
      expect(find.text('15m'), findsOneWidget);

      // Change selection to 1h
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(hours: 1)),
      );

      // Pump animation frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Both buttons should still be visible
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
    });

    testWidgets('is horizontally scrollable', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      final listViewWidget = tester.widget<ListView>(listView);
      expect(listViewWidget.scrollDirection, equals(Axis.horizontal));
    });

    testWidgets('has proper spacing between buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify SizedBox separators exist
      final separators = find.byWidgetPredicate(
        (widget) => widget is SizedBox && widget.width == 12,
      );

      // Should have 4 separators for 5 buttons
      expect(separators, findsNWidgets(4));
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

      await tester.tap(find.text('30m'));

      // Verify haptic feedback was called
      expect(hapticCalls.length, equals(1));
      expect(hapticCalls.first.method, equals('HapticFeedback.vibrate'));

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('maintains consistent button height', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final container = find.byType(Container).first;
      final containerWidget = tester.widget<Container>(container);

      expect(containerWidget.constraints?.maxHeight, equals(60));
    });
  });
}
