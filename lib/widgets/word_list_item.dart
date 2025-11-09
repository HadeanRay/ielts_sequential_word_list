import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';

class WordListItem extends StatelessWidget {
  final WordItem word;
  final bool isCenter;
  final VoidCallback? onTap;

  const WordListItem({
    Key? key,
    required this.word,
    required this.isCenter,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 根据状态获取颜色
    int backgroundColorValue;
    int textColorValue;
    int chineseColorValue;

    switch (word.status) {
      case WordStatus.easy:
        backgroundColorValue = isCenter ? 0xFF4CAF50 : 0x104CAF50; // 绿色/浅绿色
        textColorValue = isCenter ? 0xFFFFFFFF : 0xFF4CAF50; // 白色/绿色
        chineseColorValue = isCenter ? 0xFFFFFFFF : 0xFF4CAF50; // 白色/绿色
        break;
      case WordStatus.hesitant:
        backgroundColorValue = isCenter ? 0xFFFFEB3B : 0x10FFEB3B; // 黄色/浅黄色
        textColorValue = isCenter ? 0xFF000000 : 0xFFFFEB3B; // 黑色/黄色
        chineseColorValue = isCenter ? 0xFF000000 : 0xFFFFEB3B; // 黑色/黄色
        break;
      case WordStatus.difficult:
        backgroundColorValue = isCenter ? 0xFFF44336 : 0x10F44336; // 红色/浅红色
        textColorValue = isCenter ? 0xFFFFFFFF : 0xFFF44336; // 白色/红色
        chineseColorValue = isCenter ? 0xFFFFFFFF : 0xFFF44336; // 白色/红色
        break;
      default:
        backgroundColorValue = isCenter ? 0xFF9E9E9E : 0x109E9E9E; // 灰色/浅灰色
        textColorValue = isCenter ? 0xFFFFFFFF : 0xFF9E9E9E; // 白色/灰色
        chineseColorValue = isCenter ? 0xFFFFFFFF : 0xFF9E9E9E; // 白色/灰色
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: 20,
        ),
        padding: EdgeInsets.symmetric(
          vertical: isCenter ? 20 : 12,
          horizontal: isCenter ? 20 : 16,
        ),
        decoration: BoxDecoration(
          color: Color(backgroundColorValue),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // 左侧英文单词
            Expanded(
              flex: 2,
              child: Text(
                word.english,
                style: TextStyle(
                  fontSize: isCenter ? 22 : 16,
                  fontWeight: isCenter ? FontWeight.bold : FontWeight.w600,
                  color: Color(textColorValue),
                ),
                textAlign: TextAlign.left,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 16),

            // 右侧中文释义
            Expanded(
              flex: 3,
              child: Text(
                word.chinese,
                style: TextStyle(
                  fontSize: isCenter ? 18 : 14,
                  fontWeight: isCenter ? FontWeight.w500 : FontWeight.normal,
                  color: Color(chineseColorValue),
                ),
                textAlign: TextAlign.left,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}