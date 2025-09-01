import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:focuslock/features/session/domain/entities/session_config.dart';
import 'package:focuslock/features/session/presentation/bloc/session_bloc.dart';
import 'package:focuslock/features/session/presentation/bloc/session_event.dart';
import 'package:focuslock/features/session/presentation/bloc/session_state.dart'
    as states;
import 'package:focuslock/features/session/presentation/pages/session_screen.dart';
import 'package:focuslock/features/session/presentation/pages/active_session_screen.dart';
import 'package:focuslock/features/session/presentation/widgets/preview_card.dart';
import 'package:focuslock/features/session/presentation/widgets/preset_buttons.dart';
import 'package:focuslock/features/session/presentation/widgets/time_dial.dart';
import 'package:focuslock/features/session/presentation/widgets/fine_controls.dart';
import 'package:focuslock/features/session/presentation/widgets/countdown_overlay.dart';

@GenerateMocks([SessionBloc])
import 'session_screen_test.mocks.dart';

void main() {
  group('SessionScreen', () {
    late MockSessionBloc mockSessionBloc;
    late SessionConfig testConfig;

    setUp(() {
      mockSessionBloc = MockSessionBloc();
      testConfig = const SessionConfig(duration: Duration(minutes: 30));
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<SessionBloc>.value(
          value: mockSessionBloc,
          child: const SessionScreen(),
        ),
        routes: {
          '/profile': (context) => const Scaffold(body: Text('Profile')),
        },
      );
    }

    testWidgets('dispatches SessionInitialized on init', (tester) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      verify(mockSessionBloc.add(const SessionInitialized())).called(1);
    });

    testWidgets('displays configuration screen in configuring state', (
      tester,
    ) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Focus Lock'), findsOneWidget);
      expect(find.byType(PreviewCard), findsOneWidget);
      expect(find.byType(PresetButtons), findsOneWidget);
      expect(find.byType(TimeDial), findsOneWidget);
      expect(find.byType(FineControls), findsOneWidget);
      expect(find.text('Start Focus Session'), findsOneWidget);
    });

    testWidgets('displays active session screen in active state', (
      tester,
    ) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionActive(
          config: testConfig,
          remainingTime: const Duration(minutes: 25),
          startTime: DateTime.now(),
        ),
      );
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(ActiveSessionScreen), findsOneWidget);
      expect(find.byType(PreviewCard), findsNothing);
    });

    testWidgets('displays countdown overlay in countdown state', (
      tester,
    ) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionCountdown(config: testConfig, secondsRemaining: 5),
      );
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CountdownOverlay), findsOneWidget);
      expect(
        find.byType(PreviewCard),
        findsOneWidget,
      ); // Still shows config screen underneath
    });

    testWidgets('displays completion screen in completed state', (
      tester,
    ) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionCompleted(
          config: testConfig,
          completedAt: DateTime.now(),
        ),
      );
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(ActiveSessionScreen), findsOneWidget);
    });

    testWidgets('shows error snackbar in error state', (tester) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionError(config: testConfig, message: 'Test error message'),
      );
      when(mockSessionBloc.stream).thenAnswer(
        (_) => Stream.fromIterable([
          states.SessionError(
            config: testConfig,
            message: 'Test error message',
          ),
        ]),
      );

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Allow snackbar to show

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('navigates to profile when profile button is tapped', (
      tester,
    ) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('dispatches PresetSelected when preset is selected', (
      tester,
    ) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap a preset button
      await tester.tap(find.text('1h'));

      verify(
        mockSessionBloc.add(PresetSelected(const Duration(hours: 1))),
      ).called(1);
    });

    testWidgets('dispatches TimeChanged when time dial changes', (
      tester,
    ) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      // Find the time dial and simulate a change
      final timeDial = find.byType(TimeDial);
      expect(timeDial, findsOneWidget);

      // Simulate tapping on a different time in the dial
      await tester.tap(find.text('45m'));

      verify(
        mockSessionBloc.add(TimeChanged(const Duration(minutes: 45))),
      ).called(1);
    });

    testWidgets('dispatches TimeChanged when fine controls are used', (
      tester,
    ) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the increment button
      await tester.tap(find.byIcon(Icons.add));

      verify(
        mockSessionBloc.add(TimeChanged(const Duration(minutes: 31))),
      ).called(1);
    });

    testWidgets(
      'dispatches SessionStartRequested when start button is tapped',
      (tester) async {
        when(
          mockSessionBloc.state,
        ).thenReturn(states.SessionConfiguring(config: testConfig));
        when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

        await tester.pumpWidget(createWidgetUnderTest());

        await tester.tap(find.text('Start Focus Session'));

        verify(mockSessionBloc.add(const SessionStartRequested())).called(1);
      },
    );

    testWidgets('shows loading state when countdown is active', (tester) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionCountdown(config: testConfig, secondsRemaining: 5),
      );
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Starting...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables start button during countdown', (tester) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionCountdown(config: testConfig, secondsRemaining: 5),
      );
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      final startButton = find.byType(ElevatedButton);
      final buttonWidget = tester.widget<ElevatedButton>(startButton);
      expect(buttonWidget.onPressed, isNull);
    });

    testWidgets('dispatches CountdownCancelled when countdown is cancelled', (
      tester,
    ) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionCountdown(config: testConfig, secondsRemaining: 5),
      );
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      // Find and tap the cancel button in the countdown overlay
      await tester.tap(find.text('Cancel'));

      verify(mockSessionBloc.add(const CountdownCancelled())).called(1);
    });

    testWidgets('dispatches SessionCompleted from active session', (
      tester,
    ) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionActive(
          config: testConfig,
          remainingTime: const Duration(minutes: 25),
          startTime: DateTime.now(),
        ),
      );
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      final activeSession = find.byType(ActiveSessionScreen);
      final activeSessionWidget = tester.widget<ActiveSessionScreen>(
        activeSession,
      );

      // Simulate session completion
      activeSessionWidget.onSessionComplete?.call();

      verify(mockSessionBloc.add(const SessionCompleted())).called(1);
    });

    testWidgets(
      'dispatches SessionCancelled from active session emergency exit',
      (tester) async {
        when(mockSessionBloc.state).thenReturn(
          states.SessionActive(
            config: testConfig,
            remainingTime: const Duration(minutes: 25),
            startTime: DateTime.now(),
          ),
        );
        when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

        await tester.pumpWidget(createWidgetUnderTest());

        final activeSession = find.byType(ActiveSessionScreen);
        final activeSessionWidget = tester.widget<ActiveSessionScreen>(
          activeSession,
        );

        // Simulate emergency exit
        activeSessionWidget.onEmergencyExit?.call();

        verify(mockSessionBloc.add(const SessionCancelled())).called(1);
      },
    );

    testWidgets('dispatches SessionReset from completion screen', (
      tester,
    ) async {
      when(mockSessionBloc.state).thenReturn(
        states.SessionCompleted(
          config: testConfig,
          completedAt: DateTime.now(),
        ),
      );
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      final activeSession = find.byType(ActiveSessionScreen);
      final activeSessionWidget = tester.widget<ActiveSessionScreen>(
        activeSession,
      );

      // Simulate completion acknowledgment
      activeSessionWidget.onSessionComplete?.call();

      verify(mockSessionBloc.add(const SessionReset())).called(1);
    });

    testWidgets('has proper app bar styling', (tester) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      final appBar = find.byType(AppBar);
      final appBarWidget = tester.widget<AppBar>(appBar);

      expect(appBarWidget.title, isA<Text>());
      expect((appBarWidget.title as Text).data, equals('Focus Lock'));
      expect(appBarWidget.backgroundColor, equals(Colors.blue.shade600));
      expect(appBarWidget.foregroundColor, equals(Colors.white));
      expect(appBarWidget.elevation, equals(0));
    });

    testWidgets('has scrollable body', (tester) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('has proper spacing between widgets', (tester) async {
      when(
        mockSessionBloc.state,
      ).thenReturn(states.SessionConfiguring(config: testConfig));
      when(mockSessionBloc.stream).thenAnswer((_) => Stream.empty());

      await tester.pumpWidget(createWidgetUnderTest());

      // Check for SizedBox widgets that provide spacing
      final sizedBoxes = find.byType(SizedBox);
      expect(sizedBoxes, findsWidgets);
    });
  });
}
