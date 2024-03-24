import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:aumoticon/homepage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:aumoticon/displayImage.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? cameraController;
  List<CameraDescription>? cameras;
  bool isCameraReady = false;
  String? prediction = '';
  String? emoticonImagePath;
  String backgroundImagePath = 'assets/backgrounds/default.png';
  Timer? _timer;
  bool snapshotTaken = false;

  int cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    await Permission.camera.request();
    cameras = await availableCameras();
    cameraController = CameraController(cameras![cameraIndex], ResolutionPreset.medium);

    await cameraController!.initialize();

    try {
      await cameraController!.setFlashMode(FlashMode.off);
    } catch (e) {
      // ignore: avoid_print
      print('Flash is not supported.');
    }

    if (!mounted) return;

    setState(() {
      isCameraReady = true;
    });

    loadModel();
    startPeriodicClassification();
  }

  Future<void> loadModel() async {
    try {
      await Tflite.loadModel(
        // model: 'assets/model.tflite',
        model: 'assets/model.tflite',
        labels: 'assets/labels.txt',
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error loading model: $e');
    }
  }

  void startPeriodicClassification() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      classifyFrame();
    });
  }

  void classifyFrame() async {
    if (!isCameraReady) return;

    try {
      var image = await cameraController!.takePicture();
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 5,
        threshold: 0.3,
      );

      setState(() {
        if (recognitions != null && recognitions.isNotEmpty) {
          var predictionClass = recognitions[0]['label'];
          prediction = predictionClass;

          // Update emoticon and background images
          if (classToEmoticonMap.containsKey(predictionClass)) {
            emoticonImagePath = classToEmoticonMap[predictionClass];
          } else {
            emoticonImagePath = 'assets/Emojis/unknown.png';
          }

          if (!emotionToBackgroundImagePath.containsKey(predictionClass)) {
            backgroundImagePath = 'assets/backgrounds/default.png';
          } else {
            backgroundImagePath = emotionToBackgroundImagePath[predictionClass]!;
          }
        } else {
          prediction = 'Unknown';
        }
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error running model: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    cameraController?.dispose();
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isCameraReady) {
      return Container();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Aumoticon',
          style: TextStyle(
            fontFamily: 'Roboto-Bold',
            fontSize: 24,
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 0, 0)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/Home/home.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home, size: 30),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
            );
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Home/home.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Stack(
                children: [
                  CameraPreview(cameraController!),
                  Align(
  alignment: Alignment.bottomCenter,
  child: Container(
    margin: const EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.flip_camera_android),
          iconSize: 30,
          color: Colors.white,
          onPressed: switchCamera, // Switch camera when button is pressed
        ),
      GestureDetector(
  onTap: takeSnapshot,
  child: Icon(Icons.camera, size: 30, color: Colors.white),
),
      ],
    ),
  ),
),
                Center(
                  child: Container(
                    width: 200,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green, // Green border color
                        width: 2.0, // Border width
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
            Container(
              width: 250,
              height: 160,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(backgroundImagePath),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 10,
                    offset: Offset(0,4)
                  )
                ]
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (emoticonImagePath != null)
                        Image.asset(
                          emoticonImagePath!,
                          width: 55,
                          height: 55,
                        ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Emotion: $prediction',
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Arial',
                        ),
                      ),

                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getEmotionIntervention(prediction),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Arial',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

Future<void> takeSnapshot() async {
  try {
    // Ensure that the camera is ready
    if (!isCameraReady) return;

    // Capture the image using the camera controller
    var image = await cameraController!.takePicture();

    // Perform actions with the real-time predicted emotion
    print('Snapshot taken with real-time predicted emotion: $prediction');

    // You can use the predicted emotion for further processing or display

    // Update the UI with the captured image and predicted emotion
    classifySnapshot(image.path);

    // Set the snapshotTaken variable to true
    setState(() {
      snapshotTaken = true;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisplaySnapshotScreen(
          imagePath: image.path,
          predictedEmotion: prediction!,
        ),
      ),
    );
  } catch (e) {
    print('Error taking snapshot: $e');
  }
}

void classifySnapshot(String imagePath) async {
  try {
    var recognitions = await Tflite.runModelOnImage(
      path: imagePath,
      numResults: 5,
      threshold: 0.3,
    );

    setState(() {
      if (recognitions != null && recognitions.isNotEmpty) {
        var predictionClass = recognitions[0]['label'];
        prediction = predictionClass;

        // Update emoticon and background images based on the predicted emotion
        if (classToEmoticonMap.containsKey(predictionClass)) {
          emoticonImagePath = classToEmoticonMap[predictionClass];
        } else {
          emoticonImagePath = 'assets/Emojis/unknown.png';
        }

        if (!emotionToBackgroundImagePath.containsKey(predictionClass)) {
          backgroundImagePath = 'assets/backgrounds/default.png';
        } else {
          backgroundImagePath = emotionToBackgroundImagePath[predictionClass]!;
        }
      } else {
        prediction = 'Unknown';
      }
    });
  } catch (e) {
    print('Error running model on snapshot: $e');
  }
}

  void switchCamera() async {
    if (cameras!.isEmpty) return;

    await cameraController!.dispose();

    cameraIndex = (cameraIndex + 1) % cameras!.length;
    cameraController = CameraController(cameras![cameraIndex], ResolutionPreset.medium);

    await cameraController!.initialize();

    setState(() {});
  }

  String _getEmotionIntervention(String? emotion) {
    // Display the text-based interventions according to the emotion predicted
    switch (emotion) {
      case 'Happy':
        return '-Smile back!\n-Be happy for them, too';
      case 'Sad':
        return '-Comfort the person\n-Make them smile';
      case 'Angry':
        return '-Stay calm\n-Give them space';
      case 'Neutral':
        return '-Stay calm\n-Talk nicely';
      case 'Fearful':
        return '-Stay with them\n-Talk to them';
      default:
        return '';
    }
  }
}

// Calling the emoticons
Map<String, String> classToEmoticonMap = {
  'Angry': 'assets/Emojis/emoangry.png',
  'Fearful': 'assets/Emojis/emoafraid.png',
  'Happy': 'assets/Emojis/emohappy.png',
  'Neutral': 'assets/Emojis/emoneutral.png',
  'Sad': 'assets/Emojis/emosad.png'
};

// Calling the emotion backgrounds
Map<String, String> emotionToBackgroundImagePath = {
  'Angry': 'assets/Results BG/bganger.png',
  'Fearful': 'assets/Results BG/bgfear.png',
  'Happy': 'assets/Results BG/bghappy.png',
  'Neutral': 'assets/Results BG/bgneutral.png',
  'Sad': 'assets/Results BG/bgsad.png',
};

Future<void> captureImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null) {
        // Perform actions with the captured image
        print('Image captured: ${image.path}');

        // You may want to process or display the captured image
      }
    } catch (e) {
      print('Error capturing image: $e');
    }
  }
