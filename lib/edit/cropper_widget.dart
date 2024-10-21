import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:pictus/crop_ratio.dart';
import 'package:pictus/pictus.dart';

class CropperWidget extends StatefulWidget {
  const CropperWidget({
    super.key,
    this.controller,
    this.cropRatio,
    required this.bytes,
    required this.onCropped,
  });

  final CropRatio? cropRatio;
  final Uint8List bytes;
  final CropController? controller;
  final void Function(XFile file) onCropped;

  @override
  State<CropperWidget> createState() => CropperWidgetState();
}

class CropperWidgetState extends State<CropperWidget> {
  late final CropController _controller;

  @override
  void initState() {
    _controller = widget.controller ?? CropController();
    super.initState();
  }

  void crop() {
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Crop(
      baseColor: Colors.black,
      initialSize: .5,
      aspectRatio: widget.cropRatio?.ratio,
      controller: _controller,
      image: widget.bytes,
      onCropped: (value) async {
        widget.onCropped(
          XFile.fromData(
            value,
            lastModified: DateTime.now(),
            mimeType: 'image/jpeg',
            length: value.length,
            name: '${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      },
    );
  }
}
