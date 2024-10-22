library pictus;

import 'package:pictus/crop_ratio.dart';
import 'package:pictus/photo_edit_tool.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:pictus/edit/edit_page.dart';

class CustomGalleryPreview extends StatefulWidget {
  final int? maxWidth;
  final int? maxHeight;
  final List<PhotoEditTool> availableTools;
  final List<PhotoEditTool> forcedOperationsInOrder;

  final List<XFile> initialImages;
  final List<CropRatio> cropRatios;

  const CustomGalleryPreview({
    required this.initialImages,
    super.key,
    this.maxWidth,
    this.maxHeight,
    this.availableTools = const [],
    this.forcedOperationsInOrder = const [],
    this.cropRatios = const [],
  });

  @override
  CustomGalleryPreviewState createState() => CustomGalleryPreviewState();
}

class CustomGalleryPreviewState extends State<CustomGalleryPreview> {
  bool _isProcessing = false;
  List<XFile> _imageFiles = [];
  final _previewImageIndex = ValueNotifier<int>(0);
  final _scrollController = ScrollController();

  @override
  void initState() {
    _imageFiles = [...widget.initialImages];
    _previewImageIndex.value = 0;
    _forceCrop();
    super.initState();
  }

  Future<void> _forceCrop() async {
    if (widget.forcedOperationsInOrder.isNotEmpty && widget.initialImages.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) async {
          final editedImage = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditPage(
                cropRatios: widget.cropRatios,
                image: _imageFiles[_previewImageIndex.value],
                editModes: widget.availableTools,
                // forceCrops: true,
              ),
            ),
          );
          if (editedImage is XFile) {
            setState(() {
              _imageFiles[0] = editedImage;
            });
            _processImages();
          } else {
            Navigator.pop(context);
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var safeAreaPadding = MediaQuery.paddingOf(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black87,
      appBar: AppBar(
        leadingWidth: 100,
        backgroundColor: Colors.transparent,
        leading: TextButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
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
              onPressed: _isProcessing
                  ? null
                  : () {
                      _processImages();
                    },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
                    child: Container(
                      color: Colors.black87,
                      child: ValueListenableBuilder(
                          valueListenable: _previewImageIndex,
                          builder: (context, value, child) {
                            return FutureBuilder(
                              future: _imageFiles[value].readAsBytes(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                return Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.contain,
                                );
                              },
                            );
                          }),
                    ),
                  ),
                  if (widget.availableTools.isNotEmpty)
                    Positioned(
                      bottom: 20 + safeAreaPadding.bottom,
                      left: 20 + safeAreaPadding.left,
                      child: TextButton.icon(
                        label: const Text(
                          'Edit',
                          style: TextStyle(color: Colors.white),
                        ),
                        // show delete icon in preview mode
                        onPressed: () async {
                          final editedImage = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditPage(
                                cropRatios: widget.cropRatios,
                                image: _imageFiles[_previewImageIndex.value],
                                editModes: widget.availableTools,
                              ),
                            ),
                          );
                          if (editedImage is XFile) {
                            setState(() {
                              _imageFiles[_previewImageIndex.value] = editedImage;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  // hide images list in preview mode
                  Positioned(
                    bottom: 70 + safeAreaPadding.bottom,
                    child: SizedBox(
                      height: 80,
                      width: MediaQuery.sizeOf(context).width,
                      child: ListView.builder(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageFiles.length,
                        padding: const EdgeInsets.only(left: 2, right: 0),
                        itemBuilder: (context, index) {
                          return ValueListenableBuilder(
                            valueListenable: _previewImageIndex,
                            builder: (context, value, child) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                                decoration: value == index
                                    ? BoxDecoration(
                                        border: Border.all(
                                          width: 2.0,
                                          color: Theme.of(context).colorScheme.primary.withOpacity(.8),
                                        ),
                                      )
                                    : null,
                                child: child,
                              );
                            },
                            child: Stack(
                              children: [
                                GestureDetector(
                                  child: FutureBuilder(
                                      future: _imageFiles[index].readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData || snapshot.connectionState != ConnectionState.done) {
                                          return const CircularProgressIndicator();
                                        }
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                          height: 80,
                                          width: 80,
                                        );
                                      }),
                                  onTap: () {
                                    _previewImageIndex.value = index;
                                  },
                                ),
                                if (_imageFiles.length > 1)
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      height: 25,
                                      width: 25,
                                      decoration: const BoxDecoration(color: Color(0x99FFFFFF), shape: BoxShape.circle),
                                      child: GestureDetector(
                                        onTap: () {
                                          _previewImageIndex.value = 0;
                                          setState(() {
                                            _imageFiles.removeAt(index);
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
        final newImage =
            XFile.fromData(img.encodeJpg(image), mimeType: 'image/jpeg', name: file.name, lastModified: DateTime.now());
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
