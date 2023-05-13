import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const CameraWidget(),
    );
  }
}

class CameraWidget extends StatefulWidget {
  const CameraWidget({Key? key}) : super(key: key);

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  late CameraController controller;
  List<CameraDescription> _cameras = [];

  @override
  void didChangeDependencies() async {
    _cameras = await availableCameras();

    controller = CameraController(_cameras[0], ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
    super.didChangeDependencies();
  }

  XFile? xfile;
  File? file;
  File? cropedFile;


  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.scale(
              scale: 0.85,
              child: Container(
                width: 290,
                height: 50,
                child: ClipRect(
                    child: OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height /
                              controller.value.aspectRatio,
                          child: AspectRatio(
                            aspectRatio: controller.value.aspectRatio,
                            child: CameraPreview(controller),
                          ))),
                )),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  xfile = await controller.takePicture();

                  file = File(xfile!.path);
                  cropedFile = await reSizeImage();
                  setState(() {});
                },
                child: Text("Take Pic")),
            cropedFile != null
                ? Container(
                    width: 300,
                    height: 300,
                    child: Image.file(cropedFile!),
                  )
                : const SizedBox()
          ],
        ));
  }

  Widget _buildCameraPreview() {
    return Container(
      color: Colors.black,
      child: Transform.scale(
        scale: _getImageZoom(MediaQuery.of(context)),
        child: Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  double _getImageZoom(MediaQueryData data) {
    final double logicalWidth = data.size.width;
    final double logicalHeight = 1.7 * logicalWidth;

    final EdgeInsets padding = data.padding;
    final double maxLogicalHeight =
        data.size.height - padding.top - padding.bottom;

    return maxLogicalHeight / logicalHeight;
  }

  Future reSizeImage() async {
    // final File imageFile = File('$path/path.jpg');
    // final List<int> imageBytes = await imageFile.readAsBytes();
    final img.Image? image =
        img.decodeImage(Uint8List.fromList(file!.readAsBytesSync()));

    final double desiredAspectRatio =7;

    final int imageWidth = image!.width;
    final int imageHeight = image.height;
    final double imageAspectRatio = imageWidth / imageHeight;
    int x, y, width, height;

    print("test");
    // crop the image horizontally
    // width = (imageHeight * desiredAspectRatio).round();
    // height = imageHeight;
    // x = ((imageWidth - width) / 2).round();
    // print(x);
    // y = 0;
    // crop the image vertically
    width = imageWidth;
    height = (imageHeight / desiredAspectRatio).round();
    print(height);
    x = 0;
    y = ((imageHeight - height) / 2).round();
    print(y);

    final img.Image croppedImage =
        img.copyCrop(image, x: x, y: y, width: width, height: height);

    final File croppedImageFile = File('${file!.path}');
    cropedFile = await croppedImageFile.writeAsBytes(img.encodePng(croppedImage));
    return cropedFile;

    // File f = File("$path/path.jpg");
    // List<int> bytes = f.readAsBytesSync();
    // img.Image? image = img.decodeImage(Uint8List.fromList(bytes));
    // List<int> trimRect = img.findTrim(image!, mode: img.TrimMode.transparent);
    // img.Image trimmed = img.copyCrop(image,
    //     height: trimRect[2],
    //     width: trimRect[3],
    //     x: trimRect[0],
    //     y: trimRect[1]);
    // print(trimmed.getBytes());
    // String name = f.path.split(RegExp(r'(/|\\)')).last;
    // File('$path/trimmed-fds.jpg')
    //     .writeAsBytesSync(img.encodeNamedImage(f.path, image)!.toList());
//trimRect[0], trimRect[1], trimRect[2], trimRect[3]
    // final cmd = img.Command()
    //   ..decodeImageFile("$path/path.jpg")
    //   ..copyResize(width: 300, height: 100)
    //   ..writeToFile("$path/path.jpg");
    // await cmd.executeThread();
    //
  }
}
