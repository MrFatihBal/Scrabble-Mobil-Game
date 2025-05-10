import 'package:flutter/material.dart';
import 'package:kelimeoyunu/models/game_board.dart';
import 'package:kelimeoyunu/widgets/game_board_widget.dart';

class GecmisOyunDetayEkrani extends StatelessWidget {
  final String player1;
  final String player2;
  final GameBoard board;

  const GecmisOyunDetayEkrani({
    Key? key,
    required this.player1,
    required this.player2,
    required this.board,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Oyun Detayı"),
        backgroundColor: Colors.cyan,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              "$player1 vs $player2",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GameBoardWidget(
                board: board,

              ),
            ),
          ],
        ),
      ),
    );
  }
}
