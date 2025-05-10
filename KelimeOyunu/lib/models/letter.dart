import 'package:kelimeoyunu/models/letter_data.dart';

class Letter {
  final String character;  // Harfin kendisi ("A", "B", "Ç", "JOKER" gibi)
  final int point;         // Harfin puanı

  Letter({
    required this.character,
    required this.point,
  });
  factory Letter.fromMap(Map<String, dynamic> map) {
    return Letter(
      character: map['character'],
      point: map['point'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'character': character,
      'point': point,
    };
  }
  factory Letter.fromChar(String ch) {
    return Letter(
      character: ch,
      point: letterData[ch.toUpperCase()]?['point'] ?? 1, // puanı getir
    );
  }


}

