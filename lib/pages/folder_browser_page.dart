import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../services/webdav_service.dart';

class FolderBrowserPage extends StatefulWidget {
  final ImageSource source;
  const FolderBrowserPage({super.key, required this.source});

  @override
  State<FolderBrowserPage> createState() => _FolderBrowserPageState();
}

class _FolderBrowserPageState extends State<FolderBrowserPage> {
  final _service = WebDavService();
  List<webdav.File> _folders = [];
  String _currentPath = '/';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFolders(_currentPath);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleUpload() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: widget.source);
    if (file == null) return;

    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bytes = await file.readAsBytes();
      final remotePath = p.join(_currentPath, p.basename(file.path));

      await _service.uploadFile(remotePath, bytes);

      if (mounted) {
        Navigator.pop(context); // Close loader
        Navigator.pop(context); // Back to Home
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload Success!')));
      }
    } catch (e) {
      Navigator.pop(context); // Close loader
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath),
        leading: _currentPath == '/'
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _fetchFolders(p.dirname(_currentPath)),
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _folders.length,
              itemBuilder: (ctx, i) => ListTile(
                leading: const Icon(Icons.folder, color: Colors.orange),
                title: Text(_folders[i].name ?? ''),
                onTap: () => _fetchFolders(
                  _folders[i].path ?? '$_currentPath/${_folders[i].name}',
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleUpload,
        label: const Text('Upload Here'),
        icon: const Icon(Icons.cloud_upload),
      ),
    );
  }
}
