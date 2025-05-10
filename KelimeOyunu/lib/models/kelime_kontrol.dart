import 'dart:math';

import 'package:kelimeoyunu/models/cell.dart';

class KelimeKontrol {
  final List<List<Cell>> cells;
  final List<Cell> newCells;

  KelimeKontrol({
    required this.cells,
    required this.newCells,
  });
  bool isConnectedToExisting() {
    for (final cell in newCells) {
      final neighbors = [
        Point(cell.x - 1, cell.y),
        Point(cell.x + 1, cell.y),
        Point(cell.x, cell.y - 1),
        Point(cell.x, cell.y + 1),
      ];

      for (final p in neighbors) {
        if (p.x >= 0 && p.x < cells.length && p.y >= 0 && p.y < cells.length) {
          final neighborCell = cells[p.x][p.y];
          if (!neighborCell.isNew && neighborCell.letter != null) {
            return true; // ✅ başka bir eski harfe temas ediyor
          }
        }
      }
    }
    return false; // ❌ hiç temas yok
  }
  List<Map<String, dynamic>> getOlusanKelimelerWithCoords() {
    List<Map<String, dynamic>> kelimeler = [];

    for (final cell in newCells) {
      int x = cell.x;
      int y = cell.y;

      // Yatay kelime
      int startY = y;
      while (startY > 0 && cells[x][startY - 1].letter != null) startY--;

      List<Cell> yatay = [];
      int ty = startY;
      while (ty < cells.length && cells[x][ty].letter != null) {
        yatay.add(cells[x][ty]);
        ty++;
      }

      if (yatay.length > 1) {
        final kelime = yatay.map((c) => c.letter!).join();
        kelimeler.add({'kelime': kelime, 'hücreler': yatay});
      }

      // Dikey kelime
      int startX = x;
      while (startX > 0 && cells[startX - 1][y].letter != null) startX--;

      List<Cell> dikey = [];
      int tx = startX;
      while (tx < cells.length && cells[tx][y].letter != null) {
        dikey.add(cells[tx][y]);
        tx++;
      }

      if (dikey.length > 1) {
        final kelime = dikey.map((c) => c.letter!).join();
        kelimeler.add({'kelime': kelime, 'hücreler': dikey});
      }
    }

    // Aynı kelimeyi iki kez eklemeyelim
    final unique = <String>{};
    return kelimeler.where((e) => unique.add(e['kelime'])).toList();
  }



  List<String> getOlusanKelimeler() {
    Set<String> words = {};

    for (final cell in newCells) {
      int x = cell.x;
      int y = cell.y;

      // yatay
      int startY = y;
      while (startY > 0 && cells[x][startY - 1].letter != null) {
        startY--;
      }

      String horizontal = '';
      int ty = startY;
      while (ty < cells.length && cells[x][ty].letter != null) {
        horizontal += cells[x][ty].letter!;
        ty++;
      }

      if (horizontal.length > 1) words.add(horizontal);

      // dikey
      int startX = x;
      while (startX > 0 && cells[startX - 1][y].letter != null) {
        startX--;
      }

      String vertical = '';
      int tx = startX;
      while (tx < cells.length && cells[tx][y].letter != null) {
        vertical += cells[tx][y].letter!;
        tx++;
      }

      if (vertical.length > 1) words.add(vertical);
    }

    return words.toList();
  }

  bool isPassingThroughCenter() {
    return newCells.any((cell) => cell.x == 7 && cell.y == 7);
  }
}
