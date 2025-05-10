import 'package:flutter/material.dart';
import '../models/cell.dart';
import 'package:kelimeoyunu/models/game_board.dart';

class CellWidget extends StatelessWidget {
  final Cell cell;
  final double size;
  final void Function()? onTap;

  const CellWidget({
    Key? key,
    required this.cell,
    required this.size,
    this.onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color color;


    if (cell.letter != null) {
      color = Colors.white; // 🔥 Harf varsa arka plan sabit beyaz
    } else if (cell.scoreMultiplier == 3 && cell.multiplierType == "harf") {
      color = Colors.redAccent;
    } else if (cell.scoreMultiplier == 3 && cell.multiplierType == "kelime") {
      color = Colors.blueAccent;
    } else if (cell.scoreMultiplier == 2 && cell.multiplierType == "harf") {
      color = Colors.orangeAccent;
    } else if (cell.scoreMultiplier == 2 && cell.multiplierType == "kelime") {
      color = Colors.greenAccent;
    } else if (cell.x == 7 && cell.y == 7) {
      color = Colors.yellow;
    } else if (cell.hasTrap) {
      color = Colors.black12;
    } else if (cell.hasReward) {
      color = Colors.amberAccent;
    }
    else {
      color = Colors.grey.shade300;
    }


    return GestureDetector(
      onTap: onTap,
      child: Container(

        width: size,
        height: size,
        margin: EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                cell.letter ??
                    (cell.scoreMultiplier > 1
                        ? (cell.multiplierType == 'harf'
                        ? (cell.scoreMultiplier == 2 ? 'H\u00B2' : 'H\u00B3')
                        : (cell.scoreMultiplier == 2 ? 'K\u00B2' : 'K\u00B3'))
                        : ''),
                style:  TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: cell.letter != null ? size * 0.6 : size * 0.3,
                  color: cell.letter != null ? Colors.black : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

            ],
          ),
        ),
      ),
    );
  }
}
