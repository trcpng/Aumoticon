import 'package:flutter/material.dart';
import 'dart:io';
import 'database_helper.dart';

class DisplaySnapshotScreen extends StatelessWidget {
  final String imagePath;
  final String predictedEmotion;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  DisplaySnapshotScreen({
    required this.imagePath,
    required this.predictedEmotion,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, String> emotionToBackground = {
      'Happy': 'assets/Results BG/bghappy.png',
      'Sad': 'assets/Results BG/bgsad.png',
      'Angry': 'assets/Results BG/bganger.png',
      'Neutral': 'assets/Results BG/bgneutral.png',
      'Fearful': 'assets/Results BG/bgfear.png',
    };

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Captured Image'),
        backgroundColor: const Color(0xFFF4E4B4),
      ),
      body: Builder(
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Home/home.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 380,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 160,
                      child: Card(
                        elevation: 10,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: AssetImage(
                                emotionToBackground[predictedEmotion] ?? 'assets/Results BG/default.png',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    getEmojiPath(predictedEmotion),
                                    width: 55,
                                    height: 55,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Emotion: $predictedEmotion',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontFamily: 'Arial',
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _getEmotionIntervention(predictedEmotion),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Arial',
                                  color: Color.fromARGB(255, 0, 0, 0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _saveToDatabase(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA3D4CC),
                        minimumSize: const Size(150, 50),
                        maximumSize: const Size(200, 60),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showHistoryDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: const Color(0xFFA3D4CC),
                        minimumSize: const Size(150, 50),
                        maximumSize: const Size(200, 60),
                      ),
                      child: const Text(
                        'History',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getEmotionIntervention(String emotion) {
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

  void _saveToDatabase(BuildContext context) async {
    try {
      String prediction = predictedEmotion;
      double confidence = 0.0;
      DateTime captureTime = DateTime.now();

      int? result = await DBHelper.saveResult(
        prediction: prediction,
        imagePath: imagePath,
        captureTime: captureTime,
        synced: false,
      );

      if (result != -1) {
        // Show a SnackBar notification when data is saved successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved!'),
            duration: Duration(seconds: 2),
          ),
        );

        print('Data saved to the database!');
      } else {
        print('Failed to save data to the database.');
      }
    } catch (e) {
      print('Error saving to the database: $e');
    }
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Saved History'),
          content: Container(
            width: double.maxFinite,
            child: FutureBuilder(
              future: DBHelper.getAllResults(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
                  return const Text('No data available.');
                } else {
                  return ListView.builder(
                    itemCount: (snapshot.data as List).length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      var item = (snapshot.data as List)[index];
                      String prediction = item['prediction'];

                      return ListTile(
                        leading: Image.asset(
                          getEmojiPath(prediction),
                          width: 24,
                          height: 24,
                        ),
                        title: Text('Prediction: $prediction'),
                        subtitle: Text('Capture Time: ${item['captureTime']}'),
                      );
                    },
                  );
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String getEmojiPath(String emotion) {
    Map<String, String> emotionToEmoji = {
      'Happy': 'assets/Emojis/emohappy.png',
      'Sad': 'assets/Emojis/emosad.png',
      'Angry': 'assets/Emojis/emoangry.png',
      'Neutral': 'assets/Emojis/emoneutral.png',
      'Fearful': 'assets/Emojis/emoafraid.png',
    };

    return emotionToEmoji[emotion] ?? 'assets/Emojis/default.png';
  }
}
