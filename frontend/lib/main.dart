import 'package:flutter/material.dart';
import 'router/app_router.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init(); // restore JWT from SharedPreferences
  runApp(const CodeSpotlightApp());
}

class CodeSpotlightApp extends StatelessWidget {
  const CodeSpotlightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CodeSpotlight',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
