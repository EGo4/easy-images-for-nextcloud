import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

class WebDavService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  WebDavService();

  Future<_Creds> _readCreds() async {
    final server = await _storage.read(key: 'nextcloud_server');
    final user = await _storage.read(key: 'nextcloud_user');
    final pass = await _storage.read(key: 'nextcloud_pass');

    final cfgServer = (server != null && server.isNotEmpty) ? server : "";
    final cfgUser = (user != null && user.isNotEmpty) ? user : "";
    final cfgPass = pass ?? "";

    String mask(String s) {
      if (s.isEmpty) return '<empty>';
      if (s.length <= 2) return List.filled(s.length, '*').join();
      return '${s[0]}${List.filled(s.length - 2, '*').join()}${s[s.length - 1]}';
    }

    return _Creds(server: cfgServer, user: cfgUser, pass: cfgPass);
  }

  Future<webdav.Client> _createClient() async {
    final c = await _readCreds();
    String baseUrl = c.server;
    if (!baseUrl.contains('remote.php/dav/files')) {
      baseUrl = '${c.server}/remote.php/dav/files/${c.user}';
    }
    return webdav.newClient(baseUrl, user: c.user, password: c.pass);
  }

  Future<List<webdav.File>> getFolders(String path) async {
    final client = await _createClient();
    final list = await client.readDir(path);
    final folders = list.where((f) => f.isDir ?? false).toList();
    folders.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return folders;
  }

  /// Return files (non-directories) in the given remote path.
  Future<List<webdav.File>> getFiles(String path) async {
    final client = await _createClient();
    final list = await client.readDir(path);
    final files = list.where((f) => !(f.isDir ?? false)).toList();
    files.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return files;
  }

  /// Download a remote file and return its bytes.
  Future<Uint8List?> downloadFile(String remotePath) async {
    try {
      final client = await _createClient();
      final data = await client.read(remotePath);
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      return null;
    } catch (e) {
      debugPrint('WebDavService: downloadFile error: $e');
      return null;
    }
  }

  Future<void> uploadFile(String remotePath, Uint8List bytes) async {
    final client = await _createClient();
    await client.write(remotePath, bytes);
  }
}

class _Creds {
  final String server;
  final String user;
  final String pass;
  _Creds({required this.server, required this.user, required this.pass});
}
