import 'package:flutter/material.dart';
import 'package:pictus/pictus.dart';

class EditProvider extends ChangeNotifier {
  EditProvider({
    required XFile initialImage,
  }) : image = initialImage;

  XFile image;
  Status status = Status.loaded;
  PageMode pageMode = PageMode.preview;
  PhotoEditTool? editMode;

  void switchPageMode({PageMode? pageMode, PhotoEditTool? editMode}) {
    this.pageMode = pageMode ?? this.pageMode;
    this.editMode = editMode;
    notifyListeners();
  }

  void onConfirm({
    required void Function(XFile image) onFinishedOperation,
    required void Function()? handleCrop,
    required void Function()? handleDraw,
  }) {
    switch (pageMode) {
      case PageMode.preview:
        onFinishedOperation(image);
      case PageMode.edit:
        status = Status.loading;
        notifyListeners();
        switch (editMode) {
          case PhotoEditTool.crop:
            handleCrop?.call();

          case PhotoEditTool.draw:
            handleDraw?.call();

          case null:
            return;
        }
    }
  }

  void onOperationFinished(
    XFile? image, {
    void Function(XFile image)? afterFinishedOperation,
  }) {
    if (image == null) return;
    status = Status.loaded;
    pageMode = PageMode.preview;
    this.image = image;
    notifyListeners();
    afterFinishedOperation?.call(image);
  }
}

enum Status {
  loading,
  loaded,
}

enum PageMode {
  preview,
  edit,
}
