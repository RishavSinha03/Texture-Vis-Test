import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wall_design_visualizer/wall_design_visualizer.dart';
import 'package:wall_design_visualizer_example/visualize_wall_design.dart';

void main() {
  runApp(MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  File? pickedImageFile;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await WallDesignVisualizer.platformVersion ?? 'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future getImage(ImageSource imageSource) async {
    final pickedFile = await picker.pickImage(source: imageSource);

    setState(() {
      if (pickedFile != null) {
        pickedImageFile = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Running on: $_platformVersion\n'),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: Text("Choose a source"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            getImage(ImageSource.gallery);
                            Navigator.pop(dialogContext);
                          },
                          child: Text("Gallery"),
                        ),
                        TextButton(
                          onPressed: () {
                            getImage(ImageSource.camera);
                            Navigator.pop(dialogContext);
                          },
                          child: Text("Camera"),
                        ),
                      ],
                    );
                  },
                ).then((value) {
                  if (pickedImageFile != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => VisualizeWallDesign(wallDesignImagePath: pickedImageFile!.path)));
                  }
                });
              },
              child: Text("Start"),
            )
          ],
        ),
      ),
    );
  }
}
