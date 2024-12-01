import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pictus/edit/cropper_widget.dart';
import 'package:pictus/edit/forced_operations.dart';
import 'package:pictus/edit/painter_widget.dart';
import 'package:pictus/edit/provider/edit_provider.dart';
import 'package:pictus/pictus.dart';
import 'package:pictus/styles.dart';
import 'package:provider/provider.dart';

class EditPage extends StatefulWidget {
  const EditPage({
    required this.imageBytes,
    required this.isInMultiImageMode,
    required this.isFromGallery,
    this.cropRatios = const [],
    this.editModes = const [],
    this.forcedOperations,
    super.key,
  });

  final Uint8List imageBytes;
  final List<CropRatio> cropRatios;
  final List<PhotoEditTool> editModes;
  final ForcedOperations? forcedOperations;
  final bool isInMultiImageMode;
  final bool isFromGallery;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final GlobalKey<CropperWidgetState> _cropWidget = GlobalKey();
  final GlobalKey<PainterWidgetState> _painterWidget = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProvider(
        initialImage: widget.imageBytes,
        forcedOperations: widget.forcedOperations,
        onForcedOperationFinished: (image) => Navigator.pop(context, image),
      ),
      child: Builder(builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              return;
            }
            if (_canPop(context)) {
              Navigator.pop(context, result);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black87,
              automaticallyImplyLeading: false,
              titleSpacing: 15,
              title: TextButton(
                onPressed: context.select<EditProvider, Status>((value) => value.status) == Status.loading
                    ? null
                    : () {
                        if (_canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                child: context.select<EditProvider, Status>((value) => value.status) == Status.loading
                    ? Container()
                    : Text(widget.isInMultiImageMode || widget.isFromGallery ? 'Cancel' : 'Retake',
                        style: Styles.textButtonStyle),
              ),
              actions: [
                if (context.select<EditProvider, Status>((value) => value.status) != Status.loading)
                  TextButton(
                    onPressed: () => context.read<EditProvider>().onConfirm(
                          onFinishedOperation: (image) => Navigator.pop(context, image),
                          handleCrop: _cropWidget.currentState?.crop,
                          handleDraw: _painterWidget.currentState?.exportImage,
                        ),
                    child: Text(
                      context.select<EditProvider, bool>((provider) => provider.pageMode == PageMode.edit)
                          ? context.select<EditProvider, bool>((provider) => provider.editMode == PhotoEditTool.crop)
                              ? 'Crop'
                              : 'OK'
                          : 'Done',
                      style: Styles.textButtonStyle,
                    ),
                  ),
                const SizedBox(width: 15),
              ],
            ),
            backgroundColor: Colors.black87,
            body: Consumer<EditProvider>(
              builder: (context, provider, child) {
                if (provider.status == Status.loading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                switch (provider.pageMode) {
                  case PageMode.preview:
                    return Center(
                      child: Image.memory(
                        widget.imageBytes,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    );
                  case PageMode.edit:
                    switch (provider.editMode) {
                      case null:
                        return Container();
                      case PhotoEditTool.crop:
                        return CropperWidget(
                          key: _cropWidget, imageBytes: widget.imageBytes, // Use cached bytes
                          cropRatios: widget.cropRatios,
                          onCropped: (croppedImageBytes) => provider.onOperationFinished(
                            croppedImageBytes,
                          ),
                        );
                      case PhotoEditTool.draw:
                        return PainterWidget(
                          key: _painterWidget,
                          imageBytes: widget.imageBytes,
                          onPaintFinished: (paintedImageBytes) => provider.onOperationFinished(
                            paintedImageBytes,
                          ),
                        );
                    }
                }
              },
            ),
            bottomNavigationBar: context.select<EditProvider, PageMode>((value) => value.pageMode) == PageMode.edit
                ? null
                : Container(
                    height: 80,
                    color: Colors.black87,
                    child: _buildTools(context),
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildTools(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.editModes.contains(PhotoEditTool.crop))
          IconButton(
              onPressed: context.select<EditProvider, Status>((value) => value.status) == Status.loading
                  ? null
                  : () => context.read<EditProvider>().switchPageMode(
                        pageMode: PageMode.edit,
                        editMode: PhotoEditTool.crop,
                      ),
              icon: const Icon(
                Icons.crop,
                color: Colors.white,
              )),
        if (!kIsWeb && widget.editModes.contains(PhotoEditTool.draw))
          IconButton(
            onPressed: context.select<EditProvider, Status>((value) => value.status) == Status.loading
                ? null
                : () => context.read<EditProvider>().switchPageMode(
                      pageMode: PageMode.edit,
                      editMode: PhotoEditTool.draw,
                    ),
            icon: const Icon(
              Icons.draw,
              color: Colors.white,
            ),
          )
      ],
    );
  }

  bool _canPop(BuildContext context) {
    final status = context.read<EditProvider>().status;
    final pageMode = context.read<EditProvider>().pageMode;
    if (status == Status.loading) return false;

    if (pageMode == PageMode.edit && widget.forcedOperations == null) {
      context.read<EditProvider>().switchPageMode(pageMode: PageMode.preview, editMode: null);
      return false;
    }

    return true;
  }
}
