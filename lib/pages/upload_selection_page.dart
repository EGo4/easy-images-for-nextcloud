import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/widget_previews.dart';

import '../l10n/translations.dart';
import '../widgets/upload_manager.dart';
import '../widgets/image_viewer.dart';
import '../services/upload_status.dart';

@Preview(name: 'Upload Selection Page')
Widget uploadSelectionPagePreview() =>
    const UploadSelectionPage(remotePath: "/", source: ImageSource.gallery);

class UploadSelectionPage extends StatefulWidget {
  final String remotePath;
  final ImageSource source;

  const UploadSelectionPage({
    super.key,
    required this.remotePath,
    required this.source,
  });

  @override
  State<UploadSelectionPage> createState() => _UploadSelectionPageState();
}

class _UploadSelectionPageState extends State<UploadSelectionPage> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0;

  @override
  void initState() {
    super.initState();
    _pickInitialFiles();
    // Check immediately in case app was killed during a background upload
    // and was restarted.
    _checkUploadStatusAndNavigate();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkUploadStatusAndNavigate() async {
    try {
      final status = await UploadStatus.readStatus();
      debugPrint('UploadSelectionPage read status: $status');
      if (status == null) return;

      if (status.state == 'completed' && mounted) {
        final message =
            'Background upload finished. Success: ${status.success}, Failed: ${status.failure}';
        await _finishUpload(message);
      }
    } catch (e) {
      debugPrint('UploadSelectionPage error reading status: $e');
    }
  }

  Future<void> _finishUpload(String message) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    await UploadStatus.clear();
    if (mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _pickInitialFiles() async {
    if (widget.source == ImageSource.gallery) {
      final List<XFile> images = await _picker.pickMultiImage();
      setState(() => _selectedFiles = images);
    } else {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) setState(() => _selectedFiles = [image]);
    }
  }

  Future<void> _pickAdditionalFiles() async {
    if (widget.source == ImageSource.gallery) {
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() => _selectedFiles.addAll(images));
      }
    } else {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) setState(() => _selectedFiles.add(image));
    }
  }

  Future<void> _startUpload() async {
    if (_selectedFiles.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      await UploadManager().queueAndUploadFiles(
        files: _selectedFiles,
        remotePath: widget.remotePath,
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (mounted) {
        setState(() => _isUploading = false);
        await _finishUpload('Upload completed successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t(context, 'confirm_upload')),
        actions: [
          IconButton(
            tooltip: 'Select more',
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: _pickAdditionalFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${t(context, 'destination')} ${widget.remotePath}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (_isUploading) ...[
            LinearProgressIndicator(value: _uploadProgress),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                t(
                  context,
                  'uploading_percent',
                  args: {'pct': '${(_uploadProgress * 100).toInt()}'},
                ),
              ),
            ),
          ],
          Expanded(
            child: _selectedFiles.isEmpty
                ? Center(child: Text(t(context, 'no_images_selected')))
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _selectedFiles.length,
                    itemBuilder: (ctx, i) {
                      final file = File(_selectedFiles[i].path);
                      return GestureDetector(
                        onTap: () => showImagePreview(context, file),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(file, fit: BoxFit.cover),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedFiles.removeAt(i);
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _isUploading || _selectedFiles.isEmpty
                ? null
                : _startUpload,
            icon: const Icon(Icons.cloud_upload),
            label: Text(
              t(
                context,
                'upload_files',
                args: {'count': '${_selectedFiles.length}'},
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
      ),
    );
  }
}
