import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wall_design_visualizer_example/show_camera_preview.dart';

class VisualizeWallDesign extends StatefulWidget {
  final String wallDesignImagePath;
  VisualizeWallDesign({Key? key, required this.wallDesignImagePath}) : super(key: key);

  @override
  _VisualizeWallDesignState createState() => _VisualizeWallDesignState();
}

class _VisualizeWallDesignState extends State<VisualizeWallDesign> {
  late Future<CameraDescription> _getCameraDescription;

  @override
  void initState() {
    _getCameraDescription = getAvailableCameras();
    super.initState();
  }

  Future<CameraDescription> getAvailableCameras() async {
    final cameras = await availableCameras();
    return cameras.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Visualize Wall Design"),
      ),
      body: FutureBuilder(
        future: _getCameraDescription,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            return Center(
              child: ShowCameraPreview(
                camera: snapshot.data,
                wallDesignImagePath: widget.wallDesignImagePath,
              ),
            );
          } else {
            return Center(
                child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
            ));
          }
        },
      ),
    );
  }
}
