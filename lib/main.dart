import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/supabase_constants.dart';
import 'core/providers/child_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/child_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/create_child_screen.dart';
import 'features/auth/screens/child_dashboard_screen.dart';
import 'features/admin/screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChildProvider(),
      child: MaterialApp(
        title: 'Kids Study App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const AppStartup(),
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    // Not logged in → go to login
    if (!AuthService.isLoggedIn) {
      _go(const LoginScreen());
      return;
    }

    // Admin → go to admin dashboard
    if (AuthService.isAdmin) {
      _go(const AdminScreen());
      return;
    }

    // Parent → check if they have any children
    final children = await ChildService.getChildren();
    if (!mounted) return;

    if (children.isEmpty) {
      // First time — no children yet
      _go(const CreateChildScreen(isFirstTime: true));
    } else {
      // Returning — load last child automatically
      final provider = context.read<ChildProvider>();
      provider.setActiveChild(children.first);
      _go(const ChildDashboardScreen());
    }
  }

  void _go(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}