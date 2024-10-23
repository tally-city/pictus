library pictus;

import 'dart:developer';

import 'package:pictus/camera/provider/camera_provider.dart';
import 'package:pictus/crop_ratio.dart';
import 'package:pictus/edit/forced_operations.dart';
import 'package:pictus/photo_edit_tool.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pictus/edit/edit_page.dart';
import 'package:pictus/styles.dart';
import 'package:provider/provider.dart';

class CustomCameraPreview extends StatefulWidget {
  final int maxNumberOfImages;
  final CameraController cameraController;
  final int? maxWidth;
  final int? maxHeight;
  final List<PhotoEditTool> tools;
  final List<PhotoEditTool> forcedOperationsInOrder;
  final double? minZoomLevel;
  final double? maxZoomLevel;
  final List<CropRatio> cropRatios;

  const CustomCameraPreview({
    required this.cameraController,
    super.key,
    this.maxNumberOfImages = 1,
    this.maxWidth,
    this.maxHeight,
    this.tools = const [],
    this.forcedOperationsInOrder = const [],
    this.maxZoomLevel,
    this.minZoomLevel,
    this.cropRatios = const [],
  });

  @override
  CustomCameraPreviewState createState() => CustomCameraPreviewState();
}

class CustomCameraPreviewState extends State<CustomCameraPreview> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    imageCache.clear();
    imageCache.clearLiveImages();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        titleSpacing: 15,
        title: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: Styles.textButtonStyle,
          ),
        ),
        actions: [
          if (context.select<CameraProvider, bool>((value) => value.imageFiles.isNotEmpty))
            TextButton(
              onPressed: () {
                _processImages();
              },
              child: const Text(
                'Confirm',
                style: Styles.textButtonStyle,
              ),
            ),
          const SizedBox(width: 15),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        color: Colors.black87,
        child: context.select<CameraProvider, bool>((value) => value.isProcessing)
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Processing images...',
                      style: TextStyle(fontSize: 14, color: Colors.white, decoration: TextDecoration.none),
                    ),
                  )
                ],
              )
            : Stack(
                alignment: FractionalOffset.center,
                children: <Widget>[
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: widget.cameraController.value.aspectRatio,
                      child: Stack(
                        alignment: AlignmentDirectional.topStart,
                        children: [
                          GestureDetector(
                            onScaleStart: (ScaleStartDetails scaleStartDetails) {
                              context
                                  .read<CameraProvider>()
                                  .setBaseScaleFactor(context.read<CameraProvider>().scaleFactor);
                            },
                            onScaleUpdate: (ScaleUpdateDetails scaleUpdateDetails) {
                              final baseScaleFactor = context.read<CameraProvider>().baseScaleFactor;
                              var scale = baseScaleFactor * scaleUpdateDetails.scale;
                              if (scale > widget.maxZoomLevel!) {
                                scale = widget.maxZoomLevel!;
                              } else if (scale < widget.minZoomLevel!) {
                                scale = widget.minZoomLevel!;
                              }
                              context.read<CameraProvider>().setScaleFactor(scale);
                              widget.cameraController.setZoomLevel(scale);
                            },
                            child: Center(
                              child: CameraPreview(
                                widget.cameraController,
                              ),
                            ),
                          ),
                          Selector<CameraProvider, double>(
                              selector: (context, provider) => provider.scaleFactor,
                              builder: (context, scaleFactor, _) {
                                if (scaleFactor == 1.0) {
                                  return const SizedBox.shrink();
                                }

                                return SafeArea(
                                  child: Container(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: const Color.fromARGB(80, 0, 0, 0),
                                      ),
                                      padding: const EdgeInsets.all(6.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.search,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            '${(scaleFactor > 1.0 && scaleFactor < 1.1 ? 1.1 : scaleFactor).toStringAsFixed(1)}x',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              })
                        ],
                      ),
                    ),
                  ),
                  if (context.read<CameraProvider>().cameras.length > 1)
                    Positioned(
                      bottom: 30,
                      left: MediaQuery.sizeOf(context).width / 6,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          if (context.read<CameraProvider>().takingPicture) return;
                          final camera = context.read<CameraProvider>().switchCamera();
                          widget.cameraController.setDescription(camera);
                        },
                        icon: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // hide camera button in preview mode and when user has taken max number of photos

                  Selector<CameraProvider, bool>(
                    selector: (_, provider) => provider.takingPicture,
                    builder: (context, takingPicture, child) => Positioned(
                      bottom: 20,
                      child: Visibility(
                        visible: context.select<CameraProvider, int>(
                              (value) => value.imageFiles.length,
                            ) <
                            widget.maxNumberOfImages,
                        child: FloatingActionButton(
                          heroTag: "camera",
                          backgroundColor: Colors.grey[800],
                          onPressed: takingPicture
                              ? null
                              : () {
                                  _handleCapture(context);
                                },
                          child: takingPicture
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                  // hide images list in preview mode
                  Positioned(
                    bottom: 100 + MediaQuery.paddingOf(context).bottom,
                    child: SizedBox(
                      height: 80,
                      width: MediaQuery.sizeOf(context).width,
                      child: Selector<CameraProvider, List<XFile>>(
                        selector: (_, provider) => provider.imageFiles,
                        builder: (context, imageFiles, __) {
                          return ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: imageFiles.length,
                            padding: const EdgeInsets.only(left: 2, right: 0),
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Stack(
                                  children: [
                                    GestureDetector(
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.black87,
                                        child: FutureBuilder(
                                            future: imageFiles[index].readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData ||
                                                  snapshot.connectionState != ConnectionState.done) {
                                                return Container();
                                              }
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.contain,
                                              );
                                            }),
                                      ),
                                      onTap: () async {
                                        final editedImage = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditPage(
                                              cropRatios: widget.cropRatios,
                                              image: imageFiles[index],
                                              editModes: widget.tools,
                                              forcedOperations: null,
                                            ),
                                          ),
                                        );
                                        if (editedImage is XFile) {
                                          context.read<CameraProvider>().setImageAtIndex(index, editedImage);
                                        }
                                      },
                                    ),
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        height: 25,
                                        width: 25,
                                        decoration:
                                            const BoxDecoration(color: Color(0x99FFFFFF), shape: BoxShape.circle),
                                        child: GestureDetector(
                                          onTap: () {
                                            context.read<CameraProvider>().removeImageAtIndex(index);
                                          },
                                          child: const Icon(Icons.delete, size: 15, color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _handleCapture(BuildContext context) async {
    await context.read<CameraProvider>().handleCapture(
          takePicture: widget.cameraController.takePicture,
          onImageTaken: widget.forcedOperationsInOrder.isEmpty && widget.maxNumberOfImages > 1
              ? null
              : (image) {
                  return Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPage(
                        image: image,
                        cropRatios: widget.cropRatios,
                        editModes: widget.tools,
                        forcedOperations: widget.forcedOperationsInOrder.isEmpty
                            ? null
                            : ForcedOperations(
                                operationsInOrder: widget.forcedOperationsInOrder,
                                showPreviewAfterOperations: widget.maxNumberOfImages == 1,
                              ),
                      ),
                    ),
                  );
                },
        );

    if (widget.maxNumberOfImages == 1 && context.read<CameraProvider>().imageFiles.length == 1) {
      await _processImages();
      return;
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        if (mounted != true || _scrollController.hasClients != true) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(microseconds: 500),
          curve: Curves.fastOutSlowIn,
        );
      } catch (e) {
        log('failed to do scroll animation');
      }
    });
  }

  // both confirm buttons in preview mode and capture mode
  Future<void> _processImages() async {
    context.read<CameraProvider>().processImages(
          maxHeight: widget.maxHeight,
          maxWidth: widget.maxWidth,
          onProcessFinished: (modifiedImages) {
            if (mounted) Navigator.pop(context, modifiedImages);
          },
        );
  }
}
