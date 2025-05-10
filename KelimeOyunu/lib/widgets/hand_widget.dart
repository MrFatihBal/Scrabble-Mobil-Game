import 'package:flutter/material.dart';
import 'package:kelimeoyunu/models/letter.dart';


class HandWidget extends StatelessWidget {
  final List<Letter> hand;
  final Function(Letter)? onLetterTap;
  final Letter? selectedLetter;

  const HandWidget({
    Key? key,
    required this.hand,
    this.onLetterTap,
    this.selectedLetter,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: hand.map((letter) {
        final isSelected = selectedLetter?.character == letter.character;

        return GestureDetector(
          onTap: () => onLetterTap?.call(letter),
          child: Container(
            margin: const EdgeInsets.all(4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: isSelected ? Colors.red : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              letter.character,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
