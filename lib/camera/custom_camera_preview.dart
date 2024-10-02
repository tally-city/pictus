library pictus;

import 'dart:developer';

import 'package:pictus/photo_edit_tool.dart';
import 'package:camera/camera.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

class CustomCameraPreview extends StatefulWidget {
  final int maxNumberOfImages;
  final CameraController cameraController;
  final int? maxWidth;
  final int? maxHeight;
  final List<PhotoEditTool> tools;
  final double? minZoomLevel;
  final double? maxZoomLevel;

  const CustomCameraPreview({
    required this.cameraController,
    super.key,
    this.maxNumberOfImages = 1,
    this.maxWidth,
    this.maxHeight,
    this.tools = const [],
    this.maxZoomLevel,
    this.minZoomLevel,
  });

  @override
  CustomCameraPreviewState createState() => CustomCameraPreviewState();
}

class CustomCameraPreviewState extends State<CustomCameraPreview> {
  bool _isProcessing = false;
  final List<XFile> _imageFiles = [];
  final List<Uint8List> _thumbnails = [];
  bool _isInReviewMode = false;
  bool _isInEditMode = false;
  int? _previewImageIndex;
  final _scrollController = ScrollController();
  final _cropController = CropController();

  // final _imagePainterKey = GlobalKey<ImagePainterState>();

  double? _baseScaleFactor = 1.0;
  double? _scaleFactor = 1.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ensure that the page is displayed in the correct orientation.
    // if the user starts the page while the device is in physical landscape mode,
    // the page displays in portrait mode and the image becomes stretched. (flutter bug)
    var quarterTurns = 0;
    var currentCameraOrientation = widget.cameraController.value.deviceOrientation;
    var currentDeviceOrientation = MediaQuery.of(context).orientation;
    if (([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight].contains(currentCameraOrientation) &&
            currentDeviceOrientation == Orientation.portrait) ||
        ([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown].contains(currentCameraOrientation) &&
            currentDeviceOrientation == Orientation.landscape)) {
      switch (currentCameraOrientation) {
        case DeviceOrientation.landscapeRight:
        case DeviceOrientation.portraitUp:
          quarterTurns = 1;
          break;
        case DeviceOrientation.portraitDown:
        case DeviceOrientation.landscapeLeft:
          quarterTurns = 3;
          break;
        default:
      }
    }

    // calculate safe area padding values for each side of the page based on orientation
    var safeAreaPadding = MediaQuery.of(context).padding;
    var safeRightPadding = (quarterTurns == 1
        ? safeAreaPadding.bottom
        : quarterTurns == 3
            ? safeAreaPadding.top
            : safeAreaPadding.right);
    var safeLeftPadding = (quarterTurns == 1
        ? safeAreaPadding.top
        : quarterTurns == 3
            ? safeAreaPadding.bottom
            : safeAreaPadding.left);
    var safeBottomPadding = (quarterTurns == 1
        ? safeAreaPadding.right
        : quarterTurns == 3
            ? safeAreaPadding.left
            : safeAreaPadding.bottom);

    var singleShotMode = (widget.maxNumberOfImages) == 1;
    imageCache.clear();
    imageCache.clearLiveImages();

