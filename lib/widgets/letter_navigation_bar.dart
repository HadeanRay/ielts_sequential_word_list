import 'package:flutter/material.dart';

class LetterNavigationBar extends StatelessWidget {
  final Map<String, int> letterIndices;
  final String? selectedLetter;
  final Function(String) onLetterTap;

  const LetterNavigationBar({
    Key? key,
    required this.letterIndices,
    this.selectedLetter,
    required this.onLetterTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 字母列表
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: ListView.builder(
                itemCount: 26,
                itemBuilder: (context, index) {
                  final letter = String.fromCharCode(65 + index); // A-Z
                  final hasWords = letterIndices.containsKey(letter);

                  return GestureDetector(
                    onTap: hasWords ? () => onLetterTap(letter) : null,
                    child: Container(
                      height: 24,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        letter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selectedLetter == letter
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: hasWords
                              ? Colors.black87
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  
}
