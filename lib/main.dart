import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme.dart';
import 'core/supabase_client.dart';
import 'core/notification_service.dart';
import 'services/services.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/couple_setup_screen.dart';
import 'features/tasks/task_list_screen.dart';

/// LifeManager - Invisible magic for life together
/// 
/// A warm, intimate task management app for couples
/// that feels like a caring friend, not a task manager.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  // Initialize notifications
  await NotificationService.initialize();
  
  runApp(const LifeManagerApp());
}

class LifeManagerApp extends StatelessWidget {
  const LifeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeManager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

/// Handles auth state and routing
/// 
/// Routes to:
/// - LoginScreen if not authenticated
/// - CoupleSetupScreen if authenticated but no profile
/// - TaskListScreen if fully set up
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Widget? _destination;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // Listen for auth changes
    _authSubscription = AuthService.onAuthStateChange.listen((state) {
      if (state.event == AuthChangeEvent.signedOut) {
        _navigateTo(const LoginScreen());
      } else if (state.event == AuthChangeEvent.signedIn) {
        _checkAuthState();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthState() async {
    if (!AuthService.isAuthenticated) {
      _navigateTo(const LoginScreen());
      return;
    }
    
    // Check if user has a profile
    final hasProfile = await AuthService.hasProfile();
    debugPrint('hasProfile check: $hasProfile');
    
    if (!hasProfile) {
      // Get display name from auth metadata if available
      final displayName = AuthService.currentUser?.userMetadata?['display_name'] as String?;
      _navigateTo(CoupleSetupScreen(displayName: displayName ?? 'Friend'));
      return;
    }
    
    // Fully authenticated and set up
    _navigateTo(const TaskListScreen());
  }

  void _navigateTo(Widget screen) {
    if (mounted) {
      setState(() {
        _destination = screen;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'LifeManager',
                style: AppTheme.handwritten(
                  fontSize: 48,
                  color: AppTheme.softSage,
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(
                color: AppTheme.softSage,
              ),
            ],
          ),
        ),
      );
    }
    
    return _destination ?? const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
