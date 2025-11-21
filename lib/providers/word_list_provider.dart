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

  List<WordItem> _filteredWordList = [];

  int _scrollPosition = 0;

  int _centerWordIndex = 0;

  bool _isLoading = false;

  String? _error;

  WordStatus? _filterStatus; // 筛选状态



  List<WordItem> get wordList => _wordList;

  List<WordItem> get filteredWordList => _filterStatus == null ? _wordList : _filteredWordList;

  int get scrollPosition => _scrollPosition;

  int get centerWordIndex => _centerWordIndex;

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get wordCount => _wordList.length;

  WordStatus? get filterStatus => _filterStatus;

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

    List<WordItem> listToUse = _filterStatus == null ? _wordList : _filteredWordList;

    for (int i = 0; i < listToUse.length; i++) {

      final firstLetter = listToUse[i].english[0].toUpperCase();

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

    // 如果有筛选，需要将过滤列表中的索引转换为原始列表中的索引

    int actualIndex;

    if (_filterStatus != null && index >= 0 && index < _filteredWordList.length) {

      // 在过滤列表中找到对应原始列表的索引

      WordItem word = _filteredWordList[index];

      actualIndex = _wordList.indexOf(word);

    } else {

      actualIndex = index.clamp(0, _wordList.length - 1);

    }



    if (actualIndex >= 0 && actualIndex < _wordList.length) {

      _centerWordIndex = actualIndex;

      _saveToPrefs(_PrefsKeys.centerWordIndex, _centerWordIndex);

    }

  }

  int getSavedCenterIndex() {

    if (_filterStatus != null && _centerWordIndex >= 0 && _centerWordIndex < _wordList.length) {

      // 如果有筛选，查找原始索引在过滤列表中的位置

      WordItem centerWord = _wordList[_centerWordIndex];

      int filteredIndex = _filteredWordList.indexOf(centerWord);

      return filteredIndex >= 0 ? filteredIndex : 0;

    }

    return _centerWordIndex;

  }

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



  void applyFilter(WordStatus? status) {

    _filterStatus = status;

    if (status == null) {

      _filteredWordList = _wordList;

    } else {

      _filteredWordList = _wordList.where((word) => word.status == status).toList();

    }

    notifyListeners();

  }



  void clearFilter() {

    _filterStatus = null;

    _filteredWordList = _wordList;

    notifyListeners();

  }



  bool hasFilterApplied() {

    return _filterStatus != null;

  }



  int get filteredWordCount {

    return _filteredWordList.length;

  }

}