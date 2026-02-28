import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'services/webdav_service.dart';

/// Name given to the upload task; Workmanager uses it to identify what to
/// execute in the background callback.
/// Public constant used throughout the app when scheduling the
/// background upload task.  Plugins such as Workmanager require the
/// same string value in both the scheduler and the dispatcher.
const String uploadTaskName = 'backgroundUploadTask';

/// This function is invoked by the Workmanager plugin on a background
/// isolate.  It must be a top-level or static function.
/// Per the workmanager example: https://github.com/fluttercommunity/flutter_workmanager/tree/main/example
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      if (task == uploadTaskName) {
        debugPrint('[background] Starting background upload task');

        final List<dynamic>? paths = inputData?['paths'];
        final String remotePath = inputData?['remotePath'] ?? '/';

        if (paths == null || paths.isEmpty) {
          debugPrint('[background] No paths provided');
          return Future.value(true); // Success; nothing to do
        }

        int successCount = 0;
        int failureCount = 0;

        for (final dynamic raw in paths) {
          try {
            final String path = raw as String;
            final file = File(path);

            if (!await file.exists()) {
              debugPrint('[background] File not found: $path');
              failureCount++;
              continue;
            }

            final bytes = await file.readAsBytes();
            final destination = p.join(remotePath, p.basename(path));

            debugPrint('[background] Uploading $path to $destination');
            await WebDavService().uploadFile(destination, bytes);

            successCount++;
            debugPrint('[background] Successfully uploaded: $path');
          } catch (fileError) {
            failureCount++;
            debugPrint('[background] Failed to upload file: $fileError');
          }
        }

        debugPrint(
          '[background] Upload complete. Success: $successCount, Failed: $failureCount',
        );

        // Return true if all succeeded; false (retry) if some failed
        if (failureCount > 0) {
          debugPrint('[background] Returning false to retry due to failures');
          return Future.value(false); // Workmanager will retry
        }
        return Future.value(true);
      }
    } catch (e) {
      debugPrint('[background] Unexpected error: $e');
      return Future.value(false); // Retry on unexpected exceptions
    }

    debugPrint('[background] Unknown task: $task');
    return Future.value(true);
  });
}
