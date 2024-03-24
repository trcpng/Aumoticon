import 'dart:async';
import 'dart:convert';
import 'dart:developer' as log;
import 'dart:io';
import 'dart:math';
import 'package:aumoticon/homepage.dart';
import 'package:flutter_audio_recorder2/flutter_audio_recorder2.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'speech_db.dart';

class EmotionAnalysis extends StatefulWidget {
  const EmotionAnalysis({super.key});

  @override
  State<EmotionAnalysis> createState() => _EmotionAnalysisState();
}

class _EmotionAnalysisState extends State<EmotionAnalysis> {
  String pathGot = '';
  var recorder = FlutterAudioRecorder2('', audioFormat: AudioFormat.WAV);
  String result = '';
  String? emoticonImagePath;
  String backgroundImagePath = 'assets/Home/home.png';
  bool isRecording = false;


  getResponse(String path) async {
    print('============get Response was called=============');
    try {
      var pos = path.split('/');
      print("File name is ${pos.last}");
      var request = http.MultipartRequest(
          'POST', Uri.parse('http://192.168.43.113:8080/analyze_emotion'));
      var multiPartData = http.MultipartFile.fromPath(
        'file',
        path,
        filename: pos.first,
      );
      request.files.add(await multiPartData);

      http.StreamedResponse response = await request.send();
      print('************Response is about to test**********');
      if (response.statusCode == 200) {
        print("==========Status code is 200========");
        try {
          final extractedData =
              json.decode(await response.stream.bytesToString());
          print(extractedData);
          result = extractedData['predicted_emotion'].toString();
          setState(() {
            if (result != null && result.isNotEmpty) {
              var predictionClass = result;
              result = predictionClass;

              if (classToEmoticonMap.containsKey(predictionClass)) {
                emoticonImagePath = classToEmoticonMap[predictionClass];
              } else {
                emoticonImagePath = 'assets/Emojis/unknown.png';
              }

              if (!emotionToBackgroundImagePath
                  .containsKey(predictionClass)) {
                backgroundImagePath = 'assets/Home/home.png';
              } else {
                backgroundImagePath =
                    emotionToBackgroundImagePath[predictionClass]!;
              }
            } else {
              result = 'Unknown';
            }
          });
          print('emotion was obtaining-----01');
          print("Emotion status is ${extractedData['predicted_emotion'].toString()}");
          print('emotion was obtained-----02');
        } catch (e) {
          print('Exception :( ${e}');
        }
      } else {
        print("======Error is printing====");
        print(response.reasonPhrase.toString());
        print("=========Completed with error=======");
      }
    } catch (e) {
      print(e.runtimeType);
    }
  }

  @override
  void initState() {
    initializaeRecord();
    super.initState();
  }

  initializaeRecord() async {
    Directory? extDir = await getExternalStorageDirectory();
    var rng = Random();
    setState(() {
      pathGot = "${extDir!.path}/${rng.nextInt(1000)}";
      recorder = FlutterAudioRecorder2(pathGot, audioFormat: AudioFormat.WAV);
    });
    if (!(await Permission.microphone.isGranted)) {
      await Permission.microphone.request();
    }
    await recorder.initialized;
  }

