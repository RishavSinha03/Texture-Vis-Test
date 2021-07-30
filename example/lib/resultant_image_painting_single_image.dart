import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wall_design_visualizer/wall_design_visualizer.dart';

class ResultantImage extends StatefulWidget {
  final String inputPath, wallDesignImagePath, outputPath;
  final double viewportHeight, viewportWidth, xTap, yTap;

  ResultantImage({
    Key? key,
    required this.inputPath,
    required this.wallDesignImagePath,
    required this.outputPath,
    required this.viewportHeight,
    required this.viewportWidth,
    required this.xTap,
    required this.yTap,
  }) : super(key: key);

  @override
  _ResultantImageState createState() => _ResultantImageState();
}

class _ResultantImageState extends State<ResultantImage> {
  Future<String?>? futureResult;

  @override
  void initState() {
    futureResult = WallDesignVisualizer.paintWallDesignSingleImage(
        widget.inputPath, widget.wallDesignImagePath, widget.viewportHeight, widget.viewportWidth, widget.xTap, widget.yTap, widget.outputPath);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: futureResult,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
            return Image.file(File(snapshot.data.toString()));
          } else {
            return CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            );
          }
        },
      ),
    );
  }
}
