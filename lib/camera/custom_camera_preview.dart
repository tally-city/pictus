library pictus;

import 'dart:developer';

import 'package:pictus/crop_ratio.dart';
import 'package:pictus/photo_edit_tool.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pictus/edit/edit_page.dart';

class CustomCameraPreview extends StatefulWidget {
  final int maxNumberOfImages;
  final CameraController cameraController;
  final int? maxWidth;
  final int? maxHeight;
  final List<PhotoEditTool> tools;
  final double? minZoomLevel;
  final double? maxZoomLevel;
  final bool forceCrop;
  final List<CropRatio> cropRatios;
  final List<CameraDescription> cameras;
  final int cameraIndex;

  const CustomCameraPreview({
    required this.cameraController,
    required this.cameras,
    required this.cameraIndex,
    super.key,
    this.maxNumberOfImages = 1,
    this.maxWidth,
    this.maxHeight,
    this.tools = const [],
    this.maxZoomLevel,
    this.minZoomLevel,
    this.forceCrop = false,
    this.cropRatios = const [],
  });

  @override
  CustomCameraPreviewState createState() => CustomCameraPreviewState();
}

class CustomCameraPreviewState extends State<CustomCameraPreview> {
  bool _isProcessing = false;
  final List<XFile> _imageFiles = [];
  final _scrollController = ScrollController();
  final _thumbnails = ValueNotifier<List<Uint8List>>([]);
  final _takingPicture = ValueNotifier<bool>(false);
  late int _cameraIndex;

  final _baseScaleFactor = ValueNotifier<double>(1.0);
  final _scaleFactor = ValueNotifier<double>(1.0);

  @override
  void initState() {
    _cameraIndex = widget.cameraIndex;
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
        leadingWidth: 100,
        backgroundColor: Colors.transparent,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          if (_imageFiles.isNotEmpty)
            TextButton(
              onPressed: () {
                _handleConfirm();
              },
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(width: 10),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        color: Colors.black87,
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
                      child: Stack(
                        alignment: AlignmentDirectional.topStart,
                        children: [
                          GestureDetector(
                            onScaleStart: (ScaleStartDetails scaleStartDetails) {
                              _baseScaleFactor.value = _scaleFactor.value;
                            },
                            onScaleUpdate: (ScaleUpdateDetails scaleUpdateDetails) {
                              var scale = _baseScaleFactor.value * scaleUpdateDetails.scale;
                              if (scale > widget.maxZoomLevel!) {
                                scale = widget.maxZoomLevel!;
                              } else if (scale < widget.minZoomLevel!) {
                                scale = widget.minZoomLevel!;
                              }
                              _scaleFactor.value = scale;
                              widget.cameraController.setZoomLevel(scale).then(
                                (value) {
                                  // _scaleFactor.value = scale;
                                },
                              );
                            },
                            child: Center(
                              child: CameraPreview(
                                widget.cameraController,
                              ),
                            ),
                          ),
                          ValueListenableBuilder(
                              valueListenable: _scaleFactor,
                              builder: (context, value, child) {
                                if (_scaleFactor.value == 1.0) return const SizedBox.shrink();

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
                                            '${(value > 1.0 && value < 1.1 ? 1.1 : value).toStringAsFixed(1)}x',
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
                  if (widget.cameras.length > 1)
                    Positioned(
                      bottom: 25,
                      left: 15,
                      child: IconButton(
                        onPressed: () {
                          if (_cameraIndex < widget.cameras.length - 1) {
                            setState(() {
                              _cameraIndex++;
                            });
                          } else {
                            setState(() {
                              _cameraIndex = 0;
                            });
                          }
                          widget.cameraController.setDescription(widget.cameras[_cameraIndex]);
                        },
                        icon: const Icon(
                          Icons.cameraswitch,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  // hide camera button in preview mode and when user has taken max number of photos
                  if (_imageFiles.length < widget.maxNumberOfImages)
                    ValueListenableBuilder(
                      valueListenable: _takingPicture,
                      builder: (context, takingPicture, child) => Positioned(
                        bottom: 20,
                        child: FloatingActionButton(
                          heroTag: "camera",
                          backgroundColor: Colors.grey[800],
                          onPressed: takingPicture ? null : () => _handleCapture(),
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
                  // hide images list in preview mode
                  Positioned(
                    bottom: 80 + MediaQuery.paddingOf(context).bottom,
                    child: SizedBox(
                      height: 80,
                      width: MediaQuery.sizeOf(context).width,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageFiles.length,
                        padding: const EdgeInsets.only(left: 2, right: 0),
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  child: Image.memory(
                                    _thumbnails.value[index],
                                    fit: BoxFit.contain,
                                  ),
                                  onTap: () async {
                                    final editedImage = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditPage(
                                          cropRatios: widget.cropRatios,
                                          image: _imageFiles[index],
                                          editModes: widget.tools,
                                        ),
                                      ),
                                    );
                                    if (editedImage is XFile) {
                                      setState(() {
                                        _imageFiles[index] = editedImage;
                                      });
                                      final bytes = await editedImage.readAsBytes();
                                      final thumbnail = img.encodeJpg(img.copyResize(
                                        img.decodeImage(bytes)!,
                                        width: 100,
                                        height: 100,
                                      ));
                                      _thumbnails.value[index] = thumbnail;
                                    }
                                  },
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    height: 25,
                                    width: 25,
                                    decoration: const BoxDecoration(color: Color(0x99FFFFFF), shape: BoxShape.circle),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _imageFiles.removeAt(index);
                                          _thumbnails.value.removeAt(index);
                                        });
                                      },
                                      child: const Icon(Icons.delete, size: 15, color: Colors.black87),
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

  Future<void> _handleCapture() async {
    //you can give limit that's user can take how many photo
    if ((_imageFiles.length) < (widget.maxNumberOfImages)) {
      //take a photo
      _takingPicture.value = true;
      final imageXFile = await widget.cameraController.takePicture();
      _takingPicture.value = false;
      final bytes = await imageXFile.readAsBytes();
      final thumbnail = img.encodeJpg(img.copyResize(
        img.decodeImage(bytes)!,
        width: 100,
        height: 100,
      ));

      //add photo into files list
      setState(() {
        _imageFiles.add(XFile.fromData(
          bytes,
          lastModified: DateTime.now(),
          mimeType: 'image/jpeg',
          name: imageXFile.name,
          length: bytes.length,
          path: imageXFile.path,
        ));
        _thumbnails.value = [..._thumbnails.value, thumbnail];
      });

      if (widget.maxNumberOfImages == 1) {
        if (widget.tools.contains(PhotoEditTool.crop)) {
          final editedImage = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPage(
                image: _imageFiles[0],
                cropRatios: widget.cropRatios,
                forceCrop: widget.forceCrop,
                editModes: widget.tools,
              ),
            ),
          );

          if (editedImage is XFile) {
            final bytes = await editedImage.readAsBytes();
            final thumbnail = img.encodeJpg(img.copyResize(
              img.decodeImage(bytes)!,
              width: 100,
              height: 100,
            ));
            setState(() {
              _imageFiles[0] = editedImage;
              _thumbnails.value[0] = thumbnail;
            });
            _handleConfirm();
            return;
          } else {
            setState(() {
              _imageFiles.removeLast();
              _thumbnails.value.removeLast();
            });
          }
        }

        if (widget.tools.isEmpty) {
          await _handleConfirm();
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
  Future<void> _handleConfirm() async {
    setState(() {
      _isProcessing = true;
    });

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
      _isProcessing = false;
    });

    if (mounted) Navigator.pop(context, modifiedImages);
  }
}
