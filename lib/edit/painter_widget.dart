import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_painter/image_painter.dart';

class PainterWidget extends StatefulWidget {
  const PainterWidget({
    super.key,
    this.controller,
    required this.imageBytes,
    required this.onPaintFinished,
  });

  final ImagePainterController? controller;
  final Uint8List imageBytes;
  final void Function(Uint8List? imageBytes) onPaintFinished;

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
      widget.imageBytes,
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
      (imageBytes) {
        if (imageBytes == null) widget.onPaintFinished(null);
        widget.onPaintFinished(imageBytes);
      },
    );
  }
}
