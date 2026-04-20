import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/supabase_constants.dart';
import 'core/providers/child_provider.dart';
import 'core/services/auth_service.dart';
import 'core/services/child_service.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/create_child_screen.dart';
import 'features/child/home_screen_shell.dart';
import 'features/admin/admin_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';


final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );

  await NotificationService.initialize();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ChildProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study N Go',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorObservers: [routeObserver],
      home: const AppStartup(),
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

    if (!AuthService.isLoggedIn) {
      _go(const LoginScreen());
      return;
    }

    if (AuthService.isAdmin) {
      _go(const AdminScreen());
      return;
    }

    final children = await ChildService.getChildren();
    if (!mounted) return;

    if (children.isEmpty) {
      _go(const CreateChildScreen(isFirstTime: true));
    } else {
      final provider = context.read<ChildProvider>();
      final lastId = await ChildService.getLastActiveChildId();
      final activeChild = lastId != null
          ? children.firstWhere(
            (c) => c.id == lastId,
        orElse: () => children.first,
      )
          : children.first;
      provider.setActiveChild(activeChild);
      _go(const ChildDashboardScreen());
    }

    if (children.isNotEmpty) {
      await NotificationService.saveToken(children.first.id);
    }
  }

  void _go(Widget screen) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}