import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/video_player_screen.dart';
import 'providers/player_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Video Player',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      home: ChangeNotifierProvider(
        create: (_) => PlayerProvider(),
        child: const VideoPlayerScreen(),
      ),
    );
  }
}