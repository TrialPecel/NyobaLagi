import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'controllers/music_controller.dart';
import 'screens/player_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set transparent status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicController()),
      ],
      child: MaterialApp(
        title: 'Rimble',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: GoogleFonts.interTextTheme(
            Theme.of(context).textTheme,
          ),
          useMaterial3: true,
        ),
        home: const PlayerScreen(),
      ),
    );
  }
}
