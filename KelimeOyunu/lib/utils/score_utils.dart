import 'package:kelimeoyunu/models/letter_data.dart';
import 'package:kelimeoyunu/models/cell.dart';


int calculateScore(List<Map<String, dynamic>> kelimeler) {
  int total = 0;
  bool hasKelimeIptal = false;
  bool hasKatEngeli = false;
  bool hasPuanBol = false;
  bool hasPuanTransfer = false;
  bool hasHarfKaybi = false;
  bool hasHarfBonus = false;
  bool hasKelimeBonus = false;
  bool hasTamPuan = false;

  for (var wordEntry in kelimeler) {
    final List<Cell> cells = wordEntry['hücreler'];
    int wordScore = 0;
    int wordMultiplier = 1;

    for (final cell in cells) {
      String letter = cell.letter!;
      int point = letter == "?" ? 0 : (letterData[letter]?['point'] ?? 0);
      if (cell.hasTrap) {
        switch (cell.trapType) {
          case 'kelime_iptal':
            hasKelimeIptal = true;
            break;
          case 'kat_engeli':
            hasKatEngeli = true;
            break;
          case 'puan_bol':
            hasPuanBol = true;
            break;
          case 'puan_transfer':
            hasPuanTransfer = true;
            break;
          case 'harf_kaybi':
            hasHarfKaybi = true;
            break;
        }
      }

      if (cell.hasReward) {
        switch (cell.rewardType) {
          case 'harf_bonus': hasHarfBonus = true; break;
          case 'kelime_bonus': hasKelimeBonus = true; break;
          case 'tam_puan': hasTamPuan = true; break;
        }
      }
      if (cell.isNew) {
        if (cell.scoreMultiplier > 1) {
          if (cell.multiplierType == 'harf') {
            point *= cell.scoreMultiplier;
          } else if (cell.multiplierType == 'kelime') {
            wordMultiplier *= cell.scoreMultiplier;
          }
        }
      }

      wordScore += point;
    }

    total += wordScore * wordMultiplier;
  }
  if (hasKelimeIptal) return 0;
  if (hasPuanBol) total = (total * 0.3).floor();
  if (hasTamPuan) total = (total * 2).floor();
  if (hasHarfBonus) total += 10;
  if (hasKelimeBonus) total += 20;
  return total;
}
