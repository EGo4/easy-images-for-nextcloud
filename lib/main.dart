import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'pages/home_page.dart';
import 'config.dart';
import 'app_locale.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}
