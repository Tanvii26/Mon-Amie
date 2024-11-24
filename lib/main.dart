import 'package:flutter/material.dart';
import 'package:mon_amie/home_page.dart';
import 'package:mon_amie/pallete.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mon Amie',
      theme: ThemeData.light(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: Pallete.whiteColor
      ),
      home: const HomePage(),
    );
  }
}


