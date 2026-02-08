import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/webdav_service.dart';
import 'upload_selection_page.dart';
import '../l10n/translations.dart';

class FolderPickerPage extends StatefulWidget {
  final ImageSource source;
  const FolderPickerPage({super.key, required this.source});

  @override
  State<FolderPickerPage> createState() => _FolderPickerPageState();
}

class _FolderPickerPageState extends State<FolderPickerPage> {
  final _service = WebDavService();
  List<webdav.File> _folders = [];
  String _currentPath = "/";
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    try {
      // Load saved default upload path from secure storage if present
      final saved = await _storage.read(key: 'nextcloud_path');
      if (saved != null && saved.isNotEmpty) {
        _currentPath = saved;
      }
      await _fetchFolders(_currentPath);
    } catch (e) {
      // If the default path doesn't exist/fails, start at root
      await _fetchFolders('/');
    }
  }

  Future<void> _fetchFolders(String path) async {
    setState(() => _isLoading = true);
    try {
      final folders = await _service.getFolders(path);
      setState(() {
        _folders = folders;
        _currentPath = path;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading folders: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Fixed: AppBar doesn't have a 'subtitle' property.
        // We use a Column inside the title instead.
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              p.basename(_currentPath).isEmpty
                  ? t(context, 'nextcloud')
                  : p.basename(_currentPath),
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              _currentPath,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _folders.length + (_currentPath == '/' ? 0 : 1),
              itemBuilder: (ctx, i) {
                // Logic for the 'Back' button (..)
                if (_currentPath != '/' && i == 0) {
                  return ListTile(
                    leading: const Icon(Icons.arrow_upward, color: Colors.blue),
                    title: const Text(".."),
                    onTap: () => _fetchFolders(p.dirname(_currentPath)),
                  );
                }

                final folder = _folders[_currentPath == '/' ? i : i - 1];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.amber),
                  title: Text(folder.name ?? ''),
                  onTap: () => _fetchFolders(
                    folder.path ?? p.join(_currentPath, folder.name),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UploadSelectionPage(
                remotePath: _currentPath,
                source: widget.source,
              ),
            ),
          );
        },
        label: Text(t(context, 'select_folder')),
        icon: const Icon(Icons.check_circle),
      ),
    );
  }
}
