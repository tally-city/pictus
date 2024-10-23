import 'package:flutter/material.dart';
import 'package:pictus/edit/forced_operations.dart';
import 'package:pictus/pictus.dart';

class EditProvider extends ChangeNotifier {
  EditProvider({
    required XFile initialImage,
    this.forcedOperations,
    this.onForcedOperationFinished,
  }) : image = initialImage {
    if (forcedOperations != null) {
      forcedOperationStep = 0;
      pageMode = PageMode.edit;
      editMode = forcedOperations!.operationsInOrder[forcedOperationStep!];
    }
  }

  XFile image;
  Status status = Status.loaded;
  PageMode pageMode = PageMode.preview;
  PhotoEditTool? editMode;
  int? forcedOperationStep;
  final ForcedOperations? forcedOperations;
  final void Function(XFile image)? onForcedOperationFinished;

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

  void onOperationFinished(XFile? image) {
    status = Status.loaded;
    if (image != null) {
      this.image = image;
    }

    notifyListeners();
    if (forcedOperations == null || forcedOperationStep == forcedOperations!.operationsInOrder.length - 1) {
      // if we are ate the end of the forced operations, we switch to the preview mode
      pageMode = PageMode.preview;
      if (!(forcedOperations?.showPreviewAfterOperations ?? true)) {
        // if we should skip the preview, we do the on finished operations func (pop the route with latest image)
        onForcedOperationFinished?.call(this.image);
      }
    } else {
      // else we switch to the next operation step
      forcedOperationStep = forcedOperationStep! + 1;
      editMode = forcedOperations!.operationsInOrder[forcedOperationStep!];
    }
    notifyListeners();
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
