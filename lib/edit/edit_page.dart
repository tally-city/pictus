import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pictus/crop_ratio.dart';
import 'package:pictus/edit/cropper_widget.dart';
import 'package:pictus/edit/painter_widget.dart';
import 'package:pictus/pictus.dart';

enum Status {
  loading,
  loaded,
}

enum EditMode {
  preview,
  edit,
}

class EditPage extends StatefulWidget {
  const EditPage({
    required this.image,
    this.cropRatios = const [],
    this.forceCrop = false,
    this.editModes = const [],
    super.key,
  });
  final XFile image;
  final List<CropRatio> cropRatios;
  final bool forceCrop;
  final List<PhotoEditTool> editModes;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  Status _status = Status.loaded;
  EditMode _mode = EditMode.preview;
  bool _isDirty = false;
  PhotoEditTool? _editMode;
  late XFile _image;
  final GlobalKey<CropperWidgetState> _cropWidget = GlobalKey();
  final GlobalKey<PainterWidgetState> _painterWidget = GlobalKey();

  @override
  void initState() {
    if (widget.forceCrop) {
      _mode = EditMode.edit;
      _editMode = PhotoEditTool.crop;
    }
    _image = widget.image;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty && _status == Status.loaded && _mode == EditMode.preview,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        if (_status == Status.loading) return;

        if (_mode == EditMode.edit) {
          setState(() {
            _mode = EditMode.preview;
            _editMode = null;
          });
          return;
        }

        if (_isDirty) {
          final bool shouldPop = await _showDialog() ?? false;
          if (shouldPop && context.mounted) {
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black87,
          leading: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          leadingWidth: 100,
          actions: [
            if (_isDirty || _mode == EditMode.edit)
              TextButton(
                onPressed: () {
                  switch (_mode) {
                    case EditMode.preview:
                      Navigator.pop(context, _image);
                    case EditMode.edit:
                      setState(() {
                        _status = Status.loading;
                      });
                      switch (_editMode) {
                        case PhotoEditTool.crop:
                          _cropWidget.currentState?.crop();

                        case PhotoEditTool.draw:
                          _painterWidget.currentState?.exportImage();

                        case null:
                          return;
                      }
                  }
                },
                child: Text(
                  _mode == EditMode.edit && _editMode == PhotoEditTool.crop ? 'Crop' : 'Done',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            const SizedBox(width: 10),
          ],
        ),
        backgroundColor: Colors.black87,
        // extendBodyBehindAppBar: true,
        body: (_status == Status.loading)
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder(
                future: _image.readAsBytes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      switch (_mode) {
                        case EditMode.preview:
                          return Center(
                            child: Image.memory(
                              snapshot.data!,
                              width: double.infinity,
                              // height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          );
                        case EditMode.edit:
                          switch (_editMode) {
                            case null:
                              return Container();
                            case PhotoEditTool.crop:
                              return CropperWidget(
                                bytes: snapshot.data!,
                                cropRatios: widget.cropRatios,
                                key: _cropWidget,
                                onCropped: (file) {
                                  setState(() {
                                    _status = Status.loaded;
                                    _isDirty = true;
                                    _mode = EditMode.preview;
                                    _image = file;
                                  });
                                },
                              );
                            case PhotoEditTool.draw:
                              return PainterWidget(
                                key: _painterWidget,
                                bytes: snapshot.data!,
                                onPaintFinished: (file) {
                                  if (file == null) return;
                                  setState(() {
                                    _status = Status.loaded;
                                    _isDirty = true;
                                    _mode = EditMode.preview;
                                    _image = file;
                                  });
                                },
                              );
                          }
                      }
                    }
                    return const Center(child: Text('Failed to load image'));
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
        bottomNavigationBar: _mode == EditMode.edit
            ? null
            : Container(
                height: 80,
                color: Colors.black87,
                child: _buildTools(),
              ),
      ),
    );
  }

  Widget _buildTools() {
    var tools = <Widget>[];
    switch (_mode) {
      case EditMode.preview:
        tools = [
          if (widget.editModes.contains(PhotoEditTool.crop))
            IconButton(
                onPressed: () {
                  setState(() {
                    _mode = EditMode.edit;
                    _editMode = PhotoEditTool.crop;
                  });
                },
                icon: const Icon(
                  Icons.crop,
                  color: Colors.white,
                )),
          if (!kIsWeb && widget.editModes.contains(PhotoEditTool.draw))
            IconButton(
              onPressed: () {
                setState(() {
                  _mode = EditMode.edit;
                  _editMode = PhotoEditTool.draw;
                });
              },
              icon: const Icon(
                Icons.draw,
                color: Colors.white,
              ),
            )
        ];
      case EditMode.edit:
        tools = [];
        switch (_editMode) {
          case null:
            tools = [];
          case PhotoEditTool.crop:
            tools = [];
          case PhotoEditTool.draw:
            tools = [];
        }
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: tools);
  }

  Future<bool?> _showDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Any unsaved changes will be lost!'),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes, discard my changes'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            TextButton(
              child: const Text('No, continue editing'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
  }
}
