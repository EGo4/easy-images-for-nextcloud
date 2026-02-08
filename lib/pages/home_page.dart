import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'folder_browser_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nextcloud Uploader')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MenuButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              color: Colors.blue.shade100,
              onTap: () => _nav(context, ImageSource.camera),
            ),
            const SizedBox(height: 20),
            _MenuButton(
              icon: Icons.photo_library,
              label: 'Gallery',
              color: Colors.green.shade100,
              onTap: () => _nav(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, ImageSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FolderBrowserPage(source: source)),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