  @override
  Widget build(BuildContext context) {
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
                    offset: Offset(0, 4),
                  )
                ],
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
                        'Emotion: ${result == 'Calm' ? 'Neutral' : result == 'Surprised' ? 'Happy' : result == 'Disgust' ? 'Angry' : result}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Arial',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _getEmotionIntervention(result),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Arial',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.transparent,
              ),
              child: IconButton(
                onPressed: () {
                  setState(() {
                    if (isRecording == true) {
                      stopRecording();
                      print('Recording Stopped!');
                      isRecording = false;
                    } else {
                      startRecording();
                      print('Recording started...');
                      isRecording = true;
                    }
                  });
                },
                icon: Icon(
                  Icons.mic,
                  color: isRecording ? Colors.red : Colors.black,
                  size: 65.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await SpeechDBHelper.saveEmotion(result);
                    print('Emotion saved to the database: $result');
                    showSavedEmotions();
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFA3D4CC),
                    minimumSize: const Size(150, 50),
                    maximumSize: const Size(200, 60),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    showPredictedEmotionsDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFFA3D4CC),
                    minimumSize: const Size(150, 50),
                    maximumSize: const Size(200, 60),
                  ),
                  child: const Text(
                    'History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startRecording() async {
    print('Recorder was started======');
    await recorder.start();
  }

  Future<String?> stopRecording() async {
    var result = await recorder.stop();
    log.log(result!.path!);
    print('Recording was stopped & path is======== ${result.path}');
    getResponse(result.path!);
  }


 Future<void> showPredictedEmotionsDialog(BuildContext context) async {
  List<String> savedEmotions = await SpeechDBHelper.getSavedEmotions();

  savedEmotions = savedEmotions.reversed.toList();

  // ignore: use_build_context_synchronously
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Predicted Emotions History'),
        content: SingleChildScrollView(
          child: Column(
            children: savedEmotions.map((emotion) {
              String alteredEmotion = alterPredictedEmotion(emotion);
              String emojiPath = getEmojisAsset(alteredEmotion);

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (emojiPath.isNotEmpty)
                          Image.asset(
                            emojiPath,
                            width: 30,
                            height: 30,
                          ),
                        if (emojiPath.isEmpty)
                          const Text(
                            'Unknown',
                            style: TextStyle(fontSize: 16),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('- $alteredEmotion'),
                ],
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

String getEmojisAsset(String emotion) {
  switch (emotion.toLowerCase()) {
    case 'happy':
      return 'assets/Emojis/emohappy.png';
    case 'sad':
      return 'assets/Emojis/emosad.png';
    case 'angry':
      return 'assets/Emojis/emoangry.png';
    case 'fearful':
      return 'assets/Emojis/emoafraid.png';
    case 'neutral':
      return 'assets/Emojis/emoneutral.png';
    case 'surprised':
      return 'assets/Emojis/emohappy.png';
    case 'calm':
      return 'assets/Emojis/emoneutral.png';
    case 'disgust':
      return 'assets/Emojis/emoangry.png';
    default:
      return '';
  }
}

String alterPredictedEmotion(String emotion) {
  switch (emotion.toLowerCase()) {
    case 'disgust':
      return 'angry';
    case 'calm':
      return 'neutral';
    case 'surprised':
      return 'happy';
    default:
      return emotion;
  }
}

  String _getEmotionIntervention(String? emotion) {
    switch (emotion) {
      case 'Happy':
        return '-Smile back!\n-Be happy for them, too';
      case 'Sad':
        return '-Comfort the person\n-Make them smile';
      case 'Angry':
        return '-Stay calm\n-Give them space';
      case 'Neutral':
        return '-Be friendly\n-Talk nicely';
      case 'Fearful':
        return '-Stay by their side\n-Have a small talk';
      case 'Calm':
        return '-Be friendly\n-Talk nicely';
      case 'Disgust':
        return '-Stay calm\n-Give them space';
      case 'Surprised':
        return '-Smile back!\n-Be happy for them, too';

      default:
        return '';
    }
  }

  static const Map<String, String> classToEmoticonMap = {
    'Angry': 'assets/Emojis/emoangry.png',
    'Fearful': 'assets/Emojis/emoafraid.png',
    'Happy': 'assets/Emojis/emohappy.png',
    'Neutral': 'assets/Emojis/emoneutral.png',
    'Sad': 'assets/Emojis/emosad.png',
    'Disgust': 'assets/Emojis/emoangry.png',
    'Surprised': 'assets/Emojis/emohappy.png',
    'Calm': 'assets/Emojis/emoneutral.png',
  };

  static const Map<String, String> emotionToBackgroundImagePath = {
    'Angry': 'assets/Results BG/bganger.png',
    'Fearful': 'assets/Results BG/bgfear.png',
    'Happy': 'assets/Results BG/bghappy.png',
    'Neutral': 'assets/Results BG/bgneutral.png',
    'Sad': 'assets/Results BG/bgsad.png',
    'Disgust': 'assets/Results BG/bganger.png',
    'Surprised': 'assets/Results BG/bghappy.png',
    'Calm': 'assets/Results BG/bgneutral.png',
  };

  Future<void> showSavedEmotions() async {
  List<String> savedEmotions = await SpeechDBHelper.getSavedEmotions();

  print('Saved Emotions:');
  for (String emotion in savedEmotions) {
    print('- $emotion');
  }

  // ignore: use_build_context_synchronously
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Saved!'),
      duration: Duration(seconds: 2),
    ),
  );
}

}