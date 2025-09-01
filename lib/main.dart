import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:focuslock/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:focuslock/features/permissions/presentation/screen/permissions_screen.dart';
import 'package:focuslock/features/permissions/presentation/bloc/permission_bloc.dart';
import 'package:focuslock/features/profile/presentation/pages/profile_screen.dart';
import 'package:focuslock/features/session/presentation/bloc/session_bloc.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/session/presentation/pages/session_screen.dart';
import 'firebase_options.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize dependency injection
    await di.init();

    // Run the app
    runApp(const MyApp());
  } catch (error, stackTrace) {
    // Log the error and show a fallback UI
    debugPrint('Failed to initialize app: $error');
    debugPrint('Stack trace: $stackTrace');

    // Run a minimal error app
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
          lazy: false, // Initialize immediately
        ),
        BlocProvider<PermissionBloc>(
          create: (context) => di.sl<PermissionBloc>(),
          lazy: false, // Initialize immediately
        ),
        BlocProvider<SessionBloc>(
          create: (context) => di.sl<SessionBloc>(),
          lazy: false, // Initialize immediately
        ),
      ],
      child: MaterialApp(
        title: 'Focus Lock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        initialRoute: '/',
        onGenerateRoute: _generateRoute,
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/permissions': (context) => const PermissionsScreen(),
          '/home': (context) => const SessionScreen(),
          // '/profile': (context) => const ProfileSheet.show(context),
        },
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Handle dynamic routes or fallback routes
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/permissions':
        return MaterialPageRoute(builder: (_) => const PermissionsScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const SessionScreen());
      // case '/profile':
      //   return MaterialPageRoute(builder: (_) => const ProfileSheet.show(context));
      default:
        // Fallback to splash screen for unknown routes
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Lock - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.red.shade400, Colors.red.shade600],
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'App Initialization Failed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Something went wrong during app startup. Please restart the app.',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
