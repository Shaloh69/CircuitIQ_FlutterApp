import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
import 'services/websocket_service.dart';
import 'providers/device_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(CircuitIQApp(prefs: prefs));
}

class CircuitIQApp extends StatelessWidget {
  final SharedPreferences prefs;

  const CircuitIQApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth Provider - manages authentication state
        ChangeNotifierProvider(
          create: (_) => AuthProvider(prefs),
        ),
        
        // API Service - depends on AuthProvider for token management
        ChangeNotifierProxyProvider<AuthProvider, ApiService>(
          create: (_) => ApiService(prefs),
          update: (_, auth, previous) => previous ?? ApiService(prefs),
        ),
        
        // WebSocket Service - manages real-time connections
        ChangeNotifierProxyProvider<ApiService, WebSocketService>(
          create: (_) => WebSocketService(),
          update: (_, api, previous) {
            if (previous == null) {
              return WebSocketService();
            }
            return previous;
          },
        ),
        
        // Device Provider - manages device state with WebSocket and API
        ChangeNotifierProxyProvider2<WebSocketService, ApiService, DeviceProvider>(
          create: (context) {
            final ws = context.read<WebSocketService>();
            final api = context.read<ApiService>();
            return DeviceProvider(ws, api);
          },
          update: (_, ws, api, previous) {
            if (previous == null) {
              return DeviceProvider(ws, api);
            }
            previous.updateServices(ws, api);
            return previous;
          },
        ),
      ],
      child: MaterialApp(
        title: 'CircuitIQ',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}