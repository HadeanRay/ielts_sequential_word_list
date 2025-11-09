import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';
import '../providers/word_list_provider.dart';
import '../widgets/letter_navigation_bar.dart';
import '../widgets/picker_scroll_view.dart';
import '../widgets/status_action_buttons.dart';
import '../widgets/word_list_item.dart';

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
        _scrollController.jumpTo(provider.scrollPosition * 100.0);
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

            // 右侧单词选择器
            Expanded(
              child: PickerScrollView(
                controller: _scrollController,
                itemCount: provider.wordList.length,
                itemExtent: 100.0,
                onCenterIndexChanged: (index) {
                  setState(() {
                    _centerWordIndex = index;
                  });
                },
                itemBuilder: (context, index, isCenter) {
                  final word = provider.wordList[index];
                  return _buildWordItem(word, isCenter);
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

  Widget _buildWordItem(WordItem word, bool isCenter) {
    return WordListItem(
      word: word,
      isCenter: isCenter,
      onTap: () {
        // 点击单词项时将其滚动到中心
        final provider = context.read<WordListProvider>();
        final index = provider.wordList.indexOf(word);
        if (index != -1 && _scrollController.hasClients) {
          _scrollController.animateTo(
            index * 100.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  void _handleLetterTap(String letter) {
    final provider = context.read<WordListProvider>();

    setState(() {
      _selectedLetter = letter;
    });

    // 获取当前viewport高度
    final viewportHeight = MediaQuery.of(context).size.height;

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
        // 修正：计算正确的居中位置
        final targetOffset = middleIndex * 100.0 - (viewportHeight - 100.0) / 2;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // 滚动到指定字母
      final indices = provider.getLetterGroupIndices();
      final targetIndex = indices[letter];
      if (targetIndex != null && _scrollController.hasClients) {
        // 修正：计算正确的居中位置
        final targetOffset = targetIndex * 100.0 - (viewportHeight - 100.0) / 2;
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _handleStatusChange(WordStatus status) {
    if (_centerWordIndex == null) return;

    final provider = context.read<WordListProvider>();
    provider.updateWordStatus(_centerWordIndex!, status);
  }
}