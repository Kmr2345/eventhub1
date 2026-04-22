import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eventhub/data/app_state.dart';
import 'package:eventhub/screens/auth_screen.dart';
import 'package:eventhub/screens/main_screen.dart';
import 'package:eventhub/theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const EventHubApp(),
    ),
  );
}

class EventHubApp extends StatelessWidget {
  const EventHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventHub',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      supportedLocales: const [
        Locale('ru'),
        Locale('kk'),
        Locale('en'),
      ],
      home: Consumer<AppState>(
        builder: (_, state, __) =>
        state.user == null ? const AuthScreen() : const MainScreen(),
      ),
    );
  }
}