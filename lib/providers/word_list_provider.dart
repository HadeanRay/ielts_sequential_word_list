import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';
import '../services/excel_service.dart';

class WordListProvider with ChangeNotifier {
  final ExcelService _excelService = ExcelService();
  List<WordItem> _wordList = [];
  int _scrollPosition = 0;
  bool _isLoading = false;
  String? _error;

  List<WordItem> get wordList => _wordList;
  int get scrollPosition => _scrollPosition;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get wordCount => _wordList.length;

  // 加载单词列表
  Future<void> loadWordList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wordList = await _excelService.loadWordList();
      
      // 恢复保存的状态
      await _restoreWordStates();
      await _restoreScrollPosition();
      
    } catch (e) {
      _error = e.toString();
      _wordList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 更新单词状态
  void updateWordStatus(int index, WordStatus status) {
    if (index >= 0 && index < _wordList.length) {
      _wordList[index] = _wordList[index].copyWith(status: status);
      _saveWordState(index, status);
      notifyListeners();
    }
  }

  // 获取当前中心位置的单词索引
  int getCenterWordIndex(double scrollOffset, double viewportHeight, double itemHeight) {
    if (_wordList.isEmpty) return 0;
    
    final centerOffset = scrollOffset + viewportHeight / 2;
    final centerIndex = (centerOffset / itemHeight).round();
    
    return centerIndex.clamp(0, _wordList.length - 1);
  }

  // 设置滚动位置
  void setScrollPosition(int position) {
    _scrollPosition = position.clamp(0, _wordList.length - 1);
    _saveScrollPosition();
    notifyListeners();
  }
  
  // 更新滚动位置
  void updateScrollPosition(double offset, double itemHeight) {
    final newPosition = (offset / itemHeight).round();
    if (newPosition != _scrollPosition) {
      _scrollPosition = newPosition.clamp(0, _wordList.length - 1);
      _saveScrollPosition();
    }
  }

  // 获取首字母分组的起始索引
  Map<String, int> getLetterGroupIndices() {
    Map<String, int> indices = {};
    
    for (int i = 0; i < _wordList.length; i++) {
      final firstLetter = _wordList[i].english[0].toUpperCase();
      if (!indices.containsKey(firstLetter)) {
        indices[firstLetter] = i;
      }
    }
    
    return indices;
  }

  // 滚动到指定字母
  void scrollToLetter(String letter) {
    final indices = getLetterGroupIndices();
    final targetIndex = indices[letter.toUpperCase()];
    if (targetIndex != null) {
      setScrollPosition(targetIndex);
    }
  }

  // 保存单词状态到本地存储
  Future<void> _saveWordState(int index, WordStatus status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('word_$index', status.statusKey);
    } catch (e) {
      print('保存单词状态失败: $e');
    }
  }

  // 恢复单词状态
  Future<void> _restoreWordStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      for (int i = 0; i < _wordList.length; i++) {
        final savedStatus = prefs.getString('word_$i');
        if (savedStatus != null) {
          final status = WordStatusExtension.fromString(savedStatus);
          _wordList[i] = _wordList[i].copyWith(status: status);
        }
      }
    } catch (e) {
      print('恢复单词状态失败: $e');
    }
  }

  // 保存滚动位置
  Future<void> _saveScrollPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('scroll_position', _scrollPosition);
    } catch (e) {
      print('保存滚动位置失败: $e');
    }
  }

  // 恢复滚动位置
  Future<void> _restoreScrollPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _scrollPosition = prefs.getInt('scroll_position') ?? 0;
    } catch (e) {
      print('恢复滚动位置失败: $e');
      _scrollPosition = 0;
    }
  }

  // 清除所有数据
  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // 重置所有单词状态
      for (int i = 0; i < _wordList.length; i++) {
        _wordList[i] = _wordList[i].copyWith(status: WordStatus.defaultState);
      }
      
      _scrollPosition = 0;
      notifyListeners();
    } catch (e) {
      print('清除数据失败: $e');
    }
  }

  // 获取学习统计
  Map<WordStatus, int> getLearningStats() {
    Map<WordStatus, int> stats = {
      WordStatus.defaultState: 0,
      WordStatus.easy: 0,
      WordStatus.hesitant: 0,
      WordStatus.difficult: 0,
    };

    for (final word in _wordList) {
      stats[word.status] = (stats[word.status] ?? 0) + 1;
    }

    return stats;
  }
}