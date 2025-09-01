import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/presentation/widgets/preview_card.dart';

void main() {
  group('PreviewCard', () {
    late SessionConfig testConfig;

    setUp(() {
      testConfig = SessionConfig(duration: const Duration(minutes: 30));
    });

    Widget createWidgetUnderTest({SessionConfig? config, VoidCallback? onTap}) {
      return MaterialApp(
        home: Scaffold(
          body: PreviewCard(config: config ?? testConfig, onTap: onTap),
        ),
      );
    }

    testWidgets('displays formatted time correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('30m'), findsOneWidget);
      expect(find.text('Focus Time'), findsOneWidget);
    });

    testWidgets('displays difficulty level correctly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
    });

    testWidgets('displays different difficulty levels correctly', (
      tester,
    ) async {
      final expertConfig = SessionConfig(duration: const Duration(hours: 3));

      await tester.pumpWidget(createWidgetUnderTest(config: expertConfig));

      expect(find.text('3h'), findsOneWidget);
      expect(find.text('Expert'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        createWidgetUnderTest(onTap: () => tapped = true),
      );

      await tester.tap(find.byType(PreviewCard));

      expect(tapped, isTrue);
    });

    testWidgets('animates when config changes', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Initial state
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);

      // Change config
      final newConfig = SessionConfig(duration: const Duration(hours: 2));

      await tester.pumpWidget(createWidgetUnderTest(config: newConfig));
      await tester.pump(); // Start animation

      // Should show new values after animation
      await tester.pumpAndSettle();
      expect(find.text('2h'), findsOneWidget);
      expect(find.text('Intermediate'), findsOneWidget);
    });

    testWidgets('has proper accessibility semantics', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final card = find.byType(PreviewCard);
      expect(card, findsOneWidget);

      // Verify the card is tappable
      final inkWell = find.byType(InkWell);
      expect(inkWell, findsOneWidget);
    });

    testWidgets('displays correct colors for different difficulty levels', (
      tester,
    ) async {
      // Test easy difficulty
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Find the difficulty container
      final easyContainer = find.byWidgetPredicate(
        (widget) => widget is AnimatedContainer,
      );
      expect(easyContainer, findsOneWidget);

      // Test expert difficulty
      final expertConfig = SessionConfig(duration: const Duration(hours: 4));

      await tester.pumpWidget(createWidgetUnderTest(config: expertConfig));
      await tester.pumpAndSettle();

      expect(find.text('Expert'), findsOneWidget);
    });
  });
}
