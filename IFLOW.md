# IELTS 顺序词表应用 - iFlow 指令文档

## 项目概述

这是一个基于Flutter开发的移动应用，专门用于雅思(IELTS)顺序词表学习。应用采用现代化的UI设计和直观的状态管理，帮助用户系统性地学习和记忆雅思单词。

### 核心特性
- **顺序学习**: 按字母顺序排列的雅思核心词汇
- **状态跟踪**: 四种学习状态（默认、简单、犹豫、困难）
- **进度保存**: 自动保存学习进度和滚动位置
- **快速导航**: 左侧字母导航栏，支持快速跳转
- **中心高亮**: 自动检测并高亮当前中心位置的单词
- **数据持久化**: 使用SharedPreferences本地存储
- **多格式支持**: 支持CSV和Excel格式的单词数据文件
- **智能数据加载**: 优先加载CSV文件，回退到Excel文件或示例数据

## 技术架构

### 开发环境
- **Flutter版本**: 3.9.2+
- **Dart版本**: 3.0+
- **平台支持**: Android, iOS, Web, Windows, macOS, Linux

### 核心依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2          # 状态管理
  shared_preferences: ^2.2.2 # 本地存储
  excel: ^2.1.0             # Excel文件处理
  permission_handler: ^11.0.1 # 权限管理
  path_provider: ^2.1.1      # 路径获取

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0     # 代码规范检查
```

### 架构模式
- **状态管理**: Provider模式
- **数据层**: Service层分离
- **UI层**: Widget组件化
- **模型层**: 数据模型和状态枚举

## 目录结构

```
lib/
├── main.dart                    # 应用入口
├── models/                      # 数据模型
│   ├── word_item.dart          # 单词项模型
│   └── word_status.dart        # 学习状态枚举
├── providers/                   # 状态管理
│   └── word_list_provider.dart # 单词列表状态管理
├── screens/                     # 界面屏幕
│   └── word_list_screen.dart   # 主界面
├── services/                    # 服务层
│   └── excel_service.dart      # Excel数据服务
└── widgets/                     # UI组件
    ├── word_list_item.dart     # 单词列表项
    ├── letter_navigation_bar.dart # 字母导航栏
    ├── picker_scroll_view.dart # 滚动选择器视图
    └── status_action_buttons.dart # 状态操作按钮

assets/
├── words/
│   ├── ielts-main.csv         # 单词数据(CSV格式，优先加载)
│   ├── ielts.csv              # 单词数据(CSV格式，备用)
│   └── ielts.xls              # 单词数据(Excel格式，最后回退)
└── icons/                     # 应用图标资源
```

## 核心功能实现

### 1. 数据管理 (WordListProvider)

**主要职责**:
- 加载和管理单词列表数据
- 维护学习状态和滚动位置
- 提供状态持久化功能
- 计算学习统计数据
- 管理中心单词索引

**关键方法**:
```dart
// 加载单词列表
Future<void> loadWordList()

// 更新单词状态
void updateWordStatus(int index, WordStatus status)

// 获取中心位置单词索引
int getCenterWordIndex(double scrollOffset, double viewportHeight, double itemHeight)

// 设置滚动位置
void setScrollPosition(int position)

// 更新滚动位置
void updateScrollPosition(double offset, double itemHeight)

// 滚动到指定字母
void scrollToLetter(String letter)

// 更新中心单词索引
void updateCenterWordIndex(int index)

// 获取中心单词索引（用于初始化恢复）
int getSavedCenterIndex()

// 获取学习统计
Map<WordStatus, int> getLearningStats()

