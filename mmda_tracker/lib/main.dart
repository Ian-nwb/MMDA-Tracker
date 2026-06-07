import 'package:flutter/material.dart';

void main() {
  // Tells the Android system to initialize the Flutter framework engines
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MMDA Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Instant dark mode canvas
      home: const Scaffold(
        body: Center(
          child: Text('Engine Initialized. Ready to build.'),
        ),
      ),
    );
  }
}