import 'package:flutter/material.dart';
import 'package:kelimeoyunu/models/game_board.dart';
import 'package:kelimeoyunu/widgets/cell_widget.dart';

class GameBoardWidget extends StatelessWidget {
  final GameBoard board;
  final Function(int x, int y)? onCellTap;

  const GameBoardWidget({Key? key, required this.board, this.onCellTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double cellSize = MediaQuery.of(context).size.width / 15;

    return GridView.builder(
      shrinkWrap: true, // ✅ Bu olmadan görünmeyebilir
      physics: const NeverScrollableScrollPhysics(), // ✅ Scroll çatışmasını önler
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 15,
        childAspectRatio: 1.0,
      ),
      itemCount: 15 * 15,
      itemBuilder: (context, index) {
        int x = index ~/ 15;
        int y = index % 15;

        return CellWidget(
          cell: board.getCell(x, y),
          size: cellSize,
          onTap: () {
            print("🟩 Hücreye tıklandı: $x, $y");
            onCellTap?.call(x, y);
          },
        );
      },
    );
  }
}