// 清除所有数据
Future<void> clearAllData()
```

**状态持久化**:
- 单词状态: `SharedPreferences`存储，键格式为`word_${index}`
- 滚动位置: `scroll_position`键保存
- 中心单词索引: `center_word_index`键保存
- 自动恢复: 应用启动时自动加载保存的数据

### 2. 数据服务 (ExcelService)

**数据加载策略**:
1. 首先尝试加载CSV文件 (`assets/words/ielts-main.csv`)
2. 如果第一个CSV文件为空或错误，尝试备用CSV文件 (`assets/words/ielts.csv`)
3. 如果CSV文件都失败，尝试Excel文件 (`assets/words/ielts.xls`)
4. 如果都失败，返回示例数据作为备选方案

**支持的数据格式**:
- **CSV格式 (ielts-main.csv)**: `english,词性中文释义` 每行一个单词，会智能解析词性标识
- **CSV格式 (ielts.csv)**: `english,中文释义1,中文释义2` 每行一个单词
- **Excel格式**: 第一列为英文单词，第二列为中文释义
- **示例数据**: 包含20个基础雅思单词

### 3. 学习状态系统 (WordStatus)

**四种学习状态**:

| 状态 | 颜色值 | 显示中文 | 状态键 | 用途 |
|------|--------|----------|--------|------|
| 默认 | #9E9E9E (灰色) | ✗ | `defaultState` | 尚未学习的单词 |
| 简单 | #4CAF50 (绿色) | ✓ | `easy` | 已掌握且简单的单词 |
| 犹豫 | #FFEB3B (黄色) | ✓ | `hesitant` | 需要再次复习的单词 |
| 困难 | #F44336 (红色) | ✓ | `difficult` | 难以掌握的单词 |

**状态行为**:
- 只有非默认状态才显示中文释义
- 状态改变时自动保存到本地存储
- 支持状态序列化和反序列化

### 4. 用户界面设计

#### 主界面布局 (WordListScreen)
- **双栏布局**: 左侧导航栏(32px) + 右侧内容区
- **堆叠设计**: 主内容 + 底部操作按钮
- **响应式**: 根据屏幕高度动态计算

#### 单词列表项 (WordListItem)
- **三栏布局**: 英文单词(2份) + 中文释义(3份)
- **中心高亮**: 蓝色背景和边框突出显示
- **状态指示器**: 颜色标识，根据状态改变显示效果

#### 字母导航栏 (LetterNavigationBar)
- **A-Z字母列表**: 显示有单词的字母，无单词的显示为灰色
- **快速导航**: 点击字母跳转到对应单词位置
- **顶部/中间按钮**: 快速回到列表顶部或中间位置

#### 状态操作按钮 (StatusActionButtons)
- **三按钮布局**: 简单(绿) + 犹豫(黄) + 困难(红)
- **悬浮设计**: 固定在屏幕底部，带阴影效果
- **智能操作**: 仅对当前中心位置的单词生效

#### 滚动选择器 (PickerScrollView)
- **智能吸附**: 滚动停止时自动吸附到最近的单词项
- **中心检测**: 实时检测并高亮屏幕中心的单词项
- **平滑动画**: 滚动和吸附都使用平滑动画效果

## 核心算法

### 中心位置检测算法
```dart
int getCenterWordIndex(double scrollOffset, double viewportHeight, double itemHeight) {
  final centerOffset = scrollOffset + viewportHeight / 2;
  final centerIndex = (centerOffset / itemHeight).round();
  return centerIndex.clamp(0, _wordList.length - 1);
}
```

### 首字母分组索引
```dart
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
```

## 构建和运行

### 开发环境要求
1. **Flutter SDK**: 3.9.2或更高版本
2. **Dart SDK**: 3.0或更高版本
3. **开发工具**: VS Code或Android Studio
4. **平台工具**: 
   - Android: Android SDK和Android Studio
   - iOS: Xcode (仅macOS)

### 构建命令
```bash
# 获取依赖
flutter pub get

# 运行调试版本
flutter run

# 构建Android APK
flutter build apk --release

# 构建iOS应用(仅macOS)
flutter build ios --release

# 构建Web版本
flutter build web

# 清理构建缓存
flutter clean
```

### 测试命令
```bash
# 运行单元测试
flutter test

# 运行集成测试
flutter drive --target=test_driver/app.dart

# 代码格式化
dart format .

# 代码规范检查
flutter analyze
```

## 开发和调试

### 热重载开发
```bash
# 启动开发服务器
flutter run

