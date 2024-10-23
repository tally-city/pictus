import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';
import 'package:pictus/pictus.dart';

class PainterWidget extends StatefulWidget {
  const PainterWidget({
    super.key,
    this.controller,
    required this.bytes,
    required this.onPaintFinished,
  });

  final ImagePainterController? controller;
  final Uint8List bytes;
  final void Function(XFile? file) onPaintFinished;

  @override
  State<PainterWidget> createState() => PainterWidgetState();
}

class PainterWidgetState extends State<PainterWidget> {
  late ImagePainterController _controller;

  @override
  void initState() {
    _controller = widget.controller ?? ImagePainterController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ImagePainter.memory(
      widget.bytes,
      controller: _controller,
      controlsAtTop: false,
      brushIcon: const Icon(
        Icons.brush,
        color: Colors.white,
      ),
      undoIcon: const Icon(
        Icons.reply,
        color: Colors.white,
      ),
      clearAllIcon: const Icon(
        Icons.clear,
        color: Colors.white,
      ),
      controlsBackgroundColor: Colors.black87,
      optionColor: Colors.white,
    );
  }

  void exportImage() {
    _controller.exportImage().then(
      (bytes) {
        if (bytes == null) widget.onPaintFinished(null);
        widget.onPaintFinished(XFile.fromData(
          bytes!,
          lastModified: DateTime.now(),
          mimeType: 'image/png',
          length: bytes.length,
          name: '${DateTime.now().millisecondsSinceEpoch}.jpg',
        ));
      },
    );
  }
}
