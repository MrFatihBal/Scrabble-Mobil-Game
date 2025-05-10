import 'dart:async';
import 'package:flutter/services.dart';

class WordRepository {
  static final Set<String> _allWords = {};

  static Future<void> loadWords() async {
    if (_allWords.isNotEmpty) return;

    final letters = [
      'a','b','c','c_','d','e','f','g','g_','h',
      'i','i_','j','k','l','m','n','o','o_','p',
      'r','s','s_','t','u','u_','v','y','z'
    ];

    for (final letter in letters) {
      try {
        final content = await rootBundle.loadString('assets/kelimeler/$letter.list');
        final words = content.split('\n').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty);
        _allWords.addAll(words);
      } catch (e) {
        print("⚠️ $letter.list yüklenemedi: $e");
      }
    }

    print("✅ Kelimeler yüklendi: ${_allWords.length} adet");
  }

  static bool isValidWord(String word) {
    if (_allWords.isEmpty) return false;

    // Eğer kelimede joker varsa → jokeri regex'e çevir (her harfi eşleştir)
    if (word.contains('?')) {
      final regex = RegExp('^' + word.replaceAll('?', '.') + r'$');
      return _allWords.any((w) => regex.hasMatch(w));
    }

    return _allWords.contains(word.toLowerCase());
  }


}
