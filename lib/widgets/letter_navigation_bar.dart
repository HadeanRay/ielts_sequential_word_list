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
      width: 32,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                        color: selectedLetter == letter
                            ? Colors.blue[100]
                            : Colors.transparent,
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
                              ? (selectedLetter == letter
                                    ? Colors.blue[800]
                                    : Colors.black87)
                              : Colors.grey[400],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 底部操作区
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              children: [
                // 回到顶部按钮
                _buildNavButton(
                  icon: Icons.keyboard_arrow_up,
                  onPressed: () => onLetterTap('TOP'),
                ),

                const SizedBox(height: 8),

                // 回到中间按钮
                _buildNavButton(
                  icon: Icons.center_focus_strong,
                  onPressed: () => onLetterTap('MIDDLE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 12, color: Colors.grey[700]),
      ),
    );
  }
}
