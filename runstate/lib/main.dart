// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // ProviderScope é o container raiz do Riverpod —
    // todos os providers são disponibilizados a partir daqui
    const ProviderScope(
      child: RunStateApp(),
    ),
  );
}

class RunStateApp extends StatelessWidget {
  const RunStateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunState',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const DashboardScreen(),
    );
  }
}
