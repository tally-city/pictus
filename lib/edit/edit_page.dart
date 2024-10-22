import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pictus/crop_ratio.dart';
import 'package:pictus/edit/cropper_widget.dart';
import 'package:pictus/edit/painter_widget.dart';
import 'package:pictus/edit/provider/edit_provider.dart';
import 'package:pictus/pictus.dart';
import 'package:provider/provider.dart';

class EditPage extends StatefulWidget {
  const EditPage({
    required this.image,
    this.cropRatios = const [],
    this.editModes = const [],
    this.forcedOperationsInOrder = const [],
    this.showPreviewAfterOperations = false,
    super.key,
  });
  final XFile image;
  final List<CropRatio> cropRatios;
  final List<PhotoEditTool> editModes;
  final List<PhotoEditTool> forcedOperationsInOrder;
  final bool showPreviewAfterOperations;

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
        initialImage: widget.image,
      ),
      child: Builder(builder: (context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            final status = context.read<EditProvider>().status;
            final pageMode = context.read<EditProvider>().pageMode;
            if (didPop) {
              return;
            }
            if (status == Status.loading) return;

            if (pageMode == PageMode.edit) {
              context.read<EditProvider>().switchPageMode(pageMode: PageMode.preview, editMode: null);
              return;
            }

            Navigator.pop(context, result);
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.black87,
              leading: TextButton(
                onPressed: context.select<EditProvider, Status>((value) => value.status) == Status.loading
                    ? null
                    : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              leadingWidth: 100,
              actions: [
                TextButton(
                  onPressed: () => context.read<EditProvider>().onConfirm(
                        onFinishedOperation: (image) => Navigator.pop(context, image),
                        handleCrop: _cropWidget.currentState?.crop,
                        handleDraw: _painterWidget.currentState?.exportImage,
                      ),
                  child: Text(
                    context.select<EditProvider, bool>(
                            (provider) => provider.pageMode == PageMode.edit && provider.editMode == PhotoEditTool.crop)
                        ? 'Crop'
                        : 'Done',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
            backgroundColor: Colors.black87,
            // extendBodyBehindAppBar: true,
            body: Consumer<EditProvider>(
              builder: (context, provider, child) => FutureBuilder(
                future: provider.image.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      switch (provider.pageMode) {
                        case PageMode.preview:
                          return Center(
                            child: Image.memory(
                              snapshot.data!,
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
                                key: _cropWidget,
                                bytes: snapshot.data!,
                                cropRatios: widget.cropRatios,
                                onCropped: (croppedImage) => provider.onOperationFinished(
                                  croppedImage,
                                  afterFinishedOperation: (image) => Navigator.pop(context, image),
                                ),
                              );
                            case PhotoEditTool.draw:
                              return PainterWidget(
                                key: _painterWidget,
                                bytes: snapshot.data!,
                                onPaintFinished: (paintedImage) => provider.onOperationFinished(
                                  paintedImage,
                                  afterFinishedOperation: (image) => Navigator.pop(context, image),
                                ),
                              );
                          }
                      }
                    }
                    return const Center(child: Text('Failed to load image'));
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
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

  Future<bool?> _showDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Any unsaved changes will be lost!'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes, discard my changes'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: const Text('No, continue editing'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }
}
