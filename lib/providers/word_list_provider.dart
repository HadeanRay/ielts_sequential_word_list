import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_item.dart';
import '../models/word_status.dart';
import '../services/excel_service.dart';

class _PrefsKeys {
  static const String wordState = 'word_';
  static const String scrollPosition = 'scroll_position';
  static const String centerWordIndex = 'center_word_index';
}

class WordListProvider with ChangeNotifier {
  final ExcelService _excelService = ExcelService();
  List<WordItem> _wordList = [];
  int _scrollPosition = 0;
  int _centerWordIndex = 0;
  bool _isLoading = false;
  String? _error;

  List<WordItem> get wordList => _wordList;
  int get scrollPosition => _scrollPosition;
  int get centerWordIndex => _centerWordIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get wordCount => _wordList.length;

  Future<void> loadWordList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wordList = await _excelService.loadWordList();
      await _restoreAllData();
    } catch (e) {
      _error = e.toString();
      _wordList = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreAllData() async {
    await _restoreWordStates();
    _scrollPosition = await _restoreFromPrefs(_PrefsKeys.scrollPosition, 0);
    _centerWordIndex = await _restoreFromPrefs(_PrefsKeys.centerWordIndex, 0);
  }

  void updateWordStatus(int index, WordStatus status) {
    if (index >= 0 && index < _wordList.length) {
      _wordList[index] = _wordList[index].copyWith(status: status);
      _saveToPrefs('${_PrefsKeys.wordState}$index', status.statusKey);
      notifyListeners();
    }
  }

  int getCenterWordIndex(double scrollOffset, double viewportHeight, double itemHeight) {
    if (_wordList.isEmpty) return 0;
    final centerOffset = scrollOffset + viewportHeight / 2;
    return (centerOffset / itemHeight).round().clamp(0, _wordList.length - 1);
  }

  void setScrollPosition(int position) {
    _scrollPosition = position.clamp(0, _wordList.length - 1);
    _saveToPrefs(_PrefsKeys.scrollPosition, _scrollPosition);
    notifyListeners();
  }

  void updateScrollPosition(double offset, double itemHeight) {
    final newPosition = (offset / itemHeight).round();
    if (newPosition != _scrollPosition) {
      _scrollPosition = newPosition.clamp(0, _wordList.length - 1);
      _saveToPrefs(_PrefsKeys.scrollPosition, _scrollPosition);
    }
  }

  Map<String, int> getLetterGroupIndices() {
    final indices = <String, int>{};
    for (int i = 0; i < _wordList.length; i++) {
      final firstLetter = _wordList[i].english[0].toUpperCase();
      indices.putIfAbsent(firstLetter, () => i);
    }
    return indices;
  }

  void scrollToLetter(String letter) {
    final targetIndex = getLetterGroupIndices()[letter.toUpperCase()];
    if (targetIndex != null) {
      setScrollPosition(targetIndex);
    }
  }

  Future<void> _saveToPrefs(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
    } catch (e) {
      debugPrint('保存数据失败: $e');
    }
  }

  Future<T> _restoreFromPrefs<T>(String key, T defaultValue) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (defaultValue is int) {
        return prefs.getInt(key) as T? ?? defaultValue;
      }
      return defaultValue;
    } catch (e) {
      debugPrint('恢复数据失败: $e');
      return defaultValue;
    }
  }

  Future<void> _restoreWordStates() async {
    final prefs = await SharedPreferences.getInstance();
    for (int i = 0; i < _wordList.length; i++) {
      final savedStatus = prefs.getString('${_PrefsKeys.wordState}$i');
      if (savedStatus != null) {
        _wordList[i] = _wordList[i].copyWith(
          status: WordStatusExtension.fromString(savedStatus),
        );
      }
    }
  }

  void updateCenterWordIndex(int index) {
    if (index >= 0 && index < _wordList.length) {
      _centerWordIndex = index.clamp(0, _wordList.length - 1);
      _saveToPrefs(_PrefsKeys.centerWordIndex, _centerWordIndex);
    }
  }

  int getSavedCenterIndex() => _centerWordIndex;

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      for (int i = 0; i < _wordList.length; i++) {
        _wordList[i] = _wordList[i].copyWith(status: WordStatus.defaultState);
      }
      
      _scrollPosition = 0;
      _centerWordIndex = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('清除数据失败: $e');
    }
  }

  Map<WordStatus, int> getLearningStats() {
    final stats = <WordStatus, int>{
      for (var status in WordStatus.values) status: 0,
    };
    
    for (final word in _wordList) {
      stats[word.status] = stats[word.status]! + 1;
    }
    
    return stats;
  }
}