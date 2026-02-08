import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
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
      appBar: AppBar(title: const Text('Settings')),
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
                      decoration: const InputDecoration(
                        labelText: 'Nextcloud server URL',
                        hintText: 'https://nextcloud.example.com',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pathController,
                      decoration: const InputDecoration(
                        labelText: 'Default upload path',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(onPressed: _save, child: const Text('Save')),
                  ],
                ),
              ),
            ),
    );
  }
}
