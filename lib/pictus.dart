library pictus;

import 'dart:io';

import 'package:mime/mime.dart';
import 'package:pictus/camera/camera.dart';
import 'package:pictus/crop_ratio.dart';
import 'package:pictus/gallery/custom_gallery_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pictus/lens_direction.dart';
import 'photo_edit_tool.dart';

export 'photo_edit_tool.dart';

export 'package:image_picker/image_picker.dart' show XFile, ImageSource;

export 'package:pictus/lens_direction.dart';

export 'package:pictus/crop_ratio.dart';

class Pictus {
  static Future<List<XFile>?> pickImage(
    BuildContext context, {
    required ImageSource source,
    int? maxWidth,
    int? maxHeight,
    int maxNumberOfImages = 1,
    List<PhotoEditTool> availableTools = const [],
    List<PhotoEditTool> forcedOperationsInOrder = const [],
    List<CropRatio> cropRatios = const [],
    LensDirection defaultLensDirection = LensDirection.back,
  }) {
    if (kIsWeb) {
      availableTools.removeWhere((element) => element == PhotoEditTool.draw);
      forcedOperationsInOrder.removeWhere((element) => element == PhotoEditTool.draw);
    }
    switch (source) {
      case ImageSource.camera:
        if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
          throw Exception('Camera is not supported on this platform');
        }
        return _capture(
          context: context,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          maxNumberOfImages: maxNumberOfImages,
          availableTools: availableTools,
          forcedOperationsInOrder: forcedOperationsInOrder,
          cropRatios: cropRatios,
          defaultLensDirection: defaultLensDirection,
        );
      case ImageSource.gallery:
        return _pickAndEdit(
          context,
          maxNumberOfImages: maxNumberOfImages,
          maxHeight: maxHeight,
          maxWidth: maxWidth,
          tools: availableTools,
          forcedOperationsInOrder: forcedOperationsInOrder,
          cropRatios: cropRatios,
        );
    }
  }

  static Future<List<XFile>?> _pickAndEdit(
    BuildContext context, {
    int? maxNumberOfImages,
    int? maxWidth,
    int? maxHeight,
    List<PhotoEditTool> tools = const [],
    List<PhotoEditTool> forcedOperationsInOrder = const [],
    List<CropRatio> cropRatios = const [],
  }) async {
    var pickedImages = await _pick(
      context,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      maxNumberOfImages: maxNumberOfImages,
    );
    pickedImages = pickedImages?.map((image) => XFile(image.path, mimeType: lookupMimeType(image.path))).toList();
    if (tools.isEmpty || pickedImages == null || pickedImages.isEmpty) {
      return pickedImages;
    }
    return showGeneralDialog<List<XFile>>(
      // ignore: use_build_context_synchronously
      context: context,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => Material(
        child: CustomGalleryPreview(
          initialImages: pickedImages!,
          forcedOperationsInOrder: maxNumberOfImages == 1 ? forcedOperationsInOrder : [],
          availableTools: tools,
          cropRatios: cropRatios,
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
    List<PhotoEditTool> availableTools = const [],
    List<PhotoEditTool> forcedOperationsInOrder = const [],
    List<CropRatio> cropRatios = const [],
    LensDirection defaultLensDirection = LensDirection.front,
  }) {
    return showGeneralDialog<List<XFile>>(
      context: context,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) => Material(
        child: Camera(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          maxNumberOfImages: maxNumberOfImages,
          availableTools: availableTools,
          forcedOperationsInOrder: forcedOperationsInOrder,
          cropRatios: cropRatios,
          defaultLensDirection: defaultLensDirection,
        ),
      ),
    );
  }
}
