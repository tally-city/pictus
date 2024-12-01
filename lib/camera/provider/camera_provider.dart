import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraProvider extends ChangeNotifier {
  CameraProvider({
    required int initialCameraIndex,
    required this.cameras,
  }) : cameraIndex = initialCameraIndex;

  List<XFile> imageFiles = [];
  bool takingPicture = false;
  int cameraIndex;
  double baseScaleFactor = 1.0;
  double scaleFactor = 1.0;
  bool isProcessing = false;
  List<CameraDescription> cameras;

  void setWithNotify(void Function() callback) {
    callback();
    notifyListeners();
  }

  void setScaleFactor(double factor) => setWithNotify(() => scaleFactor = factor);

  void setBaseScaleFactor(double factor) => setWithNotify(() => baseScaleFactor = factor);

  void setCameraIndex(int index) => setWithNotify(() => cameraIndex = index);

  void setImageAtIndex(int index, XFile editedImage) => setWithNotify(() {
        imageFiles = [...imageFiles];
        imageFiles[index] = editedImage;
      });

  void removeImageAtIndex(int index) => setWithNotify(
        () => imageFiles = [...imageFiles]..removeAt(index),
      );

  Future<void> handleCapture({
    required Future<XFile> Function() takePicture,
    required Future<XFile?> Function(XFile)? onImageTaken,
  }) async {
    takingPicture = true;
    notifyListeners();

    final takenPicture = await takePicture();

    final bytes = await takenPicture.readAsBytes();

    final newImage = XFile.fromData(
      bytes,
      lastModified: DateTime.now(),
      mimeType: 'image/jpeg',
      length: bytes.length,
      path: takenPicture.path,
    );
    imageFiles = [...imageFiles, newImage];
    takingPicture = false;
    notifyListeners();

    if (onImageTaken != null) {
      final editedImage = await onImageTaken(newImage);
      if (editedImage != null) {
        imageFiles = [...imageFiles];
        imageFiles.removeLast();
        imageFiles = [...imageFiles, editedImage];
      } else {
        imageFiles = [...imageFiles];
        imageFiles.removeLast();
      }
      notifyListeners();
    }
  }

  Future<void> processImages({
    required void Function(List<XFile> modifiedImages) onProcessFinished,
    int? maxWidth,
    int? maxHeight,
  }) async {
    isProcessing = true;
    notifyListeners();

    final modifiedImages = <XFile>[];
    for (final file in imageFiles) {
      if (maxHeight != null || maxWidth != null) {
        var image = img.decodeImage(await file.readAsBytes())!;
        image = img.copyResize(
          image,
          width: image.width > (maxWidth ?? 0) ? maxWidth : image.width,
          height: image.height > (maxHeight ?? 0) ? maxHeight : image.height,
        );
        final newImage = XFile.fromData(
          img.encodeJpg(image),
          mimeType: 'image/jpeg',
        );
        modifiedImages.add(newImage);
      } else {
        modifiedImages.add(file);
      }
    }

    isProcessing = false;
    notifyListeners();

    onProcessFinished(modifiedImages);
  }

  CameraDescription switchCamera() {
    if (cameraIndex < cameras.length - 1) {
      cameraIndex++;
    } else {
      cameraIndex = 0;
    }
    return cameras[cameraIndex];
  }
}
