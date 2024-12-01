library pictus;

import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:pictus/crop_ratio.dart';
import 'package:pictus/edit/edit_page.dart';
import 'package:pictus/edit/forced_operations.dart';
import 'package:pictus/gallery/provider/custom_gallery_provider.dart';
import 'package:pictus/photo_edit_tool.dart';
import 'package:pictus/styles.dart';
import 'package:provider/provider.dart';

class CustomGalleryPreview extends StatelessWidget {
  final List<PhotoEditTool> availableTools;
  final List<PhotoEditTool> forcedOperationsInOrder;
  final List<XFile> initialImages;
  final List<CropRatio> cropRatios;

  const CustomGalleryPreview({
    required this.initialImages,
    super.key,
    this.availableTools = const [],
    this.forcedOperationsInOrder = const [],
    this.cropRatios = const [],
  });

  Future<void> _doForcedOperations(BuildContext context) async {
    if (forcedOperationsInOrder.isNotEmpty && initialImages.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback(
        (timeStamp) async {
          final editedImage = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FutureBuilder<Uint8List>(
                future: initialImages[0].readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Failed to load image'));
                  }

                  return EditPage(
                    cropRatios: cropRatios,
                    imageBytes: snapshot.data!,
                    editModes: availableTools,
                    forcedOperations: ForcedOperations(
                      operationsInOrder: forcedOperationsInOrder,
                      showPreviewAfterOperations: true,
                    ),
                    isInMultiImageMode: initialImages.length > 1,
                    isFromGallery: true,
                  );
                },
              ),
            ),
          );
          if (editedImage is XFile) {
            Navigator.pop(context, [editedImage]);
          } else {
            Navigator.pop(context);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var safeAreaPadding = MediaQuery.paddingOf(context);
    return ChangeNotifierProvider(
      create: (context) {
        _doForcedOperations(context);
        return CustomGalleryProvider(initialImages: initialImages);
      },
      child: Consumer<CustomGalleryProvider>(builder: (context, provider, child) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.black87,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            titleSpacing: 15,
            backgroundColor: Colors.transparent,
            title: TextButton(
              onPressed: provider.isProcessing ? null : () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: Styles.textButtonStyle,
              ),
            ),
            actions: [
              if (provider.imageFiles.isNotEmpty)
                TextButton(
                  onPressed: provider.isProcessing
                      ? null
                      : () {
                          _processImages(context);
                        },
                  child: const Text(
                    'Confirm',
                    style: Styles.textButtonStyle,
                  ),
                ),
              const SizedBox(width: 15),
            ],
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black87,
            child: provider.isProcessing
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
                          child: FutureBuilder(
                            future: provider.imageFiles[provider.previewImageIndex].readAsBytes(),
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
                          ),
                        ),
                      ),
                      if (availableTools.isNotEmpty)
                        Positioned(
                          bottom: 20 + safeAreaPadding.bottom,
                          left: 20 + safeAreaPadding.left,
                          child: TextButton.icon(
                            label: const Text(
                              'Edit',
                              style: Styles.textButtonStyle,
                            ),
                            // show delete icon in preview mode
                            onPressed: () async {
                              var imageBytes = await provider.imageFiles[provider.previewImageIndex].readAsBytes();
                              final editedImage = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditPage(
                                    cropRatios: cropRatios,
                                    imageBytes: imageBytes,
                                    editModes: availableTools,
                                    isInMultiImageMode: initialImages.length > 1,
                                    isFromGallery: true,
                                  ),
                                ),
                              );
                              provider.setImageAtIndex(provider.previewImageIndex, editedImage);
                            },
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // hide images list in preview mode
                      Positioned(
                        bottom: 90 + safeAreaPadding.bottom,
                        child: SizedBox(
                          height: 80,
                          width: MediaQuery.sizeOf(context).width,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: provider.imageFiles.length,
                            padding: const EdgeInsets.only(left: 2, right: 0),
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  GestureDetector(
                                    child: FutureBuilder(
                                        future: provider.imageFiles[index].readAsBytes(),
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
                                      provider.setPreviewIndex(index);
                                    },
                                  ),
                                  if (provider.imageFiles.length > 1)
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: Container(
                                        height: 25,
                                        width: 25,
                                        decoration:
                                            const BoxDecoration(color: Color(0x99FFFFFF), shape: BoxShape.circle),
                                        child: GestureDetector(
                                          onTap: () => provider.removeImageAtIndex(index),
                                          child: const Icon(Icons.delete, size: 15, color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      }),
    );
  }

  Future<void> _processImages(BuildContext context) async {
    if (context.mounted) Navigator.pop(context, context.read<CustomGalleryProvider>().imageFiles);
  }
}
