library pictus;

import 'dart:developer';

import 'package:pictus/camera/custom_camera_preview.dart';
import 'package:pictus/crop_ratio.dart';
import 'package:pictus/lens_direction.dart';
import 'package:pictus/photo_edit_tool.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

class Camera extends StatefulWidget {
  final int maxNumberOfImages;
  final List<PhotoEditTool> tools;
  final bool forceCrop;
  final List<CropRatio> cropRatios;
  final int? maxWidth;
  final int? maxHeight;
  final LensDirection defaultLensDirection;

  const Camera({
    super.key,
    this.maxNumberOfImages = 1,
    this.tools = const [],
    this.maxHeight,
    this.maxWidth,
    this.cropRatios = const [],
    this.forceCrop = false,
    this.defaultLensDirection = LensDirection.back,
  });

  @override
  CameraState createState() => CameraState();
}

class CameraState extends State<Camera> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  late int _selectedCameraIdx;
  String? _cameraError;
  double? _minZoomLevel;
  double? _maxZoomLevel;

  @override
  void initState() {
    super.initState();

    availableCameras().then((availableCameras) {
      _cameras = availableCameras;
      if (_cameras != null && _cameras!.isNotEmpty) {
        if (availableCameras.length == 1) {
          _selectedCameraIdx = 0;
        } else {
          setState(() {
            _selectedCameraIdx = availableCameras.indexWhere(
              (description) {
                switch (widget.defaultLensDirection) {
                  case LensDirection.front:
                    return description.lensDirection == CameraLensDirection.front;
                  case LensDirection.back:
                    return description.lensDirection == CameraLensDirection.back;
                }
              },
            );
          });
        }
        _initCameraController(_cameras![_selectedCameraIdx]).then((void v) {});
      } else {
        log('No camera available');
        setState(() {
          _cameraError = 'No camera available';
        });
      }
    }).catchError((err) {
      String errorMsg = 'No camera available';
      if (err is CameraException) {
        if (err.description != null) errorMsg = err.description!;
        log('Error: ${err.code}\nError Message: ${err.description}');
      } else {
        log(errorMsg);
      }

      setState(() {
        _cameraError = errorMsg;
      });
    });
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(
      cameraDescription,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _controller?.setFlashMode(FlashMode.auto);

    try {
      await _controller?.initialize();
    } on CameraException catch (e) {
      log('Camera Error ${e.code}: ${e.description}');
      setState(() {
        _cameraError = e.description ?? "Camera Error";
      });
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
    if (_cameraError != null) {
      final navigator = Navigator.maybeOf(context);
      if (navigator != null) {
        navigator.pop();
      } else {
        return const Center(
          child: Text("Camera Error!"),
        );
      }
    }
    if (_controller == null || !_controller!.value.isInitialized || _minZoomLevel == null || _maxZoomLevel == null) {
      return Container(
        color: Colors.black87,
        child: const Center(
            child: CircularProgressIndicator(
          color: Colors.red,
        )),
      );
    }
    return CustomCameraPreview(
      cameraIndex: _selectedCameraIdx,
      forceCrop: widget.forceCrop,
      cameras: _cameras!,
      cropRatios: widget.cropRatios,
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
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
