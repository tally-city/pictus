import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pictus/pictus.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  List<XFile> images = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pictus Example'),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            label: const Text('Gallery'),
            onPressed: () async {
              Pictus.pickImage(
                context,
                maxHeight: 1000,
                maxWidth: 1000,
                source: ImageSource.gallery,
                tools: [PhotoEditTool.crop, PhotoEditTool.draw],
                forceCrop: true,
                maxNumberOfImages: 4,
              ).then((value) {
                setState(() {
                  if (value != null) images = value;
                });
              });
            },
            icon: const Icon(Icons.image),
          ),
          if (kIsWeb || Platform.isAndroid || Platform.isIOS)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: FloatingActionButton.extended(
                label: const Text('Camera'),
                onPressed: () {
                  Pictus.pickImage(
                    context,
                    source: ImageSource.camera,
                    maxNumberOfImages: 4,
                    tools: [PhotoEditTool.crop, PhotoEditTool.draw],
                    defaultLensDirection: LensDirection.front,
                  ).then((value) {
                    setState(() {
                      if (value != null) images = value;
                    });
                  });
                },
                icon: const Icon(Icons.camera_alt),
              ),
            ),
        ],
      ),
      body: Center(
        child: images.isEmpty
            ? const Text('please pick some images')
            : Column(
                children: [
                  const Text('picked images:'),
                  ...images.map(
                    (e) => FutureBuilder(
                      future: e.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.data == null) return const CircularProgressIndicator();
                        return Image.memory(
                          snapshot.data!,
                          width: 100,
                          height: 100,
                        );
                      },
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
