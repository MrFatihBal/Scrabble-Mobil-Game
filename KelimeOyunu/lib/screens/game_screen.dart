import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kelimeoyunu/models/game_board.dart';
import 'package:kelimeoyunu/models/user_model.dart';
import 'package:kelimeoyunu/models/player.dart';
import 'package:kelimeoyunu/models/tile_bag.dart';
import 'package:kelimeoyunu/models/letter.dart';
import 'package:kelimeoyunu/models/cell.dart';
import 'package:kelimeoyunu/models/letter_data.dart';
import 'package:kelimeoyunu/models/kelime_kontrol.dart';
import 'package:kelimeoyunu/utils/word_repository.dart';
import 'package:kelimeoyunu/widgets/game_board_widget.dart';
import 'package:kelimeoyunu/widgets/hand_widget.dart';

class GameScreen extends StatefulWidget {
  final String gameId;
  final AppUser currentUser;

  const GameScreen({Key? key, required this.gameId, required this.currentUser}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late DocumentReference gameRef;
  late GameBoard board;
  late TileBag tileBag;
  Player? currentPlayer;
  Player? opponentPlayer;
  Letter? selectedLetter;
  bool initialized = false;

  @override
  void initState() {
    super.initState();
    gameRef = FirebaseFirestore.instance.collection('games').doc(widget.gameId);
    board = GameBoard();
    tileBag = TileBag();
  }

  void _initializePlayers(Map<String, dynamic> data) {
    final player1 = Player.fromMap(data['player1']);
    final player2 = Player.fromMap(data['player2']);

    if (player1.uid == widget.currentUser.uid) {
      currentPlayer = player1;
      opponentPlayer = player2;
    } else {
      currentPlayer = player2;
      opponentPlayer = player1;
    }

    if (currentPlayer!.hand.isEmpty) {
      currentPlayer!.hand = tileBag.drawMultipleLetters(7);
      gameRef.update({
        currentPlayer!.uid == data['player1']['uid'] ? 'player1' : 'player2': currentPlayer!.toMap(),
      });
    }

    initialized = true;
  }

  void _handleOnayla(Map<String, dynamic> data) async {
    if (!initialized || currentPlayer == null || opponentPlayer == null) return;

    List<Cell> newCells = [];
    for (var row in board.cells) {
      for (var cell in row) {
        if (cell.isNew && cell.letter != null) {
          newCells.add(cell);
        }
      }
    }

    if (newCells.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hiç harf yerleştirmedin.")),
      );
      return;
    }

    final kontrol = KelimeKontrol(cells: board.cells, newCells: newCells);
    final kelimeler = kontrol.getOlusanKelimeler();

    if (kelimeler.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Geçerli kelime bulunamadı.")),
      );
      return;
    }

    for (var word in kelimeler) {
      if (!WordRepository.isValidWord(word.toLowerCase())) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("'$word' geçerli bir kelime değil")),
        );
        return;
      }
    }

    for (var cell in newCells) {
      cell.isNew = false;
    }

    final yeniHarfler = tileBag.drawMultipleLetters(newCells.length);
    currentPlayer!.hand.addAll(yeniHarfler);

    final player1Uid = (data['player1'] as Map<String, dynamic>)['uid'];
    final isPlayer1 = currentPlayer!.uid == player1Uid;
    final currentKey = isPlayer1 ? 'player1' : 'player2';
    final nextTurnUid = isPlayer1 ? opponentPlayer!.uid : player1Uid;

    await gameRef.update({
      currentKey: currentPlayer!.toMap(),
      'currentTurnUid': nextTurnUid,
      'board': board.toMap(),
    });

    setState(() {
      selectedLetter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Oyun Ekranı"),
        backgroundColor: Colors.cyan,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: gameRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['board'] != null) board = GameBoard.fromMap(data['board']);

          final currentTurnUid = data['currentTurnUid'];
          final isMyTurn = currentTurnUid == widget.currentUser.uid;

          if (!initialized) _initializePlayers(data);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Rakip: ${opponentPlayer?.username ?? '...'} | Puan: ${opponentPlayer?.score ?? 0}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: GameBoardWidget(
                  board: board,
                  onCellTap: (x, y) {
                    if (!isMyTurn || selectedLetter == null) return;
                    final cell = board.getCell(x, y);
                    if (cell.letter != null) return;

                    setState(() {
                      cell.letter = selectedLetter!.character;
                      cell.isNew = true;
                      currentPlayer!.hand.remove(selectedLetter);
                      selectedLetter = null;
                    });
                  },
                ),
              ),
              if (currentPlayer != null)
                HandWidget(
                  hand: currentPlayer!.hand,
                  selectedLetter: selectedLetter,
                  onLetterTap: (letter) {
                    setState(() {
                      selectedLetter = letter;
                    });
                  },
                ),
              if (isMyTurn)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final player1Uid = (data['player1'] as Map<String, dynamic>)['uid'];
                        final isPlayer1 = currentPlayer!.uid == player1Uid;
                        final currentKey = isPlayer1 ? 'player1' : 'player2';
                        final nextTurnUid = isPlayer1 ? opponentPlayer!.uid : player1Uid;

                        await gameRef.update({
                          currentKey: currentPlayer!.toMap(),
                          'currentTurnUid': nextTurnUid,
                        });

                        setState(() {});
                      },
                      child: const Text("⭯ Sıra Geç"),
                    ),
                    ElevatedButton(
                      onPressed: () => _handleOnayla(data),
                      child: const Text("✅ Onayla"),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}