    return PopScope(
      canPop: !_isInEditMode && !_isInReviewMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_isInEditMode) {
            setState(() {
              _isInEditMode = false;
            });
            return;
          }
          if (_isInReviewMode) {
            setState(() {
              _isInReviewMode = false;
            });
            return;
          }
        }
      },
      child: RotatedBox(
        quarterTurns: quarterTurns,
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
                      child: AspectRatio(
                        aspectRatio: widget.cameraController.value.aspectRatio,
                        child: _isInReviewMode
                            ? FutureBuilder(
                                future: _imageFiles[_previewImageIndex!].readAsBytes(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const CircularProgressIndicator();
                                  }
                                  if (!_isInEditMode) {
                                    return Image.memory(snapshot.data!);
                                  }
                                  return Crop(
                                    baseColor: Colors.black,
                                    initialSize: .5,
                                    aspectRatio: 1,
                                    controller: _cropController,
                                    image: snapshot.data!,
                                    onCropped: (value) async {
                                      var file = XFile.fromData(
                                        value,
                                      );
                                      final bytes = await file.readAsBytes();
                                      final thumbnail = img.encodeJpg(img.copyResize(
                                        img.decodeImage(bytes)!,
                                        width: 100,
                                        height: 100,
                                      ));
                                      _imageFiles[_previewImageIndex!] = file;
                                      _thumbnails[_previewImageIndex!] = thumbnail;
                                      if (singleShotMode) {
                                        _processImages();
                                        return;
                                      }
                                      setState(() {
                                        _isProcessing = false;
                                        _isInEditMode = false;
                                      });
                                    },
                                  );
                                })
                            : Stack(
                                alignment: AlignmentDirectional.topStart,
                                children: [
                                  GestureDetector(
                                    onScaleStart: (ScaleStartDetails scaleStartDetails) {
                                      _baseScaleFactor = _scaleFactor;
                                    },
                                    onScaleUpdate: (ScaleUpdateDetails scaleUpdateDetails) {
                                      if (mounted) {
                                        setState(() {
                                          _scaleFactor = _baseScaleFactor! * scaleUpdateDetails.scale;
                                          if (_scaleFactor! > widget.maxZoomLevel!) {
                                            _scaleFactor = widget.maxZoomLevel;
                                          } else if (_scaleFactor! < widget.minZoomLevel!) {
                                            _scaleFactor = widget.minZoomLevel;
                                          }
                                        });
                                      }
                                      widget.cameraController.setZoomLevel(_scaleFactor!);
                                    },
                                    child: Center(
                                      child: CameraPreview(widget.cameraController),
                                    ),
                                  ),
                                  if (_scaleFactor != 1.0)
                                    SafeArea(
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
                                                '${(_scaleFactor! > 1.0 && _scaleFactor! < 1.1 ? 1.1 : _scaleFactor)?.toStringAsFixed(1) ?? 1}x',
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
                                    )
                                ],
                              ),
                      ),
                    ),
                    // hide camera button in preview mode and when user has taken max number of photos
                    _isInReviewMode || (_imageFiles.length) >= (widget.maxNumberOfImages)
                        ? Container()
                        : Positioned(
                            bottom: 20,
                            child: FloatingActionButton(
                              heroTag: "camera",
                              backgroundColor: Colors.white,
                              onPressed: () => _handleCapture(singleShotMode),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                              ),
                            ),
                          ),
                    // hide confirm button on no images
                    _imageFiles.isEmpty
                        ? Container()
                        : Positioned(
                            bottom: 20 + safeBottomPadding,
                            right: 20 + safeRightPadding,
                            child: FloatingActionButton(
                              heroTag: "confirm",
                              backgroundColor: Colors.green,
                              onPressed: () async {
                                _handleConfirm(singleShotMode);
                              },
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    Positioned(
                      top: 20 + safeBottomPadding,
                      left: 20 + safeLeftPadding,
                      child: FloatingActionButton(
                        heroTag: "edit",
                        backgroundColor: Colors.black.withOpacity(.4),
                        onPressed: () async {
                          if (singleShotMode && _isInReviewMode) {
                            _isInReviewMode = false;
                            _imageFiles.removeAt(0);
                            _previewImageIndex = null;
                          }
                          if (_isInEditMode) {
                            setState(() {
                              _isInEditMode = false;
                            });
                            return;
                          }
                          if (_isInReviewMode) {
                            setState(() {
                              _isInReviewMode = false;
                            });
                            return;
                          }
                          if (!_isInReviewMode && !_isInEditMode) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_isInReviewMode && !_isInEditMode && widget.tools.contains(PhotoEditTool.crop))
                      Positioned(
                        bottom: 20 + safeBottomPadding,
                        left: 20 + safeLeftPadding,
                        child: FloatingActionButton(
                          heroTag: "edit",
                          backgroundColor: Colors.black.withOpacity(.4),
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
                    _isInReviewMode
                        ? Container()
                        : Positioned(
                            bottom: 80 + safeBottomPadding,
                            child: SizedBox(
                              height: 80,
                              width: quarterTurns > 0 && quarterTurns < 4
                                  ? MediaQuery.of(context).size.height
                                  : MediaQuery.of(context).size.width,
                              child: ListView.builder(
                                controller: _scrollController,
                                scrollDirection: Axis.horizontal,
                                itemCount: _imageFiles.length,
                                padding: EdgeInsets.only(left: safeLeftPadding, right: safeRightPadding),
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                    decoration: BoxDecoration(border: Border.all(width: 2.0, color: Colors.white)),
                                    child: Stack(
                                      children: [
                                        GestureDetector(
                                          child: Image.memory(
                                            _thumbnails[index],
                                            fit: BoxFit.cover,
                                            height: 100,
                                            width: 100,
                                            key: UniqueKey(),
                                          ),
                                          onTap: () {
                                            setState(() {
                                              _previewImageIndex = index;
                                              _isInReviewMode = true;
                                            });
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
                                                setState(() {
                                                  _imageFiles.removeAt(index);
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
      ),
    );
  }

  Future<void> _handleCapture(bool singleShotMode) async {
    //you can give limit that's user can take how many photo
    if ((_imageFiles.length) < (widget.maxNumberOfImages)) {
      //take a photo
      var imageXFile = await widget.cameraController.takePicture();
      final bytes = await imageXFile.readAsBytes();
      final thumbnail = img.encodeJpg(img.copyResize(
        img.decodeImage(bytes)!,
        width: 100,
        height: 100,
      ));
      //add photo into files list
      setState(() {
        _imageFiles.add(imageXFile);
        _thumbnails.add(thumbnail);
      });

      if (singleShotMode) {
        setState(() {
          _previewImageIndex = _imageFiles.length - 1;
          _isInReviewMode = true;

          if (widget.tools.contains(PhotoEditTool.crop)) _isInEditMode = true;
        });

        if (widget.tools.isEmpty) {
          await _handleConfirm(singleShotMode);
        }
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
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(" Error"),
          content: Text(
              "You can't take more than ${widget.maxNumberOfImages} image${widget.maxNumberOfImages > 1 ? "s" : ""}."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Ok"),
            ),
          ],
        ),
      );
    }
  }

  // both confirm buttons in preview mode and capture mode
  Future<void> _handleConfirm(bool singleImageMode) async {
    setState(() {
      _isProcessing = true;
    });

    if (_isInEditMode || (singleImageMode && widget.tools.contains(PhotoEditTool.crop))) {
      _cropController.crop();
      return;
    }

    if (_isInReviewMode) {
      if (!singleImageMode) {
        setState(() {
          _isInReviewMode = false;
          _isProcessing = false;
        });
        return;
      }
    }

    _processImages();
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
