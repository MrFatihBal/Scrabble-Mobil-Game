import 'package:kelimeoyunu/models/letter.dart';

class Player {
  final String uid;
  final String username;
  List<Letter> hand;  // Oyuncunun elindeki 7 taş
  int score;          // Oyuncunun toplam puanı

  Player({
    required this.uid,
    required this.username,
    required this.hand,
    this.score = 0,
  });

  // Oyuncunun puanını güncellemek için kolay bir fonksiyon
  void addScore(int points) {
    score += points;
  }

  // Elindeki harflerden kullandıklarını silmek için
  void removeUsedLetters(List<String> usedLetters) {
    hand.removeWhere((letter) => usedLetters.contains(letter.character));
  }

  // Elindeki harfleri güncellemek için
  void addLetters(List<Letter> newLetters) {
    hand.addAll(newLetters);
  }
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      uid: map['uid'],
      username: map['username'],
      score: map['score'] ?? 0,
      hand: map['hand'] != null
          ? List<Letter>.from((map['hand'] as List).map((l) => Letter.fromMap(l)))
          : [],
    );
  }



  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'score': score,
      'hand': hand.map((l) => l.toMap()).toList(),
    };
  }

}
