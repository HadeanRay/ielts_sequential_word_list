import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart';
import '../models/word_item.dart';

class ExcelService {
  static const String excelPath = 'assets/words/ielts.xls';
  static const String csvPath = 'assets/words/ielts-main.csv';

  Future<List<WordItem>> loadWordList() async {
    try {
      // 首先尝试加载CSV文件
      final csvData = await _loadCsvFile();
      if (csvData.isNotEmpty) {
        return csvData;
      }
      
      // 如果CSV文件为空，尝试Excel文件
      final excelData = await _loadExcelFile();
      if (excelData.isNotEmpty) {
        return excelData;
      }
      
      throw Exception('无法加载任何数据文件');
    } catch (e) {
      print('读取文件失败: $e');
      // 返回示例数据作为备选方案
      return _getSampleData();
    }
  }

  Future<List<WordItem>> _loadCsvFile() async {
    try {
      final String csvContent = await rootBundle.loadString(csvPath);
      final List<WordItem> wordList = [];
      
      final lines = csvContent.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        
        final parts = line.split(',');
        if (parts.length >= 2) {
          final english = parts[0].trim();
          String chinese = '';
          
          // 根据文件类型解析不同格式
          if (csvPath.contains('ielts-main')) {
            // ielts-main.csv 格式: english,词性中文释义
            // 词性标识通常在释义的开头，如 "vt. 抛弃;放弃"，我们需要保留这些释义
            chinese = parts.sublist(1).join(',').trim(); // 将所有剩余部分连接起来作为释义
          } else {
            // ielts.csv 格式: english,中文释义1,中文释义2
            chinese = parts.sublist(1).join(',').trim();
          }
          
          if (english.isNotEmpty && chinese.isNotEmpty) {
            // 移除中文释义前后的不匹配引号（如果存在）
            String cleanChinese = chinese.trim();
            if (cleanChinese.startsWith('"') && cleanChinese.length > 1) {
              cleanChinese = cleanChinese.substring(1); // 移除开头的引号
            }
            if (cleanChinese.endsWith('"') && cleanChinese.length > 1) {
              cleanChinese = cleanChinese.substring(0, cleanChinese.length - 1); // 移除结尾的引号
            }
            
            wordList.add(WordItem(
              english: english,
              chinese: cleanChinese,
              index: wordList.length,
            ));
          }
        }
      }
      
      if (wordList.isEmpty) {
        throw Exception('CSV文件为空或格式错误');
      }
      
      return wordList;
    } catch (e) {
      print('读取CSV文件失败: $e');
      return [];
    }
  }

  Future<List<WordItem>> _loadExcelFile() async {
    try {
      // 加载Excel文件
      final ByteData data = await rootBundle.load(excelPath);
      final bytes = data.buffer.asUint8List();
      final excel = Excel.decodeBytes(bytes);

      List<WordItem> wordList = [];

      // 读取第一个工作表
      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        throw Exception('Excel文件为空或格式错误');
      }

      // 跳过标题行，从第二行开始读取
      for (int i = 1; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        
        if (row.isEmpty) continue;
        
        final english = row[0]?.value?.toString() ?? '';
        final chinese = row[1]?.value?.toString() ?? '';

        if (english.isNotEmpty) {
          // 移除中文释义前后的不匹配引号（如果存在）
          String cleanChinese = chinese.trim();
          if (cleanChinese.startsWith('"') && cleanChinese.length > 1) {
            cleanChinese = cleanChinese.substring(1); // 移除开头的引号
          }
          if (cleanChinese.endsWith('"') && cleanChinese.length > 1) {
            cleanChinese = cleanChinese.substring(0, cleanChinese.length - 1); // 移除结尾的引号
          }
          
          wordList.add(WordItem(
            english: english.trim(),
            chinese: cleanChinese,
            index: wordList.length,
          ));
        }
      }

      if (wordList.isEmpty) {
        throw Exception('未找到有效的单词数据');
      }

      return wordList;
    } catch (e) {
      print('读取Excel文件失败: $e');
      return [];
    }
  }

  List<WordItem> _getSampleData() {
    return [
      WordItem(english: 'abandon', chinese: '放弃, 抛弃', index: 0),
      WordItem(english: 'ability', chinese: '能力, 才智', index: 1),
      WordItem(english: 'able', chinese: '能够的, 有能力的', index: 2),
      WordItem(english: 'about', chinese: '关于, 大约', index: 3),
      WordItem(english: 'above', chinese: '在上面, 超过', index: 4),
      WordItem(english: 'abroad', chinese: '在国外, 到国外', index: 5),
      WordItem(english: 'absence', chinese: '缺席, 缺乏', index: 6),
      WordItem(english: 'absent', chinese: '缺席的, 缺少的', index: 7),
      WordItem(english: 'absolute', chinese: '绝对的, 完全的', index: 8),
      WordItem(english: 'absolutely', chinese: '绝对地, 完全地', index: 9),
      WordItem(english: 'absorb', chinese: '吸收, 专注', index: 10),
      WordItem(english: 'abstract', chinese: '抽象的, 摘要', index: 11),
      WordItem(english: 'abundant', chinese: '丰富的, 充裕的', index: 12),
      WordItem(english: 'abuse', chinese: '滥用, 虐待', index: 13),
      WordItem(english: 'academic', chinese: '学术的, 理论的', index: 14),
      WordItem(english: 'academy', chinese: '学院, 学会', index: 15),
      WordItem(english: 'accept', chinese: '接受, 承认', index: 16),
      WordItem(english: 'acceptable', chinese: '可接受的, 令人满意的', index: 17),
      WordItem(english: 'acceptance', chinese: '接受, 承认', index: 18),
      WordItem(english: 'access', chinese: '进入, 接近', index: 19),
    ];
  }

  // 验证文件格式
  Future<bool> validateDataFile() async {
    try {
      // 首先检查CSV文件
      try {
        final String csvContent = await rootBundle.loadString(csvPath);
        if (csvContent.isNotEmpty) {
          return true;
        }
      } catch (e) {
        // CSV文件不存在，继续检查Excel文件
      }
      
      // 检查Excel文件
      final ByteData data = await rootBundle.load(excelPath);
      final bytes = data.buffer.asUint8List();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) return false;

      final sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null || sheet.maxRows < 2) return false;

      return true;
    } catch (e) {
      print('验证数据文件失败: $e');
      return false;
    }
  }
}
