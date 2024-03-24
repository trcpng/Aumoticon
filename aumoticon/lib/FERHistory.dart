import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';
import 'database_helper.dart';

class FacialEmotionHistory extends StatefulWidget {
  @override
  _FacialEmotionHistoryState createState() => _FacialEmotionHistoryState();
}

class _FacialEmotionHistoryState extends State<FacialEmotionHistory> {
  late Future<List<Map<String, dynamic>>?> _historyData;

  @override
  void initState() {
    super.initState();
    _historyData = DBHelper.getAllResults();
  }

  String getEmojiAsset(String emotion) {
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
      default:
        return 'assets/Emojis/default.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facial Emotion History'),
        backgroundColor: const Color(0xFFF4E4B4),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _historyData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Text('No facial emotion history available.');
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              reverse: true,
              itemBuilder: (context, index) {
                Map<String, dynamic> result = snapshot.data![index];
                String emotion = result['prediction'];
                String emojiAsset = getEmojiAsset(emotion);

                return ListTile(
                  title: Text('Prediction: $emotion'),
                  subtitle: Text('Capture Time: ${result['captureTime']}'),
                  leading: Image.asset(
                    emojiAsset,
                    width: 50,
                    height: 50,
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
