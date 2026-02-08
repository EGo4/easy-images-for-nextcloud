import 'dart:typed_data';
import 'package:webdav_client/webdav_client.dart' as webdav;
import '../config.dart';

class WebDavService {
  late webdav.Client _client;

  WebDavService() {
    String baseUrl = Config.serverUrl;
    // Nextcloud specific path correction
    if (!baseUrl.contains('remote.php/dav/files')) {
      baseUrl = '${Config.serverUrl}/remote.php/dav/files/${Config.username}';
    }

    _client = webdav.newClient(
      baseUrl,
      user: Config.username,
      password: Config.password,
    );
  }

  Future<List<webdav.File>> getFolders(String path) async {
    final list = await _client.readDir(path);
    // Return only directories and sort them
    final folders = list.where((f) => f.isDir ?? false).toList();
    folders.sort((a, b) => (a.name ?? '').compareTo(b.name ?? ''));
    return folders;
  }

  Future<void> uploadFile(String remotePath, Uint8List bytes) async {
    await _client.write(remotePath, bytes);
  }
}
