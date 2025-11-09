enum WordStatus {
  defaultState,
  easy,
  hesitant,
  difficult,
}

extension WordStatusExtension on WordStatus {
  String get displayName {
    switch (this) {
      case WordStatus.defaultState:
        return 'Default';
      case WordStatus.easy:
        return 'Easy';
      case WordStatus.hesitant:
        return 'Hesitant';
      case WordStatus.difficult:
        return 'Difficult';
    }
  }

  int get colorValue {
    switch (this) {
      case WordStatus.defaultState:
        return 0xFF9E9E9E; // 灰色
      case WordStatus.easy:
        return 0xFF4CAF50; // 绿色
      case WordStatus.hesitant:
        return 0xFFFFEB3B; // 黄色
      case WordStatus.difficult:
        return 0xFFF44336; // 红色
    }
  }

  bool get shouldDisplayChinese {
    return this != WordStatus.defaultState;
  }

  String get statusKey {
    return toString().split('.').last;
  }

  static WordStatus fromString(String status) {
    switch (status) {
      case 'defaultState':
        return WordStatus.defaultState;
      case 'easy':
        return WordStatus.easy;
      case 'hesitant':
        return WordStatus.hesitant;
      case 'difficult':
        return WordStatus.difficult;
      default:
        return WordStatus.defaultState;
    }
  }
}