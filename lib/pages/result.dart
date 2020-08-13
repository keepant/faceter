import 'dart:io';
import 'dart:ui' as ui;
import 'package:faceter/pages/home.dart';
import 'package:faceter/utils/utils.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as imglib;

class Result extends StatefulWidget {
  final String imagePath;

  Result({
    Key key,
    this.imagePath,
  }) : super(key: key);

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {
  SharedPreferences sharedPreferences;
  String _userId;

  List<Face> _faces;
  bool isLoading = false;
  ui.Image _image;
  File jsonFile;
  var interpreter;
  dynamic data = {};
  double threshold = 1.0;
  Directory tempDir;
  List e1;

  _getUserId() async {
    sharedPreferences = await SharedPreferences.getInstance();
    setState(() {
      _userId = (sharedPreferences.getString("userId") ?? '');
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserId();
    _getImageAndDetectFaces();
    loadModel();
  }

  _getImageAndDetectFaces() async {
    final image = FirebaseVisionImage.fromFile(File(widget.imagePath));
    final faceDetector = FirebaseVision.instance.faceDetector();
    List<Face> faces = await faceDetector.processImage(image);
    if (mounted) {
      setState(() {
        _faces = faces;
        _loadImage(File(widget.imagePath));
      });
    }
  }

  _loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
      (value) => setState(() {
        _image = value;
        isLoading = false;
      }),
    );
  }

  Future loadModel() async {
    try {
      interpreter = await tfl.Interpreter.fromAsset('mobilefacenet.tflite');
    } on Exception {
      print('Failed to load model.');
    }
  }

  String _recog(imglib.Image img) {
    List input = imageToByteListFloat32(img, 112, 128, 128);
    input = input.reshape([1, 112, 112, 3]);
    List output = List(1 * 192).reshape([1, 192]);
    interpreter.run(input, output);
    output = output.reshape([192]);
    e1 = List.from(output);
    return compare(e1).toUpperCase();
  }

  String compare(List currEmb) {
    if (data.length == 0) return "No Face saved";
    double minDist = 999;
    double currDist = 0.0;
    String predRes = "NOT RECOGNIZED";
    for (String label in data.keys) {
      currDist = euclideanDistance(data[label], currEmb);
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        predRes = label;
      }
    }
    print(minDist.toString() + " " + predRes);
    if (predRes == _userId) {
      predRes = 'Sudah Terdaftar';
    }
    return predRes;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        color: Color(0xfff1eefc),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 25.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GestureDetector(
                      child: Icon(Icons.arrow_back_ios, size: 20.0),
                      onTap: () {
                        Get.to(Home());
                      },
                    ),
                    Text(
                      "Result",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor),
                    ),
                    Icon(Icons.arrow_back_ios,
                        size: 20.0, color: Color(0xfff1eefc)),
                  ],
                ),
              ),
              Container(
                width: size.width - 50.0,
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                decoration: BoxDecoration(
                    color: Color(0xffffffff),
                    borderRadius: BorderRadius.circular(10.0)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: size.width - 90.0,
                      padding:
                          EdgeInsets.symmetric(horizontal: 1.0, vertical: 1.0),
                      child: isLoading || _image == null
                          ? Center(
                              child: CircularProgressIndicator(),
                            )
                          : Center(
                              child: FittedBox(
                                fit: BoxFit.fitWidth,
                                child: SizedBox(
                                  width: _image.height.toDouble(),
                                  height: _image.height.toDouble(),
                                  child: CustomPaint(
                                    painter: FacePainter(_image, _faces),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    GestureDetector(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                        margin: EdgeInsets.only(top: 30.0),
                        width: size.width - 90.0,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(180.0),
                        ),
                        child: Text(
                          'Save',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffffffff),
                          ),
                        ),
                      ),
                      onTap: () async {

                        Get.off(Home());
                        print('Success add');
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final ui.Image image;
  final List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(this.image, this.faces) {
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15.0
      ..color = Colors.yellow;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}
