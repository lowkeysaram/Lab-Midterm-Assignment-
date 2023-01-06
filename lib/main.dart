import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splashScreen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homestay Raya',
      theme: ThemeData(
        textTheme:
            GoogleFonts.ubuntuTextTheme(Theme.of(context).textTheme.apply()),
        primarySwatch: Colors.blueGrey,
      ),
      home: SplashScreen(),
    );
  }
}
