import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';
import '../providers/word_list_provider.dart';
import '../widgets/letter_navigation_bar.dart';
import '../widgets/picker_scroll_view.dart';
import '../widgets/status_action_buttons.dart';
import '../widgets/word_list_item.dart';

class _Constants {
  static const double itemHeight = 60.0;
  static const Duration scrollDuration = Duration(milliseconds: 300);
  static const Duration restoreDuration = Duration(milliseconds: 500);
}

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _centerWordIndex;
  int? _forceShowChineseIndex;
  String? _selectedLetter;
  bool _isRestoringPosition = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  Future<void> _initializeScreen() async {
    final provider = context.read<WordListProvider>();
    await provider.loadWordList();
    if (mounted) {
      _restoreScrollPosition(provider);
    }
  }

  void _restoreScrollPosition(WordListProvider provider) {
    if (provider.wordList.isEmpty) return;

    final savedIndex = provider.getSavedCenterIndex();
    final clampedIndex = savedIndex.clamp(0, provider.wordList.length - 1);
    
    setState(() {
      _centerWordIndex = clampedIndex;
      _isRestoringPosition = true;
    });

    // 延迟执行滚动以确保widget已经构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final viewportHeight = MediaQuery.of(context).size.height;
        final targetOffset = _calculateTargetOffset(clampedIndex, viewportHeight);
        _scrollController.jumpTo(targetOffset);
        
        setState(() {
          _isRestoringPosition = false;
        });
      }
    });
  }

  double _calculateTargetOffset(int index, double viewportHeight) {
    final centerOffset = index * _Constants.itemHeight;
    final targetOffset = centerOffset - (viewportHeight / 2) + (_Constants.itemHeight / 2);
    return targetOffset.clamp(0.0, double.infinity);
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



                itemExtent: _Constants.itemHeight,



                onCenterIndexChanged: (index) {



                  setState(() {



                    _centerWordIndex = index;



                  });

                  

                  // 只有在非恢复位置模式时才更新Provider中的中心单词索引

                  if (!_isRestoringPosition) {

                    provider.updateCenterWordIndex(index);

                  }



                },



                forceShowChineseIndex: _forceShowChineseIndex, // 强制显示中文释义的索引



                itemBuilder: (context, index, isCenter, showChinese) {



                  final word = provider.wordList[index];



                  return _buildWordItem(word, isCenter, showChinese);



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

  Widget _buildWordItem(WordItem word, bool isCenter, bool showChinese) {
    return WordListItem(
      word: word,
      isCenter: isCenter,
      showChinese: showChinese,
      onTap: () => _scrollToWord(word),
    );
  }

  void _scrollToWord(WordItem word) {
    final provider = context.read<WordListProvider>();
    final index = provider.wordList.indexOf(word);
    if (index != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(
        index * _Constants.itemHeight,
        duration: _Constants.scrollDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleLetterTap(String letter) {
    final provider = context.read<WordListProvider>();
    setState(() => _selectedLetter = letter);

    final targetIndex = provider.getLetterGroupIndices()[letter];
    if (targetIndex != null && _scrollController.hasClients) {
      final viewportHeight = MediaQuery.of(context).size.height;
      final targetOffset = _calculateTargetOffset(targetIndex, viewportHeight);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleStatusChange(WordStatus status) {
    if (_centerWordIndex == null) return;

    final provider = context.read<WordListProvider>();
    provider.updateWordStatus(_centerWordIndex!, status);
    
    setState(() => _forceShowChineseIndex = _centerWordIndex);

    switch (status) {
      case WordStatus.easy:
        _scrollToNextWord();
        break;
      case WordStatus.hesitant:
      case WordStatus.difficult:
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) _scrollToNextWord();
        });
        break;
      default:
        break;
    }
  }

  void _scrollToNextWord() {
    if (_centerWordIndex == null) return;
    
    final provider = context.read<WordListProvider>();
    if (_centerWordIndex! >= provider.wordList.length - 1) return;

    final nextIndex = _centerWordIndex! + 1;
    if (_scrollController.hasClients) {
      final viewportHeight = MediaQuery.of(context).size.height;
      final targetOffset = _calculateTargetOffset(nextIndex, viewportHeight);
      _scrollController.animateTo(
        targetOffset,
        duration: _Constants.scrollDuration,
        curve: Curves.easeInOut,
      );
    }
  }
}