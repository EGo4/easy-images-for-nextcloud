import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'folder_picker_page.dart'; // Updated import

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nextcloud Uploader'), elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MenuButton(
              icon: Icons.camera_alt_rounded,
              label: 'Camera',
              color: Colors.blue.shade50,
              iconColor: Colors.blue.shade700,
              onTap: () => _nav(context, ImageSource.camera),
            ),
            const SizedBox(height: 24),
            _MenuButton(
              icon: Icons.photo_library_rounded,
              label: 'Gallery',
              color: Colors.green.shade50,
              iconColor: Colors.green.shade700,
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
      MaterialPageRoute(builder: (_) => FolderPickerPage(source: source)),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: iconColor.withOpacity(0.1), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 64, color: iconColor),
              const SizedBox(height: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: iconColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
