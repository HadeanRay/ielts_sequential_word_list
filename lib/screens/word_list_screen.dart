import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';
import '../providers/word_list_provider.dart';
import '../widgets/letter_navigation_bar.dart';
import '../widgets/picker_scroll_view.dart';
import '../widgets/progress_indicator.dart';
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

    // 始终使用原始列表中的绝对索引
    final savedIndex = provider.getSavedCenterIndex(); // 这是原始列表中的索引
    final originalClampedIndex = savedIndex.clamp(0, provider.wordList.length - 1);
    
    // 如果当前有筛选，需要将原始索引转换为筛选列表中的索引
    int displayIndex = originalClampedIndex;
    if (provider.hasFilterApplied()) {
      WordItem centerWord = provider.wordList[originalClampedIndex];
      displayIndex = provider.filteredWordList.indexOf(centerWord);
      // 如果筛选后单词不在列表中，使用第一个单词
      if (displayIndex == -1) {
        displayIndex = 0;
      }
    }
    
    setState(() {
      _centerWordIndex = displayIndex;
      _isRestoringPosition = true;
    });

    // 延迟执行滚动以确保widget已经构建完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final viewportHeight = MediaQuery.of(context).size.height;
        final targetOffset = _calculateTargetOffset(displayIndex, viewportHeight);
        _scrollController.jumpTo(targetOffset);
        
        setState(() {
          _isRestoringPosition = false;
        });
      }
    });
  }

  double _calculateTargetOffset(int index, double viewportHeight) {

    // 计算每边需要添加的空白项数量（屏幕高度能容纳的单词数量除以2）
    final itemsPerScreen = (viewportHeight / _Constants.itemHeight).round();
    final paddingItems = (itemsPerScreen / 2).ceil();
    
    // 调整目标偏移量以考虑前导空白项
    final centerOffset = (index + paddingItems) * _Constants.itemHeight;

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

              letterIndices: provider.hasFilterApplied() ? {} : provider.getLetterGroupIndices(),

              selectedLetter: _selectedLetter,

              onLetterTap: _handleLetterTap,

            ),

            // 右侧单词选择器
            Expanded(

              child: PickerScrollView(



                controller: _scrollController,



                itemCount: provider.filteredWordList.length,



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



                  final word = provider.filteredWordList[index];



                  return _buildWordItem(word, isCenter, showChinese);



                },



              ),

            ),
          ],
        ),

        // 右上角进度指示器
        ProgressIndicatorWidget(
          provider: provider,
          centerWordIndex: _centerWordIndex,
        ),

        // 底部状态按钮

        StatusActionButtons(

          onEasyPressed: () => _handleStatusChange(WordStatus.easy),

          onHesitantPressed: () => _handleStatusChange(WordStatus.hesitant),

          onDifficultPressed: () => _handleStatusChange(WordStatus.difficult),

          onFilterPressed: () => _showFilterMenu(),

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

    // 根据是否有筛选应用，使用不同的列表来查找索引

    final index = provider.hasFilterApplied() 

        ? provider.filteredWordList.indexOf(word) 

        : provider.wordList.indexOf(word);

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



    // 如果有筛选，则不能按字母跳转，因为筛选后的列表可能不包含该字母

    if (provider.hasFilterApplied()) {

      // 显示提示信息

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(content: Text('当前已应用筛选，无法按字母跳转')),

      );

      return;

    }



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
    // 使用filteredWordList来获取当前单词
    if (_centerWordIndex! < provider.filteredWordList.length) {
      final currentWord = provider.filteredWordList[_centerWordIndex!];
      // 通过原始列表的索引来更新状态
      int originalIndex = provider.wordList.indexOf(currentWord);
      if (originalIndex != -1) {
        provider.updateWordStatus(originalIndex, status);
      }
    }
    
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

    final listLength = provider.hasFilterApplied() ? provider.filteredWordList.length : provider.wordList.length;

    if (_centerWordIndex! >= listLength - 1) return;



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



  int _findClosestWordIndexInFilteredList(List<WordItem> fullList, List<WordItem> filteredList, int originalIndex) {
    if (filteredList.isEmpty) return 0;
    if (originalIndex < 0 || originalIndex >= fullList.length) return 0;

    // 获取当前单词在原始列表中的位置
    WordItem currentWord = fullList[originalIndex];

    // 检查当前单词是否在筛选列表中
    int indexInFilteredList = filteredList.indexOf(currentWord);
    if (indexInFilteredList != -1) {
      return indexInFilteredList;
    }

    // 如果当前单词不在筛选列表中，找到原始列表中离它最近的单词在筛选列表中的位置
    int minDistance = fullList.length;
    int closestFilteredListIndex = 0;

    for (int i = 0; i < filteredList.length; i++) {
      WordItem filteredWord = filteredList[i];
      int originalListIndex = fullList.indexOf(filteredWord);
      if (originalListIndex != -1) {
        int distance = (originalListIndex - originalIndex).abs();
        if (distance < minDistance) {
          minDistance = distance;
          closestFilteredListIndex = i;
        }
      }
    }

    return closestFilteredListIndex;
  }

  void _showFilterMenu() {

    final provider = context.read<WordListProvider>();

    showModalBottomSheet<void>(

      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(

        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),

      ),

      builder: (BuildContext context) {

        return StatefulBuilder(

          builder: (BuildContext context, StateSetter setState) {

            return Container(

              padding: const EdgeInsets.all(20),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  const Text(

                    '筛选单词',

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),

                  ),

                  const SizedBox(height: 16),

                  RadioListTile<WordStatus?>(

                    title: const Text('全部'),

                    value: null,

                    groupValue: provider.filterStatus,

                    onChanged: (WordStatus? value) async {

                      // 在应用筛选前保存当前中心单词
                      WordItem? currentWord;
                      if (_centerWordIndex != null && _centerWordIndex! < provider.filteredWordList.length) {
                        currentWord = provider.filteredWordList[_centerWordIndex!];
                      }

                      provider.clearFilter();

                      // 等待UI更新后，找到之前的单词在新列表中的位置
                      await Future.delayed(Duration.zero);
                      if (currentWord != null && mounted) {
                        int newCenterIndex = provider.wordList.indexOf(currentWord);
                        if (newCenterIndex != -1) {
                          // 更新UI的中心索引
                          setState(() {
                            _centerWordIndex = newCenterIndex;
                          });

                          // 滚动到新位置
                          if (_scrollController.hasClients) {
                            final viewportHeight = MediaQuery.of(context).size.height;
                            final targetOffset = _calculateTargetOffset(newCenterIndex, viewportHeight);
                            _scrollController.animateTo(
                              targetOffset,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      }
                      Navigator.pop(context);

                    },

                  ),

                  RadioListTile<WordStatus?>(

                    title: const Text('未学习'),

                    value: WordStatus.defaultState,

                    groupValue: provider.filterStatus,

                    onChanged: (WordStatus? value) async {

                      if (value != null) {

                        // 在应用筛选前保存当前中心单词
                        WordItem? currentWord;
                        if (_centerWordIndex != null && _centerWordIndex! < provider.filteredWordList.length) {
                          currentWord = provider.filteredWordList[_centerWordIndex!];
                        }

                        provider.applyFilter(value);

                        // 等待UI更新后，找到之前的单词在新列表中的位置
                        await Future.delayed(Duration.zero);
                        if (currentWord != null && mounted) {
                          int newCenterIndex = provider.filteredWordList.indexOf(currentWord);
                          if (newCenterIndex != -1) {
                            // 更新UI的中心索引
                            setState(() {
                              _centerWordIndex = newCenterIndex;
                            });

                            // 滚动到新位置
                            if (_scrollController.hasClients) {
                              final viewportHeight = MediaQuery.of(context).size.height;
                              final targetOffset = _calculateTargetOffset(newCenterIndex, viewportHeight);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          } else if (provider.filteredWordList.isNotEmpty) {
                            // 如果当前单词不在筛选结果中，滚动到最近的单词
                            int originalIndex = provider.originalCenterWordIndex;
                            int closestIndex = _findClosestWordIndexInFilteredList(provider.wordList, provider.filteredWordList, originalIndex);
                            setState(() {
                              _centerWordIndex = closestIndex;
                            });

                            if (_scrollController.hasClients) {
                              final viewportHeight = MediaQuery.of(context).size.height;
                              final targetOffset = _calculateTargetOffset(closestIndex, viewportHeight);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        }
                        Navigator.pop(context);

                      }

                    },

                  ),

                  RadioListTile<WordStatus?>(

                    title: const Text('简单'),

                    value: WordStatus.easy,

                    groupValue: provider.filterStatus,

                    onChanged: (WordStatus? value) async {

                      if (value != null) {

                        // 在应用筛选前保存当前中心单词
                        WordItem? currentWord;
                        if (_centerWordIndex != null && _centerWordIndex! < provider.filteredWordList.length) {
                          currentWord = provider.filteredWordList[_centerWordIndex!];
                        }

                        provider.applyFilter(value);

                        // 等待UI更新后，找到之前的单词在新列表中的位置
                        await Future.delayed(Duration.zero);
                        if (currentWord != null && mounted) {
                          int newCenterIndex = provider.filteredWordList.indexOf(currentWord);
                          if (newCenterIndex != -1) {
                            // 更新UI的中心索引
                            setState(() {
                              _centerWordIndex = newCenterIndex;
                            });

                            // 滚动到新位置
                            if (_scrollController.hasClients) {
                              final viewportHeight = MediaQuery.of(context).size.height;
                              final targetOffset = _calculateTargetOffset(newCenterIndex, viewportHeight);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          } else if (provider.filteredWordList.isNotEmpty) {
                            // 如果当前单词不在筛选结果中，滚动到最近的单词
                            int originalIndex = provider.originalCenterWordIndex;
                            int closestIndex = _findClosestWordIndexInFilteredList(provider.wordList, provider.filteredWordList, originalIndex);
                            setState(() {
                              _centerWordIndex = closestIndex;
                            });

                            if (_scrollController.hasClients) {
                              final viewportHeight = MediaQuery.of(context).size.height;
                              final targetOffset = _calculateTargetOffset(closestIndex, viewportHeight);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        }
                        Navigator.pop(context);

                      }

                    },

                  ),

                  RadioListTile<WordStatus?>(

                    title: const Text('犹豫+困难'),

                    value: WordStatus.hesitant, // 保持WordStatus.hesitant作为标识，但实际执行组合筛选

                    groupValue: provider.filterStatus,

                    onChanged: (WordStatus? value) async {

                      if (value != null) {

                        // 在应用筛选前保存当前中心单词
                        WordItem? currentWord;
                        if (_centerWordIndex != null && _centerWordIndex! < provider.filteredWordList.length) {
                          currentWord = provider.filteredWordList[_centerWordIndex!];
                        }

                        // 应用组合筛选：犹豫+困难
                        provider.applyCombinedFilter([WordStatus.hesitant, WordStatus.difficult]);

                        // 等待UI更新后，找到之前的单词在新列表中的位置
                        await Future.delayed(Duration.zero);
                        if (currentWord != null && mounted) {
                          int newCenterIndex = provider.filteredWordList.indexOf(currentWord);
                          if (newCenterIndex != -1) {
                            // 更新UI的中心索引
                            setState(() {
                              _centerWordIndex = newCenterIndex;
                            });

                            // 滚动到新位置
                            if (_scrollController.hasClients) {
                              final viewportHeight = MediaQuery.of(context).size.height;
                              final targetOffset = _calculateTargetOffset(newCenterIndex, viewportHeight);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          } else if (provider.filteredWordList.isNotEmpty) {
                            // 如果当前单词不在筛选结果中，滚动到最近的单词
                            int originalIndex = provider.originalCenterWordIndex;
                            int closestIndex = _findClosestWordIndexInFilteredList(provider.wordList, provider.filteredWordList, originalIndex);
                            setState(() {
                              _centerWordIndex = closestIndex;
                            });

                            if (_scrollController.hasClients) {
                              final viewportHeight = MediaQuery.of(context).size.height;
                              final targetOffset = _calculateTargetOffset(closestIndex, viewportHeight);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        }
                        Navigator.pop(context);

                      }

                    },

                  ),

                  RadioListTile<WordStatus?>(

                    title: const Text('困难'),

                    value: WordStatus.difficult,

                    groupValue: provider.filterStatus,

                    onChanged: (WordStatus? value) async {

                      if (value != null) {

                        // 在应用筛选前保存当前中心单词
                        WordItem? currentWord;
                        if (_centerWordIndex != null && _centerWordIndex! < provider.filteredWordList.length) {
                          currentWord = provider.filteredWordList[_centerWordIndex!];
                        }

                        provider.applyFilter(value);

                        // 等待UI更新后，找到之前的单词在新列表中的位置
                        await Future.delayed(Duration.zero);
                        if (currentWord != null && mounted) {
                          int newCenterIndex = provider.filteredWordList.indexOf(currentWord);
                          if (newCenterIndex != -1) {
                            // 更新UI的中心索引
                            setState(() {
                              _centerWordIndex = newCenterIndex;
                            });

                            // 滚动到新位置
                            if (_scrollController.hasClients) {
                              final viewportHeight = MediaQuery.of(context).size.height;
                              final targetOffset = _calculateTargetOffset(newCenterIndex, viewportHeight);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          } else if (provider.filteredWordList.isNotEmpty) {
                            // 如果当前单词不在筛选结果中，滚动到最近的单词
                            int originalIndex = provider.originalCenterWordIndex;
                            int closestIndex = _findClosestWordIndexInFilteredList(provider.wordList, provider.filteredWordList, originalIndex);
                            setState(() {
                              _centerWordIndex = closestIndex;
                            });

                            if (_scrollController.hasClients) {
                              final viewportHeight = MediaQuery.of(context).size.height;
                              final targetOffset = _calculateTargetOffset(closestIndex, viewportHeight);
                              _scrollController.animateTo(
                                targetOffset,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          }
                        }
                        Navigator.pop(context);

                      }

                    },

                  ),

                  const SizedBox(height: 16),

                  ListTile(

                    title: const Text('回到今天首次打开的位置'),

                    leading: const Icon(Icons.today, color: Colors.blue),

                    onTap: () async {

                      // 调用Provider中的方法回到今天首次打开的位置
                      await provider.goToTodayFirstOpenIndex();

                      // 找到今天首次打开的单词在当前显示列表中的位置
                      int targetIndex = provider.todayFirstOpenIndex;
                      if (provider.hasFilterApplied()) {
                        // 如果有筛选，需要找到在筛选列表中的位置
                        if (targetIndex >= 0 && targetIndex < provider.wordList.length) {
                          WordItem targetWord = provider.wordList[targetIndex];
                          int filteredIndex = provider.filteredWordList.indexOf(targetWord);
                          if (filteredIndex != -1) {
                            targetIndex = filteredIndex;
                          } else {
                            // 如果目标单词不在筛选结果中，滚动到第一个单词
                            targetIndex = 0;
                          }
                        }
                      }

                      // 更新UI的中心索引
                      setState(() {
                        _centerWordIndex = targetIndex;
                      });

                      // 滚动到目标位置
                      if (_scrollController.hasClients) {
                        final viewportHeight = MediaQuery.of(context).size.height;
                        final targetOffset = _calculateTargetOffset(targetIndex, viewportHeight);
                        _scrollController.animateTo(
                          targetOffset,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }

                      Navigator.pop(context);

                    },

                  ),

                  const SizedBox(height: 16),

                  ElevatedButton(

                    onPressed: () async {

                      // 在应用筛选前保存当前中心单词
                      WordItem? currentWord;
                      if (_centerWordIndex != null && _centerWordIndex! < provider.filteredWordList.length) {
                        currentWord = provider.filteredWordList[_centerWordIndex!];
                      }

                      provider.clearFilter();

                      // 等待UI更新后，找到之前的单词在新列表中的位置
                      await Future.delayed(Duration.zero);
                      if (currentWord != null && mounted) {
                        int newCenterIndex = provider.wordList.indexOf(currentWord);
                        if (newCenterIndex != -1) {
                          // 更新UI的中心索引
                          setState(() {
                            _centerWordIndex = newCenterIndex;
                          });

                          // 滚动到新位置
                          if (_scrollController.hasClients) {
                            final viewportHeight = MediaQuery.of(context).size.height;
                            final targetOffset = _calculateTargetOffset(newCenterIndex, viewportHeight);
                            _scrollController.animateTo(
                              targetOffset,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      }
                      Navigator.pop(context);

                    },

                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.red,

                      foregroundColor: Colors.white,

                    ),

                    child: const Text('清除筛选'),

                  ),

                  const SizedBox(height: 20),

                ],

              ),

            );

          },

        );

      },

    );

  }

}