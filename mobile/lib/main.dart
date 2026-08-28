import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/app_shell.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = await AppController.create();
  runApp(FarReachApp(controller: controller));
  unawaited(controller.initialize());
}

class FarReachApp extends StatelessWidget {
  const FarReachApp({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FarReach',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: ThemeMode.system,
    home: AppShell(controller: controller),
  );
}
