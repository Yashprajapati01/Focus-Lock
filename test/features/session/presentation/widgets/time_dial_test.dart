import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/presentation/widgets/time_dial.dart';

void main() {
  group('TimeDial', () {
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
    }) {
      return MaterialApp(
        home: Scaffold(
          body: TimeDial(
            selectedDuration: selected ?? selectedDuration,
            onDurationChanged:
                onDurationChanged ??
                (duration) {
                  changedDurations.add(duration);
                },
            minDuration: minDuration ?? const Duration(minutes: 5),
            maxDuration: maxDuration ?? const Duration(hours: 8),
          ),
        ),
      );
    }

    testWidgets('displays time options correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Should find 30m (which should be visible initially as it's the selected duration)
      expect(find.text('30m'), findsOneWidget);

      // Scroll to find 1h
      await tester.drag(find.byType(Scrollable), const Offset(0, -200));
      await tester.pump();
      expect(find.text('1h'), findsOneWidget);

      // Scroll more to find 2h
      await tester.drag(find.byType(Scrollable), const Offset(0, -400));
      await tester.pump();
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('highlights selected duration', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(hours: 1)),
      );

      // The 1h option should be visible and styled as selected (it should auto-scroll to selected)
      expect(find.text('1h'), findsOneWidget);
    });

    testWidgets('calls onDurationChanged when item is tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Scroll to make 1h visible, then tap it
      await tester.drag(find.byType(Scrollable), const Offset(0, -200));
      await tester.pump();

      await tester.tap(find.text('1h'));
      await tester.pump();

      expect(changedDurations.length, equals(1));
      expect(changedDurations.first, equals(const Duration(hours: 1)));
    });

    testWidgets('scrolls to selected duration on init', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(hours: 2)),
      );

      await tester.pumpAndSettle();

      // The 2h option should be visible (scrolled into view)
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('updates when selectedDuration changes', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(minutes: 15)),
      );

      await tester.pumpAndSettle();
      expect(find.text('15m'), findsOneWidget);

      // Change the selected duration
      await tester.pumpWidget(
        createWidgetUnderTest(selected: const Duration(hours: 1)),
      );

      await tester.pumpAndSettle();
      expect(find.text('1h'), findsOneWidget);
    });

    testWidgets('respects min and max duration constraints', (tester) async {
      await tester.pumpWidget(
        createWidgetUnderTest(
          minDuration: const Duration(minutes: 30),
          maxDuration: const Duration(hours: 2),
        ),
      );

      await tester.pump();

      // Should not find options below 30 minutes (they shouldn't exist in the list)
      expect(find.text('15m'), findsNothing);
      expect(find.text('25m'), findsNothing);

      // Should find 30m (should be visible as it's the minimum)
      expect(find.text('30m'), findsOneWidget);

      // Scroll to find 1h and 2h
      await tester.drag(find.byType(Scrollable), const Offset(0, -200));
      await tester.pump();
      expect(find.text('1h'), findsOneWidget);

      await tester.drag(find.byType(Scrollable), const Offset(0, -400));
      await tester.pump();
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('generates correct time increments', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.pump();

      // Scroll up to see smaller increments
      await tester.drag(find.byType(Scrollable), const Offset(0, 200));
      await tester.pump();

      // Should have 5-minute increments in lower range
      expect(find.text('5m'), findsOneWidget);
      expect(find.text('10m'), findsOneWidget);
      expect(find.text('15m'), findsOneWidget);

      // Scroll down to see larger increments
      await tester.drag(find.byType(Scrollable), const Offset(0, -600));
      await tester.pump();
      expect(find.text('2h'), findsOneWidget);
    });

    testWidgets('formats durations correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.pump();

      // Minutes only (should be visible initially)
      expect(find.text('30m'), findsOneWidget);

      // Scroll to find hours
      await tester.drag(find.byType(Scrollable), const Offset(0, -200));
      await tester.pump();
      expect(find.text('1h'), findsOneWidget);

      await tester.drag(find.byType(Scrollable), const Offset(0, -400));
      await tester.pump();
      expect(find.text('2h'), findsOneWidget);

      // Hours and minutes (should appear in higher ranges)
      // Note: This depends on the specific increments generated
    });

    testWidgets('handles scroll notifications', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.pumpAndSettle();

      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Scroll the list
      await tester.drag(listView, const Offset(0, -100));
      await tester.pumpAndSettle();

      // Should have triggered duration change
      expect(changedDurations.isNotEmpty, isTrue);
    });

    testWidgets('has selection indicator overlay', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.pumpAndSettle();

      // Should have a container that acts as selection indicator
      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // One of them should be the selection indicator
      bool foundSelectionIndicator = false;
      for (int i = 0; i < tester.widgetList(containers).length; i++) {
        final container = tester.widget<Container>(containers.at(i));
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.border != null) {
            foundSelectionIndicator = true;
            break;
          }
        }
      }
      expect(foundSelectionIndicator, isTrue);
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

      // Scroll to make 1h visible, then tap it
      await tester.drag(find.byType(Scrollable), const Offset(0, -200));
      await tester.pump();

      await tester.tap(find.text('1h'));
      await tester.pump();

      // Verify haptic feedback was called
      expect(hapticCalls.length, equals(1));

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('finds closest duration when exact match not found', (
      tester,
    ) async {
      // Test with a duration that's not in the generated options
      await tester.pumpWidget(
        createWidgetUnderTest(
          selected: const Duration(minutes: 37), // Not a 5-minute increment
        ),
      );

      await tester.pumpAndSettle();

      // Should find the closest option (35m or 40m)
      final bool found35 = find.text('35m').evaluate().isNotEmpty;
      final bool found40 = find.text('40m').evaluate().isNotEmpty;

      expect(found35 || found40, isTrue);
    });
  });
}
