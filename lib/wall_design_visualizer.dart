import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WallDesignVisualizer {
  static const MethodChannel _channel = const MethodChannel('wall_design_visualizer');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// Returns the path of the image with the Wall Design applied.
  static Future<String?> paintWallDesign(
    CameraImage cameraImage,
    String wallDesignImagePath,
    double viewportHeight,
    double viewportWidth,
    double xTap,
    double yTap,
    double cameraImageHeight,
    double cameraImageWidth,
  ) async {
    final String? outputImagePath = await _channel.invokeMethod(
      "paintWallDesign",
      {
        "Uint8List bytes for plane 0": cameraImage.planes[0].bytes,
        "Uint8List bytes for plane 1": cameraImage.planes[1].bytes,
        "Uint8List bytes for plane 2": cameraImage.planes[2].bytes,
        "wallDesignImagePath": wallDesignImagePath,
        "viewportHeight": viewportHeight,
        "viewportWidth": viewportWidth,
        "xTap": xTap,
        "yTap": yTap,
        "cameraImageHeight": cameraImageHeight,
        "cameraImageWidth": cameraImageWidth,
      },
    );

    return outputImagePath;
  }
}

// CameraImage bytes are sent to android for each plane (0,1,2) -> Android takes the bytes and converts the YUV420 to bitmap format and processes it -> android saves the resulting image to a path and sends back the path to flutter.
