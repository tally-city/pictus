import 'package:flutter/foundation.dart';
import 'package:pictus/pictus.dart';

class CustomGalleryProvider extends ChangeNotifier {
  CustomGalleryProvider({required List<XFile> initialImages}) : imageFiles = initialImages;

  List<XFile> imageFiles;
  int previewImageIndex = 0;
  bool isProcessing = false;

  void setWithNotify(void Function() callback) {
    callback();
    notifyListeners();
  }

  void setImageAtIndex(int index, XFile editedImage) => setWithNotify(() {
        imageFiles = [...imageFiles];
        imageFiles[index] = editedImage;
      });

  void setPreviewIndex(int index) => setWithNotify(() => previewImageIndex = index);

  void removeImageAtIndex(int index) => setWithNotify(
        () => imageFiles = [...imageFiles]..removeAt(index),
      );
}
