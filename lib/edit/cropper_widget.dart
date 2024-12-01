import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:pictus/pictus.dart';

class CropperWidget extends StatefulWidget {
  const CropperWidget({
    super.key,
    this.controller,
    this.cropRatios = const [],
    required this.bytes,
    required this.onCropped,
  });

  final List<CropRatio> cropRatios;
  final Uint8List bytes;
  final CropController? controller;
  final void Function(XFile file) onCropped;

  @override
  State<CropperWidget> createState() => CropperWidgetState();
}

class CropperWidgetState extends State<CropperWidget> {
  late final CropController _controller;
  late CropRatio _cropRatio;

  @override
  void initState() {
    _controller = widget.controller ?? CropController();
    if (widget.cropRatios.isEmpty) {
      _cropRatio = CropRatio.free;
    } else if (widget.cropRatios.length < CropRatio.values.length) {
      _cropRatio = widget.cropRatios.first;
    }
    super.initState();
  }

  void crop() {
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Crop(
        baseColor: Colors.black87,
        initialSize: .9,
        aspectRatio: _cropRatio.ratio,
        controller: _controller,
        image: widget.bytes,
        interactive: true,
        onCropped: (value) async {
          widget.onCropped(XFile.fromData(
            value,
            lastModified: DateTime.now(),
            mimeType: 'image/png',
          ));
        },
      ),
      bottomNavigationBar: Container(
        height: 80,
        color: Colors.black87,
        child: _buildRatios(),
      ),
    );
  }

  Widget _buildRatios() {
    List<CropRatio> values = (widget.cropRatios.length <= 1
        ? widget.cropRatios.isEmpty
            ? CropRatio.values
            : []
        : widget.cropRatios);
    final tools = values
        .map(
          (ratio) => TextButton(
            onPressed: () {
              _controller.aspectRatio = ratio.ratio;
              setState(() {
                _cropRatio = ratio;
              });
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  ratio.icon,
                  color: ratio == _cropRatio ? Theme.of(context).colorScheme.primary : Colors.white,
                ),
                Text(
                  ratio.title,
                  style: TextStyle(
                    color: ratio == _cropRatio ? Theme.of(context).colorScheme.primary : Colors.white,
                  ),
                )
              ],
            ),
          ),
        )
        .toList();
    return Center(
      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        children: tools,
      ),
    );
  }
}
