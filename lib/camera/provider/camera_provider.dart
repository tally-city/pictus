import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CameraProvider extends ChangeNotifier {
  CameraProvider({
    required int initialCameraIndex,
    required this.cameras,
  }) : cameraIndex = initialCameraIndex;

  List<Uint8List> images = [];
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

  void setImageAtIndex(int index, Uint8List editedImage) => setWithNotify(() {
        images = [...images];
        images[index] = editedImage;
      });

  void removeImageAtIndex(int index) => setWithNotify(
        () => images = [...images]..removeAt(index),
      );

  Future<void> handleCapture({
    required Future<XFile> Function() takePicture,
    required Future<Uint8List?> Function(Uint8List)? onImageTaken,
  }) async {
    takingPicture = true;
    notifyListeners();

    final takenPicture = await takePicture();
    var newImageBytes = await takenPicture.readAsBytes();
    images = [...images, newImageBytes];
    takingPicture = false;
    notifyListeners();

    if (onImageTaken != null) {
      final editedImage = await onImageTaken(newImageBytes);
      if (editedImage != null) {
        images = [...images];
        images.removeLast();
        images = [...images, editedImage];
      } else {
        images = [...images];
        images.removeLast();
      }
      notifyListeners();
    }
  }

  Future<void> processImages({
    required void Function(List<Uint8List> modifiedImages) onProcessFinished,
    int? maxWidth,
    int? maxHeight,
  }) async {
    isProcessing = true;
    notifyListeners();

    final modifiedImages = <Uint8List>[];
    for (final imageBytes in images) {
      if (maxHeight != null || maxWidth != null) {
        var image = img.decodeImage(imageBytes)!;
        var newImageBytes = img
            .copyResize(
              image,
              width: image.width > (maxWidth ?? 0) ? maxWidth : image.width,
              height: image.height > (maxHeight ?? 0) ? maxHeight : image.height,
            )
            .toUint8List();
        modifiedImages.add(newImageBytes);
      } else {
        modifiedImages.add(imageBytes);
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
