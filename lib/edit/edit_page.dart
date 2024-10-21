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
  CropRatio? _cropRatio;
  late XFile _image;
  final GlobalKey<CropperWidgetState> _cropWidget = GlobalKey();
  final GlobalKey<PainterWidgetState> _painterWidget = GlobalKey();

  @override
  void initState() {
    if (widget.cropRatios.isEmpty) {
      _cropRatio = CropRatio.free;
    } else if (widget.cropRatios.length < CropRatio.values.length) {
      _cropRatio = widget.cropRatios.first;
    }
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
            child: Text(
              _mode == EditMode.preview ? 'Cancel' : 'Discard',
              style: const TextStyle(
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
                  _mode == EditMode.preview ? 'Done' : 'Save',
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
                                cropRatio: _cropRatio,
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
        bottomNavigationBar: _editMode == PhotoEditTool.draw
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
        switch (_editMode) {
          case null:
            tools = [];
          case PhotoEditTool.crop:
            // if we only have one crop ratio, we force the user to crop in that ratio
            final values = widget.cropRatios.length <= 1
                ? widget.cropRatios.isEmpty
                    ? CropRatio.values
                    : []
                : widget.cropRatios;
            tools = values
                .map(
                  (ratio) => TextButton(
                    onPressed: () {
                      setState(() {
                        _cropRatio = ratio;
                      });
                    },
                    child: Column(
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
