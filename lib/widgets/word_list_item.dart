import 'package:flutter/material.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';

class WordListItem extends StatelessWidget {
  final WordItem word;
  final bool isCenter;
  final VoidCallback? onTap;

  const WordListItem({
    super.key,
    required this.word,
    this.isCenter = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: isCenter
              ? _getCenterBackgroundColor()
              : Colors.transparent,
          border: isCenter
              ? Border.all(
                  color: _getCenterBorderColor(),
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isCenter
              ? [
                  BoxShadow(
                    color: _getCenterBorderColor().withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // 左侧英文单词
            Expanded(
              flex: 2,
              child: Text(
                word.english,
                style: TextStyle(
                  fontSize: _calculateFontSize(),
                  fontWeight: isCenter ? FontWeight.bold : FontWeight.w600,
                  color: isCenter ? _getCenterTextColor() : Colors.black87,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 16),

            // 右侧中文释义（带状态背景色）
            Expanded(flex: 3, child: _buildChineseMeaning()),
          ],
        ),
      ),
    );
  }

  Widget _buildChineseMeaning() {
    // 居中项总是显示中文释义，非居中项只在非默认状态时显示
    if (!isCenter && word.status == WordStatus.defaultState) {
      return const SizedBox.shrink();
    }

    int backgroundColorValue;
    int textColorValue;

    // 根据状态确定颜色
    switch (word.status) {
      case WordStatus.easy:
        backgroundColorValue = isCenter ? 0xFF4CAF50 : 0xFFE8F5E8; // 绿色/浅绿色
        textColorValue = isCenter ? 0xFFFFFFFF : 0xFF2E7D32; // 白色/深绿色
        break;
      case WordStatus.hesitant:
        backgroundColorValue = isCenter ? 0xFFFFEB3B : 0xFFFFFFF0; // 黄色/浅黄色
        textColorValue = isCenter ? 0xFF000000 : 0xFFF57F17; // 黑色/深黄色
        break;
      case WordStatus.difficult:
        backgroundColorValue = isCenter ? 0xFFF44336 : 0xFFFFEBEE; // 红色/浅红色
        textColorValue = isCenter ? 0xFFFFFFFF : 0xFFC62828; // 白色/深红色
        break;
      default:
        backgroundColorValue = isCenter ? 0xFF9E9E9E : 0xFFF5F5F5; // 灰色/浅灰色
        textColorValue = isCenter ? 0xFFFFFFFF : 0xFF616161; // 白色/深灰色
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCenter ? 20 : 16,
        vertical: isCenter ? 16 : 12,
      ),
      decoration: BoxDecoration(
        color: Color(backgroundColorValue),
        borderRadius: BorderRadius.circular(isCenter ? 24 : 20),
        border: isCenter
            ? Border.all(color: Colors.white, width: 2)
            : Border.all(color: Colors.white, width: 2),
        boxShadow: isCenter
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        word.chinese,
        style: TextStyle(
          fontSize: isCenter ? 20 : 16,
          color: Color(textColorValue),
          fontWeight: isCenter ? FontWeight.bold : FontWeight.w500,
          height: 1.3,
        ),
        textAlign: TextAlign.center,
        maxLines: isCenter ? 3 : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 根据单词长度计算合适的字体大小，避免转行
  double _calculateFontSize() {
    final wordLength = word.english.length;
    
    if (isCenter) {
      // 中心显示的基础字体大小
      if (wordLength <= 6) {
        return 24.0;
      } else if (wordLength <= 8) {
        return 22.0;
      } else if (wordLength <= 12) {
        return 20.0;
      } else if (wordLength <= 16) {
        return 18.0;
      } else {
        return 16.0;
      }
    } else {
      // 非中心显示的基础字体大小
      if (wordLength <= 6) {
        return 18.0;
      } else if (wordLength <= 8) {
        return 16.0;
      } else if (wordLength <= 12) {
        return 14.0;
      } else if (wordLength <= 16) {
        return 12.0;
      } else {
        return 10.0;
      }
    }
  }

  /// 获取居中项的背景色
  Color _getCenterBackgroundColor() {
    switch (word.status) {
      case WordStatus.easy:
        return const Color(0xFF4CAF50); // 绿色
      case WordStatus.hesitant:
        return const Color(0xFFFFEB3B); // 黄色
      case WordStatus.difficult:
        return const Color(0xFFF44336); // 红色
      default:
        return const Color(0xFF9E9E9E); // 灰色
    }
  }

  /// 获取居中项的边框颜色
  Color _getCenterBorderColor() {
    switch (word.status) {
      case WordStatus.easy:
        return const Color(0xFF388E3C); // 深绿色
      case WordStatus.hesitant:
        return const Color(0xFFFBC02D); // 深黄色
      case WordStatus.difficult:
        return const Color(0xFFD32F2F); // 深红色
      default:
        return const Color(0xFF616161); // 深灰色
    }
  }

  /// 获取居中项的文本颜色
  Color _getCenterTextColor() {
    switch (word.status) {
      case WordStatus.hesitant:
        return Colors.black; // 黄色背景上用黑色文字
      default:
        return Colors.white; // 其他背景上用白色文字
    }
  }
}