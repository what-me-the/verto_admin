import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/viewmodels/auth_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.instance.initialize();

  runApp(const VertoAdminApp());
}

/// Main application widget
class VertoAdminApp extends StatefulWidget {
  const VertoAdminApp({super.key});

  @override
  State<VertoAdminApp> createState() => _VertoAdminAppState();
}

class _VertoAdminAppState extends State<VertoAdminApp> {
  late final AuthViewModel _authViewModel;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authViewModel = AuthViewModel();
    // Initialize AuthViewModel (load preferences, check current user)
    _authViewModel.initialize();

    // Create Router with AuthViewModel dependency
    _appRouter = AppRouter(_authViewModel);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthViewModel>.value(value: _authViewModel),
      ],
      child: MaterialApp.router(
        title: 'Verto Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _appRouter.router,
      ),
    );
  }
}