# 在终端中按 'r' 重新加载
# 按 'R' 重启应用
# 按 'q' 退出
```

### 调试工具
- **Flutter Inspector**: 布局和Widget树检查
- **Debug Console**: 日志输出和错误信息
- **Performance Overlay**: 性能监控
- **Memory Profiler**: 内存使用分析

### 日志输出
主要日志位置:
- **数据加载**: `ExcelService.loadWordList()`
- **状态管理**: `WordListProvider`方法
- **滚动事件**: `WordListScreen._onScroll()`
- **本地存储**: SharedPreferences操作

## 数据格式规范

### CSV文件格式 (`assets/words/ielts-main.csv`)
```
english,词性中文释义
abandon,vt. 抛弃;放弃
ability,n. 能力；本领；才能，才干；专门技能，天资
able,a. 有(能力、时间、知识等)做某事，有本事的
```

### CSV文件格式 (`assets/words/ielts.csv`)
```
english,中文释义1,中文释义2
abandon,放弃,抛弃
ability,能力,才智
able,能够的,有能力的
```

### Excel文件格式 (`assets/words/ielts.xls`)
- **工作表**: 第一个工作表
- **列结构**: A列=英文单词, B列=中文释义
- **数据行**: 从第2行开始(第1行为标题)
- **编码**: UTF-8

### 示例数据格式
当数据文件无法加载时，应用会使用内置的示例数据:
```dart
WordItem(english: 'abandon', chinese: '放弃, 抛弃', index: 0),
WordItem(english: 'ability', chinese: '能力, 才智', index: 1),
// ... 更多示例单词
```

## 性能和优化

### 已实现的优化
1. **虚拟滚动**: ListView.builder只渲染可见项
2. **状态缓存**: 避免重复计算学习统计
3. **懒加载**: 仅在需要时显示中文释义
4. **智能刷新**: 局部更新而非整体刷新
5. **数据预加载**: 启动时加载完整单词列表
6. **滚动吸附**: 滚动停止时自动吸附到最近的单词项
7. **智能数据解析**: 自动处理CSV文件中的引号问题

### 内存管理
- 合理的Widget生命周期管理
- 及时释放ScrollController
- 使用const构造函数减少重建

### 未来优化方向
- 大文件分块加载
- 单词搜索和过滤功能
- 学习计划制定
- 云端同步功能

## 常见问题解决

### 构建问题
1. **依赖冲突**: 运行`flutter pub upgrade`
2. **平台工具缺失**: 检查SDK安装和环境变量
3. **缓存问题**: 运行`flutter clean && flutter pub get`

### 运行时问题
1. **数据文件无法加载**: 检查assets配置和文件路径
2. **状态丢失**: 验证SharedPreferences权限
3. **性能问题**: 检查大量数据处理和UI重建
4. **CSV格式错误**: 检查CSV文件编码和格式是否正确

### 调试技巧
1. 使用`print()`输出关键变量值
2. 利用Flutter Inspector检查Widget树
3. 使用Debug模式查看详细错误信息
4. 检查platform-specific日志(Android Logcat, iOS Console)

## 扩展开发

### 添加新功能
1. **新学习状态**: 修改`WordStatus`枚举和相关逻辑
2. **数据源**: 扩展`ExcelService`支持更多格式
3. **UI主题**: 自定义Material主题配置
4. **平台特性**: 添加platform-specific功能

### 自定义配置
```dart
// 修改主题颜色
theme: ThemeData(
  primarySwatch: Colors.blue,
  // 自定义更多主题配置
)

// 调整列表项高度
final itemHeight = 60.0; // 在WordListProvider和PickerScrollView中

// 修改状态颜色
int get colorValue {
  // 在WordStatusExtension中自定义颜色
}
```

## 贡献指南

### 代码规范
- 使用Dart官方格式化工具
- 遵循Flutter最佳实践
- 添加必要的注释说明复杂逻辑
- 保持代码简洁和可读性

### 测试要求
- 为新功能添加单元测试
- 确保UI测试覆盖主要用户流程
- 验证数据持久化功能

### 提交流程
1. Fork项目到个人账户
2. 创建功能分支
3. 完成开发和测试
4. 提交Pull Request
5. 代码审查和合并

---

*本文档将随着项目发展持续更新。如有问题或建议，请通过GitHub Issues反馈。*