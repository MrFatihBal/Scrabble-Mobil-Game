import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:kelimeoyunu/screens/ana_sayfa.dart';
import 'firebase_options.dart';
import 'package:kelimeoyunu/utils/word_repository.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WordRepository.loadWords();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AnaUygulama());
}

class AnaUygulama extends StatelessWidget {
  const AnaUygulama({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kelime Mayınları',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home:  AnaSayfa(), // burada AnaSayfa() Scaffold içeriyor
    );
  }
}
