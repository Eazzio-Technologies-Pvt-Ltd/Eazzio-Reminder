import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/reminder_provider.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ReminderProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReminderProvider>(context);
    
    return MaterialApp(
      title: 'eazzio reminder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.themeMode,
      home: const SplashScreen(),
    );
  }
}

