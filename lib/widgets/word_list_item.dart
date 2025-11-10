import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';

class WordListItem extends StatelessWidget {
  final WordItem word;
  final bool isCenter;
  final bool showChinese; // 新增参数控制是否显示中文释义
  final VoidCallback? onTap;

  const WordListItem({
    Key? key,
    required this.word,
    required this.isCenter,
    this.showChinese = false, // 默认不显示中文释义
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
        textColorValue = isCenter ? 0xFF000000 : 0xFF4CAF50; // 深黑色/绿色
        chineseColorValue = isCenter ? 0xFF000000 : 0xFF4CAF50; // 深黑色/绿色
        break;
      case WordStatus.hesitant:
        backgroundColorValue = isCenter ? 0xFFFFEB3B : 0x10FFEB3B; // 黄色/浅黄色
        textColorValue = isCenter ? 0xFF000000 : 0xFF9E9E9E; 
        chineseColorValue = isCenter ? 0xFF000000 : 0xFF9E9E9E; 
        break;
      case WordStatus.difficult:
        backgroundColorValue = isCenter ? 0xFFF44336 : 0x10F44336; // 红色/浅红色
        textColorValue = isCenter ? 0xFF000000 : 0xFF9E9E9E; // 深黑色/红色
        chineseColorValue = isCenter ? 0xFF000000 : 0xFF9E9E9E; // 深黑色/红色
        break;
      default:
        backgroundColorValue = 0x00000000; // 透明
        textColorValue = isCenter ? 0xFF000000 : 0xFF9E9E9E; 
        chineseColorValue = isCenter ? 0xFF000000 : 0xFF9E9E9E; 
        break;
    }

    return GestureDetector(

      onTap: onTap,

      child: Container(

        margin: EdgeInsets.symmetric(

          horizontal: 10,

          vertical: 4, // 添加垂直间隙

        ),

        padding: EdgeInsets.symmetric(

          vertical: isCenter ? 12 : 8, // 降低垂直内边距

          horizontal: isCenter ? 16 : 12, // 降低水平内边距

        ),

        decoration: BoxDecoration(

          color: Color(backgroundColorValue),

          borderRadius: BorderRadius.circular(12), // 减小圆角

        ),

        child: Row(

          children: [

            // 左侧英文单词

            Expanded(

              flex: 2,

              child: Text(

                word.english,

                style: TextStyle(

                  fontSize: isCenter ? 18 : 14, // 降低字体大小

                  fontWeight: isCenter ? FontWeight.bold : FontWeight.w600,

                  color: Color(textColorValue),

                ),

                textAlign: TextAlign.left,

              ),

            ),



            const SizedBox(width: 12), // 减小单词和释义之间的间距



            // 右侧中文释义

            Expanded(

              flex: 3,

              child: Text(

                showChinese ? word.chinese : '', // 根据showChinese参数决定是否显示中文释义

                style: TextStyle(

                  fontSize: isCenter ? 16 : 12, // 降低字体大小

                  fontWeight: isCenter ? FontWeight.w500 : FontWeight.normal,

                  color: Color(chineseColorValue),

                ),

                textAlign: TextAlign.left,

              ),

            ),

          ],

        ),

      ),

    );
  }
}