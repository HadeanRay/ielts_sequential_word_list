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
  int _originalCenterWordIndex = 0;  // 原始列表中的中心单词索引（绝对位置）
  int _filteredCenterWordIndex = 0;  // 过滤列表中的中心单词索引
  bool _isLoading = false;
  String? _error;
  WordStatus? _filterStatus; // 筛选状态
  List<WordStatus>? _combinedFilterStatuses; // 组合筛选状态



  List<WordItem> get wordList => _wordList;

  List<WordItem> get filteredWordList {
    if (_filterStatus != null) {
      // 普通筛选
      return _filteredWordList;
    } else if (_combinedFilterStatuses != null) {
      // 组合筛选
      return _wordList.where((word) => _combinedFilterStatuses!.contains(word.status)).toList();
    } else {
      // 没有筛选
      return _wordList;
    }
  }

  int get scrollPosition => _scrollPosition;

  int get centerWordIndex => _filterStatus == null ? _originalCenterWordIndex : _filteredCenterWordIndex;

  int get originalCenterWordIndex => _originalCenterWordIndex; // 绝对位置索引

  bool get isLoading => _isLoading;

  String? get error => _error;

  int get wordCount => _wordList.length;

  WordStatus? get filterStatus => _filterStatus;
  
  List<WordStatus>? get combinedFilterStatuses => _combinedFilterStatuses;

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
    _originalCenterWordIndex = await _restoreFromPrefs(_PrefsKeys.centerWordIndex, 0);
    _filteredCenterWordIndex = _originalCenterWordIndex; // 默认与原始索引相同
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
    if (_filterStatus != null) {
      // 在筛选模式下，更新过滤列表的中心索引
      _filteredCenterWordIndex = index.clamp(0, _filteredWordList.length - 1);
      
      // 同时更新原始列表的中心索引（绝对位置）
      if (index >= 0 && index < _filteredWordList.length) {
        WordItem word = _filteredWordList[index];
        int originalIndex = _wordList.indexOf(word);
        if (originalIndex != -1) {
          _originalCenterWordIndex = originalIndex;
        }
      }
    } else {
      // 在非筛选模式下，直接更新原始列表的中心索引
      _originalCenterWordIndex = index.clamp(0, _wordList.length - 1);
      _filteredCenterWordIndex = _originalCenterWordIndex;
    }

    // 保存原始中心索引到本地存储（作为绝对位置）
    _saveToPrefs(_PrefsKeys.centerWordIndex, _originalCenterWordIndex);
  }

  int getSavedCenterIndex() {
    // 总是返回原始列表中的索引，确保绝对位置
    return _originalCenterWordIndex;
  }

  Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      for (int i = 0; i < _wordList.length; i++) {
        _wordList[i] = _wordList[i].copyWith(status: WordStatus.defaultState);
      }
      
      _scrollPosition = 0;
      _originalCenterWordIndex = 0;
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

    // 保存当前的中心单词（在应用筛选之前）
    WordItem? currentCenterWord;
    if (_originalCenterWordIndex >= 0 && _originalCenterWordIndex < _wordList.length) {
      currentCenterWord = _wordList[_originalCenterWordIndex];
    }

    _filterStatus = status;

    if (status == null) {

      _filteredWordList = _wordList;

    } else {

      _filteredWordList = _wordList.where((word) => word.status == status).toList();

    }
    
    // 应用筛选后，找到当前单词在新列表中的位置
    if (currentCenterWord != null) {
      int newFilteredIndex = _filteredWordList.indexOf(currentCenterWord);
      if (newFilteredIndex != -1) {
        // 如果当前单词在筛选结果中，使用新索引
        _filteredCenterWordIndex = newFilteredIndex;
      } else {
        // 如果当前单词不在筛选结果中，设置为第一个单词
        _filteredCenterWordIndex = 0;
      }
    } else {
      // 如果没有当前中心单词，设置为第一个单词
      _filteredCenterWordIndex = 0;
    }

    notifyListeners();

  }



  void clearFilter() {

    _filterStatus = null;
    _combinedFilterStatuses = null;

    _filteredWordList = _wordList;

    notifyListeners();

  }



  bool hasFilterApplied() {

    return _filterStatus != null || _combinedFilterStatuses != null;

  }

  void applyCombinedFilter(List<WordStatus> statuses) {

    // 保存当前的中心单词（在应用筛选之前）
    WordItem? currentCenterWord;
    if (_originalCenterWordIndex >= 0 && _originalCenterWordIndex < _wordList.length) {
      currentCenterWord = _wordList[_originalCenterWordIndex];
    }

    _filterStatus = null;  // 清除普通筛选状态
    _combinedFilterStatuses = statuses.isEmpty ? null : statuses;  // 设置组合筛选状态

    if (statuses.isEmpty) {

      _filteredWordList = _wordList;

    } else {

      _filteredWordList = _wordList.where((word) => statuses.contains(word.status)).toList();

    }
    
    // 应用筛选后，找到当前单词在新列表中的位置
    if (currentCenterWord != null) {
      int newFilteredIndex = _filteredWordList.indexOf(currentCenterWord);
      if (newFilteredIndex != -1) {
        // 如果当前单词在筛选结果中，使用新索引
        _filteredCenterWordIndex = newFilteredIndex;
      } else {
        // 如果当前单词不在筛选结果中，设置为第一个单词
        _filteredCenterWordIndex = 0;
      }
    } else {
      // 如果没有当前中心单词，设置为第一个单词
      _filteredCenterWordIndex = 0;
    }

    notifyListeners();

  }



  int get filteredWordCount {

    return _filteredWordList.length;

  }

}