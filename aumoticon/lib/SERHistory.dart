import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart'; // Import the sqflite package
import 'speech_db.dart';

class SpeechEmotionHistory extends StatefulWidget {
  @override
  _SpeechEmotionHistoryState createState() => _SpeechEmotionHistoryState();
}

class _SpeechEmotionHistoryState extends State<SpeechEmotionHistory> {
  late Future<List<Map<String, dynamic>>?> _emotionHistory;
  late Database _database; // Database instance

  @override
  void initState() {
    super.initState();
    _initializeDatabase(); // Initialize your database
    _emotionHistory = SpeechDBHelper.getAllResults();
  }

  // Initialize the database
  Future<void> _initializeDatabase() async {
    _database = await openDatabase('speech_recognition_database.db'); // Initialize your database here
    // Additional database initialization logic if needed
  }

  // Function to map predicted emotions to altered emotions
  String alterPredictedEmotion(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'disgust':
        return 'angry';
      case 'surprised':
        return 'happy';
      case 'calm':
        return 'neutral';
      default:
        return emotion;
    }
  }

  // Function to get the text of the emotion
  String getEmotionText(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
        return 'Happy';
      case 'sad':
        return 'Sad';
      case 'angry':
        return 'Angry';
      case 'fearful':
        return 'Fearful';
      case 'neutral':
        return 'Neutral';
      case 'calm':
        return 'Neutral';
      case 'surprised':
        return 'Happy';
      case 'disgust':
        return 'Angry';
      default:
        return 'Unknown';
    }
  }

  // Function to map predicted emotions to emoji assets
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
      case 'calm':
        return 'assets/Emojis/emoneutral.png';
      case 'surprised':
        return 'assets/Emojis/emohappy.png';
      case 'disgust':
        return 'assets/Emojis/emoangry.png';
      default:
        return ''; // Return an empty string for unknown emotions
    }
  }

  @override
  void dispose() {
    _database.close(); // Close the database connection when widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Emotion History'),
        backgroundColor: const Color(0xFFF4E4B4),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _emotionHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No speech emotion history available.');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              reverse: true,
              itemBuilder: (context, index) {
                Map<String, dynamic> result = snapshot.data![index];
                String emotion = result['emotionPrediction'];
                String emojiAsset = getEmojisAsset(emotion);

                return ListTile(
                  title: Text('Emotion: ${getEmotionText(emotion)}'),
                  subtitle: Text('Capture Time: ${result['captureTime']}'),
                  leading: emojiAsset.isNotEmpty
                      ? Image.asset(
                          emojiAsset,
                          width: 50,
                          height: 50,
                        )
                      : const Text('No emoticon available'), // Display text for no emoticon
                );
              },
            );
          }
        },
      ),
    );
  }
}

void main() {
  runApp(
    MaterialApp(
      home: SpeechEmotionHistory(),
    ),
  );
}
