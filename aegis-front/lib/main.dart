import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'routes/app_router.dart';
import 'state/app_state.dart';
import 'state/execution_state.dart';
import 'state/history_state.dart';
import 'services/backend_api_service.dart';
import 'services/websocket_service.dart';
import 'services/window_service.dart';
import 'theme/app_theme.dart';

/// Main entry point for the AEGIS RPA Frontend application.
/// 
/// Initializes:
/// - Window manager for desktop window control
/// - Provider state management
/// - Services (API, WebSocket, Storage, Window)
/// - Theme and routing
/// 
/// Validates: Requirements 9.1, 9.2, 13.2
void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize window manager for desktop platforms
  await windowManager.ensureInitialized();

  // Configure window options
  WindowOptions windowOptions = const WindowOptions(
    size: Size(900, 700),
    minimumSize: Size(600, 500),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const AegisApp());
}

/// Root application widget with Provider setup and routing.
class AegisApp extends StatelessWidget {
  const AegisApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services
    final backendApiService = BackendApiService();
    final websocketService = WebSocketService();
    final windowService = WindowService();

    return MultiProvider(
      providers: [
        // Services
        Provider<BackendApiService>.value(value: backendApiService),
        Provider<WebSocketService>.value(value: websocketService),
        Provider<WindowService>.value(value: windowService),

        // State notifiers
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(),
        ),
        ChangeNotifierProvider<ExecutionStateNotifier>(
          create: (context) => ExecutionStateNotifier(
            apiService: backendApiService,
            wsService: websocketService,
            windowService: windowService,
          ),
        ),
        ChangeNotifierProvider<HistoryStateNotifier>(
          create: (context) => HistoryStateNotifier(
            apiService: backendApiService,
          ),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AEGIS RPA Frontend',
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.system,
        initialRoute: AppRouter.onboarding,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
