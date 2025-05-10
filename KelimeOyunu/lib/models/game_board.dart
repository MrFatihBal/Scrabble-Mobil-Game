import 'package:kelimeoyunu/models/cell.dart';
import 'dart:math';

class GameBoard {
  final int size = 15;
  late List<List<Cell>> board;

  List<List<Cell>> get cells => board;

  GameBoard() {
    board = List.generate(
      size,
          (x) => List.generate(
        size,
            (y) => Cell(x: x, y: y),
      ),
    );

    _initializeDefaultMultipliers();
  }

  GameBoard.fromMap(Map<String, dynamic> map) {
    board = List.generate(
      size,
          (x) => List.generate(
        size,
            (y) => Cell(x: x, y: y),
      ),
    );

    for (var cellMap in map['cells']) {
      final x = cellMap['x'];
      final y = cellMap['y'];
      board[x][y] = Cell.fromMap(cellMap); // 🔥 Full Cell'i yükle
    }

    // multiplierları burada tekrar initialize etme — zaten Firestore'dan gelen her şey var
  }


  Cell getCell(int x, int y) => board[x][y];

  Map<String, dynamic> toMap() {
    final flatCells = <Map<String, dynamic>>[];

    for (var row in board) {
      for (var cell in row) {
        flatCells.add(cell.toMap()); // Tüm cell'i full map olarak kaydet
      }
    }

    return {
      'cells': flatCells,
    };
  }


  List<List<Cell>> generateRandomBoard() {
    final random = Random();

    return List.generate(15, (x) {
      return List.generate(15, (y) {
        bool hasTrap = false;
        String? trapType;
        bool hasReward = false;
        String? rewardType;

        final rand = random.nextDouble();

        if (rand < 0.05) {
          hasTrap = true;
          trapType = ['freeze', 'losePoints', 'bomb'][random.nextInt(3)];
        } else if (rand < 0.1) {
          hasReward = true;
          rewardType = ['doublePoints', 'extraTurn', 'shield'][random.nextInt(3)];
        }

        // Bonuslar dışında da multiplier da ekleyebiliriz istersen
        int multiplier = 1;
        String multiplierType = 'none';
        if (rand >= 0.1 && rand < 0.13) {
          multiplier = 2;
          multiplierType = 'letter';
        } else if (rand >= 0.13 && rand < 0.15) {
          multiplier = 3;
          multiplierType = 'word';
        }

        return Cell(
          x: x,
          y: y,
          scoreMultiplier: multiplier,
          multiplierType: multiplierType,
          hasTrap: hasTrap,
          trapType: trapType,
          hasReward: hasReward,
          rewardType: rewardType,
        );
      });
    });
  }



  List<List<Cell>> getCells() => board;

  void resetNewFlags() {
    for (var row in board) {
      for (var cell in row) {
        cell.isNew = false;
      }
    }
  }


  void _initializeDefaultMultipliers() {
    // 🎯 H³ alanları (Harf 3 Katı)
    const h3 = [
      [1, 1], [1, 13], [4, 4], [4, 10],
      [10, 4], [10, 10], [13, 1], [13, 13],
    ];

    // 🔥 K³ alanları (Kelime 3 Katı)
    const k3 = [
      [0, 2], [0, 12], [2, 0], [2, 14],
      [12, 0], [12, 14], [14, 2], [14, 12],
    ];

    // 💠 H² alanları (Harf 2 Katı)
    const h2 = [
      [0, 5], [0, 9], [1, 6], [1, 8], [5, 0], [5, 5],
      [5, 9], [5, 14], [6, 1], [6, 6], [6, 8], [6, 13],
      [8, 1], [8, 6], [8, 8], [8, 13], [9, 0], [9, 5],
      [9, 9], [9, 14], [13, 6], [13, 8], [14, 5], [14, 9],
    ];

    // ⭐ K² alanları (Kelime 2 Katı)
    const k2 = [
      [2, 7], [3, 3], [3, 11], [7, 2],
      [7, 12], [11, 3], [11, 11], [12, 7],
    ];

    for (var pos in h3) {
      board[pos[0]][pos[1]].scoreMultiplier = 3;
      board[pos[0]][pos[1]].multiplierType = "harf";
    }

    for (var pos in k3) {
      board[pos[0]][pos[1]].scoreMultiplier = 3;
      board[pos[0]][pos[1]].multiplierType = "kelime";
    }

    for (var pos in h2) {
      board[pos[0]][pos[1]].scoreMultiplier = 2;
      board[pos[0]][pos[1]].multiplierType = "harf";
    }

    for (var pos in k2) {
      board[pos[0]][pos[1]].scoreMultiplier = 2;
      board[pos[0]][pos[1]].multiplierType = "kelime";
    }
  }
}
