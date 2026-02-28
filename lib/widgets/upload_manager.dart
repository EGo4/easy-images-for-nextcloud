import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';

import '../background.dart';
import '../services/webdav_service.dart';

/// Helper responsible for queuing files for background upload and performing an
/// immediate upload so the user can see progress.
///
/// The page that needs upload behaviour simply needs to provide the list of
/// [XFile]s and a callback that will be invoked with each progress update
/// (value between 0.0 and 1.0).  The manager deals with scheduling the
/// Workmanager task and talking to [WebDavService].
class UploadManager {
  final WebDavService _service = WebDavService();

  /// Uploads the given [files] to [remotePath].  Progress is reported via
  /// [onProgress].
  Future<void> queueAndUploadFiles({
    required List<XFile> files,
    required String remotePath,
    required void Function(double progress) onProgress,
  }) async {
    if (files.isEmpty) return;

    // schedule a background task so the work gets retried if the app is killed
    final paths = files.map((f) => f.path).toList();
    await Workmanager().registerOneOffTask(
      'uploadTask-${DateTime.now().millisecondsSinceEpoch}',
      uploadTaskName,
      inputData: {'paths': paths, 'remotePath': remotePath},
      existingWorkPolicy: ExistingWorkPolicy.append,
      backoffPolicy: BackoffPolicy.exponential,
    );

    // also perform an immediate upload so the user sees progress right away
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final bytes = await File(file.path).readAsBytes();
      final destination = p.join(remotePath, p.basename(file.path));

      await _service.uploadFile(destination, bytes);
      onProgress((i + 1) / files.length);
    }
  }
}
