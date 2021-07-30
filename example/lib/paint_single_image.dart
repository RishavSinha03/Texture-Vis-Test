import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wall_design_visualizer_example/resultant_image_painting_single_image.dart';

class PaintSingleImage extends StatefulWidget {
  final String wallDesignImagePath;

  PaintSingleImage({Key? key, required this.wallDesignImagePath}) : super(key: key);

  @override
  _PaintSingleImageState createState() => _PaintSingleImageState();
}

class _PaintSingleImageState extends State<PaintSingleImage> {
  File? pickedImageFile;
  final picker = ImagePicker();

  double? xTap;
  double? yTap;

  bool waiting = false;

  Future<File?> getImage(ImageSource imageSource) async {
    final pickedFile = await picker.pickImage(source: imageSource);

    setState(() {
      if (pickedFile != null) {
        pickedImageFile = File(pickedFile.path);
        print("paint_single_image.dart: image picked $pickedImageFile");
      } else {
        print('No image selected.');
      }
    });

    return pickedImageFile;
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var screenWidth = MediaQuery.of(context).size.width;
    return ModalProgressHUD(
      inAsyncCall: waiting,
      progressIndicator: Text(
        "Processing...",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
      ),
      child: Scaffold(
        body: Column(
          children: [
            pickedImageFile == null
                ? Center(
                    child: Text("No Image selected."),
                  )
                : GestureDetector(
                    onTapDown: (details) async {
                      setState(() {
                        waiting = true;
                      });
                      final RenderBox? box = context.findRenderObject() as RenderBox?;
                      final Offset offset = box!.globalToLocal(details.globalPosition);

                      // No need to scale these coordinates according, it is already being done in the Android code of the wall_design_visualizer plugin.
                      xTap = offset.dx;
                      yTap = offset.dy;

                      print("paint_single_image.dart: xTap: $xTap, yTap: $yTap");

                      var outputDir = await getTemporaryDirectory();

                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ResultantImage(
                                  inputPath: pickedImageFile!.path,
                                  wallDesignImagePath: widget.wallDesignImagePath,
                                  outputPath: outputDir.path + "resultImage.png",
                                  viewportHeight: screenHeight * 0.8,
                                  viewportWidth: screenWidth,
                                  xTap: xTap!,
                                  yTap: yTap!)));
                    },
                    child: Container(
                      height: screenHeight * 0.8,
                      width: screenWidth,
                      child: Image.file(
                        pickedImageFile!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
            Container(
              margin: EdgeInsets.all(20),
              child: TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        title: Text("Choose source"),
                        actions: [
                          TextButton(
                            onPressed: () {
                              var file = getImage(ImageSource.gallery);
                              Navigator.pop(dialogContext, file);
                            },
                            child: Text("Gallery"),
                          ),
                          TextButton(
                            onPressed: () {
                              var file = getImage(ImageSource.camera);
                              Navigator.pop(dialogContext, file);
                            },
                            child: Text("Camera"),
                          ),
                        ],
                      );
                    },
                  ).then((value) {
                    Fluttertoast.showToast(
                        msg: "Tap on image",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 1,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: 16.0);
                  });
                },
                child: Text(
                  "Choose an image to paint over",
                ),
                style: ButtonStyle(backgroundColor: MaterialStateProperty.resolveWith((states) => Colors.cyan)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
