library pictus;

import 'dart:developer';

import 'package:pictus/camera/custom_camera_preview.dart';
import 'package:pictus/photo_edit_tool.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class Camera extends StatefulWidget {
  final int maxNumberOfImages;
  final bool? canPop;
  final List<PhotoEditTool> tools;
  final int? maxWidth;
  final int? maxHeight;

  const Camera({
    super.key,
    this.maxNumberOfImages = 1,
    this.canPop,
    this.tools = const [],
    this.maxHeight,
    this.maxWidth,
  });

  @override
  CameraState createState() => CameraState();
}

class CameraState extends State<Camera> with WidgetsBindingObserver {
  CameraController? _controller;
  List? _cameras;
  late int _selectedCameraIdx;
  bool _cameraError = false;
  double? _minZoomLevel;
  double? _maxZoomLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    availableCameras().then((availableCameras) {
      _cameras = availableCameras;
      if (_cameras != null && _cameras!.isNotEmpty) {
        setState(() {
          _selectedCameraIdx = 0;
        });
        _initCameraController(_cameras![_selectedCameraIdx]).then((void v) {});
      } else {
        log("No camera available");
        setState(() {
          _cameraError = true;
        });
      }
    }).catchError((err) {
      if (err is CameraException) {
        log('Error: ${err.code}\nError Message: ${err.description}');
      } else {
        log("No camera available");
      }

      setState(() {
        _cameraError = true;
      });
    });
  }

  @override
  void didChangeMetrics() {
    setState(() {});
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(cameraDescription, ResolutionPreset.high, enableAudio: false);
    _controller?.setFlashMode(FlashMode.auto);

    try {
      await _controller?.initialize();
    } on CameraException catch (e) {
      log('Camera Error ${e.code}: ${e.description}');
    }
    try {
      _minZoomLevel = await _controller?.getMinZoomLevel();
      _maxZoomLevel = await _controller?.getMaxZoomLevel();
    } catch (e) {
      _minZoomLevel = 1;
      _maxZoomLevel = 1;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraError) {
      if (widget.canPop!) {
        Navigator.pop(context);
      } else {
        return const Center(
          child: Text("Camera Error!"),
        );
      }
    }
    if (_controller == null || !_controller!.value.isInitialized || _minZoomLevel == null || _maxZoomLevel == null) {
      return Container(
        color: Colors.black,
        child: const Center(
            child: CircularProgressIndicator(
          color: Colors.red,
        )),
      );
    }
    return CustomCameraPreview(
      maxWidth: widget.maxWidth,
      maxHeight: widget.maxHeight,
      maxNumberOfImages: widget.maxNumberOfImages,
      tools: widget.tools,
      cameraController: _controller!,
      minZoomLevel: _minZoomLevel,
      maxZoomLevel: _maxZoomLevel,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
