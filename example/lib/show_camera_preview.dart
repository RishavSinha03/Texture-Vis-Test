import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:wall_design_visualizer/wall_design_visualizer.dart';

class ShowCameraPreview extends StatefulWidget {
  final CameraDescription camera;
  final wallDesignImagePath;

  ShowCameraPreview({Key? key, required this.camera, required this.wallDesignImagePath}) : super(key: key);

  @override
  _ShowCameraPreviewState createState() => _ShowCameraPreviewState();
}

class _ShowCameraPreviewState extends State<ShowCameraPreview> {
  late CameraDescription camera;
  late CameraController _controller;

  bool processingFrame = false;

  List<Widget> listOfStackedProcessedFrames = [];
  final imageStream = StreamController<Uint8List>();

  /*int cameraImageActualWidth = 0;
  int cameraImageActualHeight = 0;*/
  double? xTap = 0.0;
  double? yTap = 0.0;
  late Size sizeOfViewport;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.low,
    );
    _controller.setFlashMode(FlashMode.off);
    _controller.initialize().then((value) => {
          _controller.startImageStream((CameraImage image) {
            /*cameraImageActualHeight = image.height;
            cameraImageActualWidth = image.width;*/
            if (!processingFrame && xTap != null) {
              processFrame(image);
              processingFrame = true;
            }
          }),
        });
  }

  processFrame(CameraImage image) {
    WallDesignVisualizer.paintWallDesign(
      image,
      widget.wallDesignImagePath,
      sizeOfViewport.height,
      sizeOfViewport.width,
      xTap!,
      yTap!,
      image.height.toDouble(),
      image.width.toDouble(),
    ).then((outputPath) {
      var bytes = File(outputPath!).readAsBytesSync();
      if (listOfStackedProcessedFrames.length > 3) {
        listOfStackedProcessedFrames.removeLast();
      }
      Future.delayed(Duration(milliseconds: 1), () {
        imageStream.sink.add(bytes);
        processingFrame = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    sizeOfViewport = MediaQuery.of(context).size;
    return StreamBuilder(
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          listOfStackedProcessedFrames.insert(
            0,
            Image.memory(
              snapshot.data! as Uint8List,
              fit: BoxFit.cover,
            ),
          );
        }
        return GestureDetector(
          onTapDown: (details) {
            /*//get tap location
            final RenderBox? box = context.findRenderObject() as RenderBox?;
            final Offset offset = box!.localToGlobal(details.globalPosition);

            //translate tap coordinates to image coordinates
            var widgetHeight = MediaQuery.of(context).size.height;
            var widgetWidth = MediaQuery.of(context).size.width;

            double xRatio = cameraImageActualWidth / widgetWidth;
            double yRatio = cameraImageActualHeight / widgetHeight;

            setState(() {
              xPos = (offset.dx.round() * xRatio).round();
              yPos = (offset.dy.round() * yRatio).round();
            });*/

            final RenderBox? box = context.findRenderObject() as RenderBox?;
            final Offset offset = box!.globalToLocal(details.globalPosition);

            // No need to scale these coordinates according to Camera Image size, it is already being done in the Android code of the wall_design_visualizer plugin.
            xTap = offset.dx;
            yTap = offset.dy;

            print("show_camera_preview.dart: xTap: $xTap, yTap: $yTap");
          },
          child: Container(
            height: sizeOfViewport.height,
            width: sizeOfViewport.width,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: listOfStackedProcessedFrames,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    imageStream.close();
    super.dispose();
  }
}
