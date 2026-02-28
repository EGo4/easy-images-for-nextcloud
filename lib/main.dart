import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:workmanager/workmanager.dart';

import 'app_theme.dart';
import 'background.dart';
import 'pages/home_page.dart';
import 'config.dart';
import 'app_locale.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Workmanager for background uploads
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

  // load saved manual locale if present
  final storage = const FlutterSecureStorage();
  final code = await storage.read(key: 'app_locale');
  if (code != null && code.isNotEmpty) {
    appLocale.value = Locale(code);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: Config.appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HomePage(),
    );
  }
}
