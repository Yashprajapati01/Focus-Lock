import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuslock/features/session/presentation/widgets/time_dial.dart';

void main() {
  testWidgets('Debug TimeDial - see what text is rendered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeDial(
            selectedDuration: const Duration(minutes: 30),
            onDurationChanged: (duration) {},
            minDuration: const Duration(minutes: 5),
            maxDuration: const Duration(hours: 8),
          ),
        ),
      ),
    );

    // Print all Text widgets found initially
    final textWidgets = find.byType(Text);
    print('Initially found ${textWidgets.evaluate().length} Text widgets:');

    for (final element in textWidgets.evaluate()) {
      final textWidget = element.widget as Text;
      print('Text: "${textWidget.data}"');
    }

    // Try scrolling down to see more options
    final scrollable = find.byType(Scrollable);
    if (scrollable.evaluate().isNotEmpty) {
      await tester.drag(scrollable, const Offset(0, -200)); // Scroll down
      await tester.pump();

      print('\nAfter scrolling down:');
      final textWidgetsAfterScroll = find.byType(Text);
      print('Found ${textWidgetsAfterScroll.evaluate().length} Text widgets:');

      for (final element in textWidgetsAfterScroll.evaluate()) {
        final textWidget = element.widget as Text;
        print('Text: "${textWidget.data}"');
      }
    }

    // Check for "1h" after scrolling
    final oneHourWidgets = find.text('1h');
    print('\nFound ${oneHourWidgets.evaluate().length} widgets with "1h"');

    // Check for "60m" (which should be equivalent to 1h)
    final sixtyMinWidgets = find.text('60m');
    print('Found ${sixtyMinWidgets.evaluate().length} widgets with "60m"');
  });
}
