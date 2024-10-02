library pictus;

import 'dart:io';

import 'package:pictus/camera/camera.dart';
import 'package:pictus/gallery/custom_gallery_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'photo_edit_tool.dart';

export 'photo_edit_tool.dart';

export 'package:image_picker/image_picker.dart' show XFile, ImageSource;

class Pictus {
  static Future<List<XFile>?> pickImage(
    BuildContext context, {
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int maxNumberOfImages = 1,
    List<PhotoEditTool> tools = const [],
  }) {
    switch (source) {
      case ImageSource.camera:
        if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
          throw Exception('Capture is not supported on this platform');
        }
        return _capture(
          context: context,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          maxNumberOfImages: maxNumberOfImages,
          tools: tools,
        );
      case ImageSource.gallery:
        return _pickAndEdit(
          context,
          maxNumberOfImages: maxNumberOfImages,
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          tools: tools,
        );
    }
  }

  static Future<List<XFile>?> _pickAndEdit(
    BuildContext context, {
    int? maxNumberOfImages,
    int? maxWidth,
    int? maxHeight,
    List<PhotoEditTool> tools = const [],
  }) async {
    final pickedImages = await _pick(
      context,
      maxWidth: tools.isNotEmpty ? null : maxWidth,
      maxHeight: tools.isNotEmpty ? null : maxHeight,
      maxNumberOfImages: maxNumberOfImages,
    );
    if (tools.isEmpty || pickedImages == null || pickedImages.isEmpty) {
      return pickedImages;
    }
    return showGeneralDialog<List<XFile>>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => Material(
        child: CustomGalleryPreview(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          initialImages: pickedImages,
          tools: tools,
        ),
      ),
    );
  }

  static Future<List<XFile>?> _pick(
    BuildContext context, {
    int? maxNumberOfImages,
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      if ((maxNumberOfImages ?? 1) == 1) {
        final file = await ImagePicker().pickImage(source: ImageSource.gallery);
        if (file == null) return null;
        return [file];
      }
      return ImagePicker().pickMultiImage(
        limit: maxNumberOfImages,
        maxHeight: maxHeight?.toDouble(),
        maxWidth: maxWidth?.toDouble(),
      );
    } catch (e) {
      return <XFile>[];
    }
  }

  static Future<List<XFile>?> _capture({
    required BuildContext context,
    int? maxWidth,
    int? maxHeight,
    int maxNumberOfImages = 1,
    List<PhotoEditTool> tools = const [],
  }) {
    return showGeneralDialog<List<XFile>>(
      context: context,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => Material(
        child: Camera(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          maxNumberOfImages: maxNumberOfImages,
          canPop: true,
          tools: tools,
        ),
      ),
    );
  }
}
