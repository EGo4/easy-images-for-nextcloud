import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app_locale.dart';
import '../l10n/translations.dart';
import 'package:flutter/widget_previews.dart';

// top-level preview function must be public and statically accessible.
// The previewer uses this annotation to render the widget in VS Code.
@Preview(name: 'Settings Page')
Widget settingsPagePreview() => const SettingsPage();

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pathController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _loading = true;
  String? _selectedLocale;

  static const _keyServer = 'nextcloud_server';
  static const _keyUser = 'nextcloud_user';
  static const _keyPass = 'nextcloud_pass';
  static const _keyPath = 'nextcloud_path';

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  Future<void> _loadValues() async {
    final server = await _storage.read(key: _keyServer) ?? '';
    final user = await _storage.read(key: _keyUser) ?? '';
    final pass = await _storage.read(key: _keyPass) ?? '';
    final path = await _storage.read(key: _keyPath) ?? '/';

    _serverController.text = server;
    _usernameController.text = user;
    _passwordController.text = pass;
    _pathController.text = path;

    final savedLocale = await _storage.read(key: 'app_locale');
    if (savedLocale != null && savedLocale.isNotEmpty) {
      _selectedLocale = savedLocale;
    }

    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _storage.write(key: _keyServer, value: _serverController.text.trim());
    await _storage.write(key: _keyUser, value: _usernameController.text.trim());
    await _storage.write(key: _keyPass, value: _passwordController.text);
    await _storage.write(key: _keyPath, value: _pathController.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t(context, 'settings') + ' saved')));
  }

  Future<void> _saveLanguage(String? lang) async {
    setState(() => _selectedLocale = lang);
    if (_selectedLocale != null) {
      await _storage.write(key: 'app_locale', value: _selectedLocale);
      appLocale.value = Locale(_selectedLocale!);
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t(context, 'settings'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _serverController,
                      decoration: InputDecoration(
                        labelText: t(context, 'nextcloud_server_url'),
                        hintText: 'https://nextcloud.example.com',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: t(context, 'username'),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: t(context, 'password'),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pathController,
                      decoration: InputDecoration(
                        labelText: t(context, 'default_upload_path'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Language'),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                      ],
                      onChanged: (v) => _saveLanguage(v),
                      initialValue: _selectedLocale ?? 'en',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _save,
                      child: Text(t(context, 'save')),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
