import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:path/path.dart' as path;

// --- CONFIGURATION ---
class Config {
  // Your Nextcloud URL (e.g., https://cloud.example.com)
  static const String serverUrl = 'serverUrl';
  // Your Username
  static const String username = 'username';
  // Your Password (or App Password generated in Nextcloud Security settings)
  static const String password = 'password';
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nextcloud Uploader',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// --- 1. HOME SCREEN (2 Big Buttons) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _navigate(BuildContext context, ImageSource source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FolderBrowserScreen(imageSource: source),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload to Nextcloud')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BigButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              color: Colors.blue.shade100,
              onTap: () => _navigate(context, ImageSource.camera),
            ),
            const SizedBox(height: 20),
            _BigButton(
              icon: Icons.folder,
              label: 'Gallery',
              color: Colors.green.shade100,
              onTap: () => _navigate(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BigButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black12)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.black87),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 2. FOLDER BROWSER SCREEN ---
class FolderBrowserScreen extends StatefulWidget {
  final ImageSource imageSource;

  const FolderBrowserScreen({super.key, required this.imageSource});

  @override
  State<FolderBrowserScreen> createState() => _FolderBrowserScreenState();
}

class _FolderBrowserScreenState extends State<FolderBrowserScreen> {
  late webdav.Client _client;
  // FIXED: Changed FileInfo to File
  List<webdav.File> _files = [];
  String _currentPath = '/';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebDav();
  }

  void _initWebDav() {
    _client = webdav.newClient(
      Config.serverUrl,
      user: Config.username,
      password: Config.password,
      debug: true,
    );

    // Auto-fix URL for Nextcloud if 'remote.php' is missing
    if (!Config.serverUrl.contains('remote.php/dav/files')) {
      _client = webdav.newClient(
        '${Config.serverUrl}/remote.php/dav/files/${Config.username}',
        user: Config.username,
        password: Config.password,
      );
    }

    _loadFolder(_currentPath);
  }

  Future<void> _loadFolder(String path) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // List files
      var list = await _client.readDir(path);
      setState(() {
        _currentPath = path;
        // FIXED: Changed isDirectory to isDir
        _files = list.where((f) => f.isDir ?? false).toList();

        // Sort: A-Z
        _files.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading folder: $e';
      });
    }
  }

  // --- 3. HANDLE IMAGE PICKING & UPLOAD ---
  Future<void> _pickAndUpload() async {
    final ImagePicker picker = ImagePicker();
    XFile? pickedFile;

    try {
      if (widget.imageSource == ImageSource.gallery) {
        pickedFile = await picker.pickImage(source: ImageSource.gallery);
      } else {
        pickedFile = await picker.pickImage(source: ImageSource.camera);
      }

      if (pickedFile == null) return; // User cancelled

      if (mounted) {
        _showUploadDialog(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _showUploadDialog(XFile file) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Construct remote path
      String fileName = path.basename(file.path);
      String remotePath = _currentPath.endsWith('/')
          ? '$_currentPath$fileName'
          : '$_currentPath/$fileName';

      // Read file bytes
      final bytes = await file.readAsBytes();

      // Upload
      await _client.write(remotePath, bytes);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        Navigator.pop(context); // Go back to Home
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload Successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath == '/' ? 'Select Folder' : _currentPath),
        leading: _currentPath != '/'
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  final parent = path.dirname(_currentPath);
                  _loadFolder(parent == '.' ? '/' : parent);
                },
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUpload,
        label: const Text('Use this Folder'),
        icon: const Icon(Icons.check),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final folder = _files[index];
                return ListTile(
                  leading: const Icon(Icons.folder, color: Colors.amber),
                  title: Text(folder.name ?? 'Unknown'),
                  onTap: () {
                    String nextPath =
                        folder.path ?? '$_currentPath/${folder.name}';
                    _loadFolder(nextPath);
                  },
                );
              },
            ),
    );
  }
}
