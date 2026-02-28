import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UploadStatus {
  final String state; // 'pending' or 'completed'
  final int total;
  final int success;
  final int failure;
  final int timestamp; // millisecondsSinceEpoch

  UploadStatus({
    required this.state,
    required this.total,
    required this.success,
    required this.failure,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'state': state,
    'total': total,
    'success': success,
    'failure': failure,
    'timestamp': timestamp,
  };

  static UploadStatus fromJson(Map<String, dynamic> j) => UploadStatus(
    state: j['state'] as String? ?? 'pending',
    total: j['total'] as int? ?? 0,
    success: j['success'] as int? ?? 0,
    failure: j['failure'] as int? ?? 0,
    timestamp: j['timestamp'] as int? ?? 0,
  );

  static Future<String> _statusFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'upload_status.json');
    debugPrint('[upload_status] file path: $path');
    return path;
  }

  static Future<void> markPending(int total) async {
    final path = await _statusFilePath();
    final status = UploadStatus(
      state: 'pending',
      total: total,
      success: 0,
      failure: 0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint('[upload_status] marking pending $total to $path');
    await File(path).writeAsString(jsonEncode(status.toJson()));
  }

  static Future<void> markCompleted(int success, int failure) async {
    final path = await _statusFilePath();
    final status = UploadStatus(
      state: 'completed',
      total: success + failure,
      success: success,
      failure: failure,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    debugPrint(
      '[upload_status] marking completed s=$success f=$failure to $path',
    );
    await File(path).writeAsString(jsonEncode(status.toJson()));
  }

  static Future<UploadStatus?> readStatus() async {
    try {
      final path = await _statusFilePath();
      final file = File(path);
      if (!await file.exists()) return null;
      final txt = await file.readAsString();
      final map = jsonDecode(txt) as Map<String, dynamic>;
      return UploadStatus.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final path = await _statusFilePath();
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
