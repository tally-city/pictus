library pictus;

import 'package:pictus/photo_edit_tool.dart';
import 'package:camera/camera.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class CustomGalleryPreview extends StatefulWidget {
  final int? maxWidth;
  final int? maxHeight;
  final List<PhotoEditTool> tools;
  final double? minZoomLevel;
  final double? maxZoomLevel;
  final List<XFile> initialImages;

  const CustomGalleryPreview({
    required this.initialImages,
    super.key,
    this.maxWidth,
    this.maxHeight,
    this.tools = const [],
    this.maxZoomLevel,
    this.minZoomLevel,
  });

  @override
  CustomGalleryPreviewState createState() => CustomGalleryPreviewState();
}

class CustomGalleryPreviewState extends State<CustomGalleryPreview> {
  bool _isProcessing = false;
  List<XFile> _imageFiles = [];
  bool _isInEditMode = false;
  int _previewImageIndex = 0;
  final _scrollController = ScrollController();
  final _cropController = CropController();

  bool get _singleShotMode => widget.initialImages.length == 1;

  @override
  void initState() {
    imageCache.clear();
    imageCache.clearLiveImages();
    _imageFiles = [...widget.initialImages];
    if (_singleShotMode) _isInEditMode = true;
    _previewImageIndex = 0;
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var safeAreaPadding = MediaQuery.of(context).padding;
    return PopScope(
      canPop: !_isInEditMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            _isInEditMode = false;
          });
        }
      },
      child: Container(
        color: Colors.black,
        child: _isProcessing
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
                    child: FutureBuilder(
                      future: _imageFiles[_previewImageIndex].readAsBytes(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
                          return const CircularProgressIndicator();
                        }
                        if (_isInEditMode) {
                          return Crop(
                            baseColor: Colors.black,
                            initialSize: .5,
                            aspectRatio: 1,
                            controller: _cropController,
                            onCropped: (value) async {
                              var file = XFile.fromData(
                                value,
                              );
                              setState(() {
                                _isProcessing = false;
                                _imageFiles[_previewImageIndex] = file;
                                _isInEditMode = false;
                              });
                              if (_singleShotMode) {
                                _processImages();
                                return;
                              }
                            },
                            image: snapshot.data!,
                          );
                        }
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.contain,
                        );
                      },
                    ),
                  ),
                  // hide confirm button on no images
                  _imageFiles.isEmpty
                      ? Container()
                      : Positioned(
                          bottom: 20 + safeAreaPadding.bottom,
                          right: 20 + safeAreaPadding.right,
                          child: FloatingActionButton(
                            heroTag: "confirm",
                            backgroundColor: Colors.green,
                            onPressed: () async {
                              setState(() {
                                _isProcessing = true;
                              });
                              if (_isInEditMode) {
                                _cropController.crop();
                              }
                              if (_singleShotMode) {
                                return;
                              } else if (!_isInEditMode) {
                                _processImages();
                              }
                            },
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                          ),
                        ),
                  Positioned(
                    top: 20 + safeAreaPadding.top,
                    left: 20 + safeAreaPadding.left,
                    child: FloatingActionButton(
                      // show delete icon in preview mode
                      heroTag: "close",
                      backgroundColor: Colors.black.withOpacity(.4),
                      onPressed: () async {
                        if (_isInEditMode && !_singleShotMode) {
                          setState(() {
                            _isInEditMode = false;
                          });
                          return;
                        }
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (!_isInEditMode && widget.tools.contains(PhotoEditTool.crop))
                    Positioned(
                      bottom: 20 + safeAreaPadding.bottom,
                      left: 20 + safeAreaPadding.left,
                      child: FloatingActionButton(
                        // show delete icon in preview mode
                        heroTag: "edit",
                        backgroundColor: Colors.black.withOpacity(.3),
                        onPressed: () async {
                          setState(() {
                            _isInEditMode = true;
                          });
                        },
                        child: const Icon(
                          Icons.crop,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // hide images list in preview mode
                  _isInEditMode || _singleShotMode
                      ? Container()
                      : Positioned(
                          bottom: 80 + safeAreaPadding.bottom,
                          child: SizedBox(
                            height: 80,
                            width: MediaQuery.of(context).size.width,
                            child: ListView.builder(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: _imageFiles.length,
                              padding: EdgeInsets.only(left: safeAreaPadding.left, right: safeAreaPadding.right),
                              itemBuilder: (context, index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 2.0,
                                      color:
                                          (_previewImageIndex == index ? Colors.green : Colors.white).withOpacity(.8),
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        child: FutureBuilder(
                                            future: _imageFiles[index].readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return const CircularProgressIndicator();
                                              }
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                                height: 100,
                                                width: 100,
                                                key: UniqueKey(),
                                              );
                                            }),
                                        onTap: () {
                                          setState(() {
                                            _previewImageIndex = index;
                                            // _isInEditMode = true;
                                          });
                                        },
                                      ),
                                      if (_imageFiles.length > 1)
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
                                                setState(() {
                                                  _imageFiles.removeAt(index);
                                                  _previewImageIndex = 0;
                                                });
                                              },
                                              child: const Icon(Icons.delete, size: 15, color: Colors.black),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
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

  // both confirm buttons in preview mode and capture mode
  Future<void> _processImages() async {
    setState(() {
      _isProcessing = true;
    });

    final modifiedImages = <XFile>[];
    for (final file in _imageFiles) {
      if (widget.maxHeight != null || widget.maxWidth != null) {
        var image = img.decodeImage(await file.readAsBytes())!;
        image = img.copyResize(
          image,
          width: image.width > (widget.maxWidth ?? 0) ? widget.maxWidth : image.width,
          height: image.height > (widget.maxHeight ?? 0) ? widget.maxHeight : image.height,
        );
        final newImage = XFile.fromData(img.encodeJpg(image));
        modifiedImages.add(newImage);
      } else {
        modifiedImages.add(file);
      }
    }

    setState(() {
      _isInEditMode = false;
      _isProcessing = false;
    });

    if (mounted) Navigator.pop(context, modifiedImages);
  }
}
