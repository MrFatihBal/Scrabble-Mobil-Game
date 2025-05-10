import 'dart:math';
import 'package:kelimeoyunu/models/letter.dart';
import 'package:kelimeoyunu/models/letter_data.dart';

class TileBag {
  List<Letter> _letters = [];

  TileBag() {
    _initializeBag();
  }

  void _initializeBag() {
    letterData.forEach((char, info) {
      int count = info['count']!;
      int point = info['point']!;
      for (int i = 0; i < count; i++) {
        _letters.add(Letter(character: char, point: point));
      }
    });

    shuffleBag();
  }

  void shuffleBag() {
    _letters.shuffle(Random());
  }

  Letter drawLetter() {
    return _letters.removeLast();

  }

  List<Letter> drawMultipleLetters(int n) {
    List<Letter> drawn = [];
    for (int i = 0; i < n && _letters.isNotEmpty; i++) {
      drawn.add(drawLetter());
    }
    return drawn;
  }

  void returnLetters(List<Letter> letters) {
    _letters.addAll(letters);
    shuffleBag(); // Karıştırıyoruz tekrar
  }

  int remainingLetters() {
    return _letters.length;
  }
  Map<String, dynamic> toMap() {
    return {
      'bag': _letters.map((letter) => letter.toMap()).toList(),
    };
  }

  TileBag.fromMap(Map<String, dynamic> map) {
    _letters = (map['bag'] as List).map((e) => Letter.fromMap(e)).toList();
  }

}
