import 'package:flutter/material.dart';
import 'package:aumoticon/homepage.dart';
import 'splashscreen.dart';
import 'package:aumoticon/database_helper.dart';

void main() {
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: const Color(0x00ffe5b4),
      ),
      title: 'Navigation Example',
      debugShowCheckedModeBanner: false,
      initialRoute: '/SplashScreen',
      routes: {
        '/SplashScreen': (context) => const SplashScreen(),
        '/home': (context) => const Homepage(),
      },
      home: const Homepage(),
    );
  }
}
