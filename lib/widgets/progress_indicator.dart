import 'package:flutter/material.dart';
import '../providers/word_list_provider.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final WordListProvider provider;
  final int? centerWordIndex;

  const ProgressIndicatorWidget({
    super.key,
    required this.provider,
    this.centerWordIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 获取今天首次打开位置
    final todayFirstOpenIndex = provider.todayFirstOpenIndex;
    
    // 根据是否有筛选来确定当前中心单词的绝对索引
    int currentAbsoluteIndex;
    if (provider.hasFilterApplied()) {
      // 如果有筛选，需要将当前中心索引转换为原始列表中的索引
      if (centerWordIndex != null && centerWordIndex! < provider.filteredWordList.length) {
        final currentWord = provider.filteredWordList[centerWordIndex!];
        currentAbsoluteIndex = provider.wordList.indexOf(currentWord);
        if (currentAbsoluteIndex == -1) {
          currentAbsoluteIndex = todayFirstOpenIndex; // 如果找不到，使用今天首次打开的索引
        }
      } else {
        currentAbsoluteIndex = todayFirstOpenIndex;
      }
    } else {
      // 没有筛选时，直接使用原始中心索引
      currentAbsoluteIndex = provider.originalCenterWordIndex;
    }
    
    // 确保索引在有效范围内
    currentAbsoluteIndex = currentAbsoluteIndex.clamp(0, provider.wordList.length - 1);
    
    // 计算统计信息
    final wordsBeforeToday = todayFirstOpenIndex;
    final wordsBetweenTodayAndCurrent = (currentAbsoluteIndex - todayFirstOpenIndex).abs();
    final wordsAfterCurrent = provider.wordList.length - currentAbsoluteIndex - 1;
    
    String progressText = '';
    if (provider.wordList.isNotEmpty) {
      progressText = '${wordsBeforeToday.toString().padLeft(3)} / '
                   + '${wordsBetweenTodayAndCurrent.toString().padLeft(3)} / '
                   + '${wordsAfterCurrent.toString().padLeft(3)}';
    } else {
      progressText = '000 / 000 / 000';
    }

    return Positioned(
      top: 40,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              progressText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}