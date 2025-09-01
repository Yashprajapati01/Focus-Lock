import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/presentation/widgets/countdown_overlay.dart';

void main() {
  group('CountdownOverlay', () {
    late bool cancelCalled;
    late bool countdownCompleteCalled;

    setUp(() {
      cancelCalled = false;
      countdownCompleteCalled = false;
    });

    Widget createWidgetUnderTest({
      int secondsRemaining = 5,
      VoidCallback? onCancel,
      VoidCallback? onCountdownComplete,
    }) {
      return MaterialApp(
        home: CountdownOverlay(
          secondsRemaining: secondsRemaining,
          onCancel: onCancel ?? () => cancelCalled = true,
          onCountdownComplete:
              onCountdownComplete ?? () => countdownCompleteCalled = true,
        ),
      );
    }

    testWidgets('displays countdown number correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 7));

      expect(find.text('7'), findsOneWidget);
      expect(find.text('seconds'), findsOneWidget);
    });

    testWidgets('displays singular second for 1', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 1));

      expect(find.text('1'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('displays zen mode message', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Zen mode starting soon'), findsOneWidget);
    });

    testWidgets('displays motivational message', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Should find one of the motivational messages
      final motivationalMessages = [
        'Take a deep breath and prepare to focus',
        'Your future self will thank you for this',
        'Great things happen when you eliminate distractions',
        'This is your time to achieve something meaningful',
        'Focus is a superpower in a distracted world',
      ];

      bool foundMessage = false;
      for (final message in motivationalMessages) {
        if (find.text(message).evaluate().isNotEmpty) {
          foundMessage = true;
          break;
        }
      }
      expect(foundMessage, isTrue);
    });

    testWidgets('displays cancel button', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('calls onCancel when cancel button is pressed', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelCalled, isTrue);
    });

    testWidgets('calls onCountdownComplete when countdown reaches 0', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 1));

      // Update to 0
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 0));

      expect(countdownCompleteCalled, isTrue);
    });

    testWidgets('animates countdown number changes', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 5));

      expect(find.text('5'), findsOneWidget);

      // Change countdown
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 4));
      await tester.pump(); // Start animation

      // Should show new number after animation
      await tester.pumpAndSettle();
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('shows progress circle', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 5));

      final progressIndicator = find.byType(CircularProgressIndicator);
      expect(progressIndicator, findsOneWidget);

      final progressWidget = tester.widget<CircularProgressIndicator>(
        progressIndicator,
      );
      expect(progressWidget.value, equals(0.5)); // (10 - 5) / 10
    });

    testWidgets('updates progress circle correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 8));

      final progressIndicator = find.byType(CircularProgressIndicator);
      final progressWidget = tester.widget<CircularProgressIndicator>(
        progressIndicator,
      );
      expect(progressWidget.value, equals(0.2)); // (10 - 8) / 10
    });

    testWidgets('has dark overlay background', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final containers = find.byType(Container);
      expect(containers, findsWidgets);

      // Find the main overlay container
      bool foundOverlayContainer = false;
      for (int i = 0; i < tester.widgetList(containers).length; i++) {
        final container = tester.widget<Container>(containers.at(i));
        if (container.color != null && container.color!.alpha > 200) {
          foundOverlayContainer = true;
          break;
        }
      }
      expect(foundOverlayContainer, isTrue);
    });

    testWidgets('animates entrance', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Should have opacity animation
      final opacity = find.byType(Opacity);
      expect(opacity, findsOneWidget);

      // Should have scale animation
      final transform = find.byType(Transform);
      expect(transform, findsWidgets);
    });

    testWidgets('handles haptic feedback on countdown changes', (tester) async {
      // Mock haptic feedback
      final List<MethodCall> hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              hapticCalls.add(call);
            }
            return null;
          });

      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 5));

      // Change countdown to trigger haptic
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 4));

      // Verify haptic feedback was called
      expect(hapticCalls.length, equals(1));

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('does not trigger haptic when countdown reaches 0', (
      tester,
    ) async {
      // Mock haptic feedback
      final List<MethodCall> hapticCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              hapticCalls.add(call);
            }
            return null;
          });

      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 1));

      // Change countdown to 0
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 0));

      // Should not trigger haptic for 0
      expect(hapticCalls.isEmpty, isTrue);

      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('animates cancel button press', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final cancelButton = find.text('Cancel');

      // Press down
      await tester.press(cancelButton);
      await tester.pump(const Duration(milliseconds: 50));

      // Button should be in pressed state (scaled down)
      final transform = find.byType(Transform);
      expect(transform, findsWidgets);

      // Release
      await tester.pumpAndSettle();
    });

    testWidgets('shows consistent motivational message for same countdown', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 3));

      // Get the displayed message
      final motivationalMessages = [
        'Take a deep breath and prepare to focus',
        'Your future self will thank you for this',
        'Great things happen when you eliminate distractions',
        'This is your time to achieve something meaningful',
        'Focus is a superpower in a distracted world',
      ];

      String? displayedMessage;
      for (final message in motivationalMessages) {
        if (find.text(message).evaluate().isNotEmpty) {
          displayedMessage = message;
          break;
        }
      }

      expect(displayedMessage, isNotNull);

      // Rebuild with same countdown - should show same message
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 3));
      expect(find.text(displayedMessage!), findsOneWidget);
    });

    testWidgets('has proper safe area', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final safeArea = find.byType(SafeArea);
      expect(safeArea, findsOneWidget);
    });

    testWidgets('uses AnimatedSwitcher for countdown number', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(secondsRemaining: 5));

      final animatedSwitcher = find.byType(AnimatedSwitcher);
      expect(animatedSwitcher, findsOneWidget);

      final switcherWidget = tester.widget<AnimatedSwitcher>(animatedSwitcher);
      expect(
        switcherWidget.duration,
        equals(const Duration(milliseconds: 300)),
      );
    });
  });
}
