import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import '../services/webdav_service.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../l10n/translations.dart';

class ViewerPage extends StatefulWidget {
  const ViewerPage({super.key});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  final _service = WebDavService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  List<webdav.File> _folders = [];
  List<webdav.File> _files = [];
  String _currentPath = '/';
  bool _loading = true;
  bool _foldersHidden = false;

  @override
  void initState() {
    super.initState();
    _initPathAndLoad();
  }

  Future<void> _initPathAndLoad() async {
    final saved = await _storage.read(key: 'nextcloud_path');
    if (saved != null && saved.isNotEmpty) {
      _currentPath = saved;
    }
    await _refresh(_currentPath);
  }

  Future<void> _refresh(String path) async {
    setState(() => _loading = true);
    try {
      final folders = await _service.getFolders(path);
      final files = await _service.getFiles(path);
      final images = files.where((f) {
        final n = (f.name ?? '').toLowerCase();
        return n.endsWith('.jpg') ||
            n.endsWith('.jpeg') ||
            n.endsWith('.png') ||
            n.endsWith('.gif') ||
            n.endsWith('.webp');
      }).toList();

      setState(() {
        _folders = folders;
        _files = images;
        _currentPath = path;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _openFolder(String path) async => _refresh(path);

  Future<void> _goUp() async {
    if (_currentPath == '/' || _currentPath.isEmpty) return;
    final parent = p.dirname(_currentPath);
    await _refresh(parent);
  }

  void _showImage(String remotePath) async {
    final bytes = await _service.downloadFile(remotePath);
    if (bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to download')));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewer(bytes: bytes, title: remotePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t(context, 'nextcloud')),
            Text(
              _currentPath,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          if (_currentPath != '/')
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              tooltip: 'Up',
              onPressed: _goUp,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                final folderHeight = _foldersHidden
                    ? 0.0
                    : (availableHeight * 0.5);
                return Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: folderHeight,
                      child: Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: _folders.isEmpty
                            ? Center(child: Text(t(context, 'no_folders')))
                            : ListView.builder(
                                itemCount:
                                    _folders.length +
                                    (_currentPath != '/' ? 1 : 0),
                                itemBuilder: (ctx, i) {
                                  if (_currentPath != '/' && i == 0) {
                                    return ListTile(
                                      leading: const Icon(
                                        Icons.arrow_upward,
                                        color: Colors.blue,
                                      ),
                                      title: const Text('..'),
                                      onTap: _goUp,
                                    );
                                  }
                                  final idx = (_currentPath != '/' ? i - 1 : i);
                                  final f = _folders[idx];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.folder,
                                      color: Colors.amber,
                                    ),
                                    title: Text(f.name ?? ''),
                                    onTap: () => _openFolder(
                                      f.path ??
                                          p.join(_currentPath, f.name ?? ''),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),

                    // Toggle arrow
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: IconButton(
                          icon: Icon(
                            _foldersHidden
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                          ),
                          onPressed: () =>
                              setState(() => _foldersHidden = !_foldersHidden),
                        ),
                      ),
                    ),

                    // Images pane takes remaining space
                    Expanded(
                      child: _files.isEmpty
                          ? Center(
                              child: Text(t(context, 'no_images_selected')),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(8),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: _files.length,
                              itemBuilder: (ctx, i) {
                                final file = _files[i];
                                final remote =
                                    file.path ??
                                    p.join(_currentPath, file.name ?? '');
                                return GestureDetector(
                                  onTap: () => _showImage(remote),
                                  child: FutureBuilder<Uint8List?>(
                                    future: _service.downloadFile(remote),
                                    builder: (c, s) {
                                      final bytes = s.data;
                                      if (bytes == null)
                                        return Container(
                                          color: Colors.grey[300],
                                        );
                                      return Image.memory(
                                        bytes,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class ImageViewer extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  const ImageViewer({super.key, required this.bytes, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: InteractiveViewer(child: Image.memory(bytes))),
    );
  }
}
