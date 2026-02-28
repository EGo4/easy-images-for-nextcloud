import 'dart:io';

import 'package:flutter/material.dart';

/// Displays a full‑screen preview of the supplied [file].  The caller need only
/// provide a [BuildContext] and the [File] to show.
Future<void> showImagePreview(BuildContext context, File file) {
  final size = MediaQuery.of(context).size;
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            SizedBox(
              width: size.width,
              height: size.height,
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(child: Image.file(file, fit: BoxFit.contain)),
              ),
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      );
    },
  );
}
