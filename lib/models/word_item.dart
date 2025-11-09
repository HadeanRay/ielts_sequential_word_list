import 'word_status.dart';

class WordItem {
  final String english;
  final String chinese;
  WordStatus status;
  final int index;

  WordItem({
    required this.english,
    required this.chinese,
    this.status = WordStatus.defaultState,
    required this.index,
  });

  WordItem copyWith({
    String? english,
    String? chinese,
    WordStatus? status,
    int? index,
  }) {
    return WordItem(
      english: english ?? this.english,
      chinese: chinese ?? this.chinese,
      status: status ?? this.status,
      index: index ?? this.index,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'chinese': chinese,
      'status': status.statusKey,
      'index': index,
    };
  }

  factory WordItem.fromJson(Map<String, dynamic> json) {
    return WordItem(
      english: json['english'] ?? '',
      chinese: json['chinese'] ?? '',
      status: WordStatusExtension.fromString(json['status'] ?? 'defaultState'),
      index: json['index'] ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordItem &&
        other.english == english &&
        other.index == index;
  }

  @override
  int get hashCode => english.hashCode ^ index.hashCode;
}