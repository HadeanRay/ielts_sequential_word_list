import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';
import '../providers/word_list_provider.dart';
import '../widgets/word_list_item.dart';
import '../widgets/letter_navigation_bar.dart';
import '../widgets/status_action_buttons.dart';
import '../widgets/centered_scroll_view.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _centerWordIndex;
  String? _selectedLetter;

  @override
  void initState() {
    super.initState();

    // 加载单词列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WordListProvider>().loadWordList();
    });

    // 从本地存储恢复滚动位置
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WordListProvider>();
      if (provider.scrollPosition > 0 && _scrollController.hasClients) {
        _scrollController.jumpTo(provider.scrollPosition * 76.0);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<WordListProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return _buildLoadingScreen();
          }

          if (provider.error != null) {
            return _buildErrorScreen(provider.error!);
          }

          if (provider.wordList.isEmpty) {
            return _buildEmptyScreen();
          }

          return _buildMainScreen(provider);
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载单词列表...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text('加载失败', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<WordListProvider>().loadWordList();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Scaffold(
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '没有找到单词数据',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreen(WordListProvider provider) {
    return Stack(
      children: [
        // 主内容区
        Row(
          children: [
            // 左侧导航栏
            LetterNavigationBar(
              letterIndices: provider.getLetterGroupIndices(),
              selectedLetter: _selectedLetter,
              onLetterTap: _handleLetterTap,
            ),

            // 右侧单词列表
            Expanded(
              child: CenteredScrollView(
                controller: _scrollController,
                itemCount: provider.wordList.length,
                itemHeight: 76.0,
                onCenterIndexChanged: (index) {
                  setState(() {
                    _centerWordIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final word = provider.wordList[index];
                  final isCenter = index == _centerWordIndex;

                  return WordListItem(
                    word: word,
                    isCenter: isCenter,
                    onTap: () => _handleWordTap(index),
                  );
                },
              ),
            ),
          ],
        ),

        // 底部状态按钮
        StatusActionButtons(
          onEasyPressed: () => _handleStatusChange(WordStatus.easy),
          onHesitantPressed: () => _handleStatusChange(WordStatus.hesitant),
          onDifficultPressed: () => _handleStatusChange(WordStatus.difficult),
        ),
      ],
    );
  }

  void _handleLetterTap(String letter) {
    final provider = context.read<WordListProvider>();

    setState(() {
      _selectedLetter = letter;
    });

    if (letter == 'TOP') {
      // 滚动到顶部
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } else if (letter == 'MIDDLE') {
      // 滚动到中间
      final middleIndex = (provider.wordList.length / 2).round();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          middleIndex * 76.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // 滚动到指定字母
      final indices = provider.getLetterGroupIndices();
      final targetIndex = indices[letter];
      if (targetIndex != null && _scrollController.hasClients) {
        _scrollController.animateTo(
          targetIndex * 76.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _handleWordTap(int index) {
    // 可以在这里添加单词点击事件，比如显示详细信息
  }

  void _handleStatusChange(WordStatus status) {
    if (_centerWordIndex == null) return;

    final provider = context.read<WordListProvider>();
    provider.updateWordStatus(_centerWordIndex!, status);
  }

  /// 构建屏幕中央的突出显示框
  Widget _buildCenterHighlightBox(WordItem word) {
    // 根据状态获取颜色
    int backgroundColorValue;
    int borderColorValue;
    int textColorValue;

    switch (word.status) {
      case WordStatus.easy:
        backgroundColorValue = 0xFFE8F5E8; // 浅绿色
        borderColorValue = 0xFF4CAF50; // 绿色
        textColorValue = 0xFF2E7D32; // 深绿色
        break;
      case WordStatus.hesitant:
        backgroundColorValue = 0xFFFFFFF0; // 浅黄色
        borderColorValue = 0xFFFFEB3B; // 黄色
        textColorValue = 0xFFF57F17; // 深黄色
        break;
      case WordStatus.difficult:
        backgroundColorValue = 0xFFFFEBEE; // 浅红色
        borderColorValue = 0xFFF44336; // 红色
        textColorValue = 0xFFC62828; // 深红色
        break;
      default:
        backgroundColorValue = 0xFFF5F5F5; // 浅灰色
        borderColorValue = 0xFF9E9E9E; // 灰色
        textColorValue = 0xFF616161; // 深灰色
    }

    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Color(backgroundColorValue),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              // 大范围外阴影 - 上凸效果
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 12),
                spreadRadius: 8,
              ),
              // 内阴影
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, -4),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 左侧英文单词
              Expanded(
                flex: 2,
                child: Text(
                  word.english,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(textColorValue),
                    letterSpacing: 1.2,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.left,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 24),

              // 右侧中文释义和状态
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 中文释义
                    if (word.status != WordStatus.defaultState)
                      Text(
                        word.chinese,
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(textColorValue),
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.left,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      Text(
                        '未标记状态',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.left,
                      ),

                    const SizedBox(height: 8),

                    // 状态标签
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Color(borderColorValue).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        word.status.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(textColorValue),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
