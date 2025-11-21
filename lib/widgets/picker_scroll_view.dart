import 'dart:async';
import 'package:flutter/material.dart';

// 滚动选择器视图组件
class PickerScrollView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index, bool isCenter, bool showChinese) itemBuilder;
  final double itemExtent;
  final Function(int centerIndex)? onCenterIndexChanged;
  final ScrollController? controller;
  final int? forceShowChineseIndex;

  const PickerScrollView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent = 60.0, // 降低默认项高度
    this.onCenterIndexChanged,
    this.controller,
    this.forceShowChineseIndex,
  });

  @override
  State<PickerScrollView> createState() => _PickerScrollViewState();
}

class _PickerScrollViewState extends State<PickerScrollView> {
  late ScrollController _scrollController;
  int? _centerItemIndex;
  bool _isUserScrolling = false;
  Timer? _scrollEndTimer;
  double _viewportHeight = 0.0;
  int _leadingPaddingItems = 0;
  int _trailingPaddingItems = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCenterItemIndex());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.controller == null) _scrollController.dispose();
    _scrollEndTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    _isUserScrolling = true;
    _scrollEndTimer?.cancel();
    _scrollEndTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _isUserScrolling) _snapToCenter();
    });
    _updateCenterItemIndex();
  }

  void _updateCenterItemIndex() {
    if (_viewportHeight <= 0) return;
    
    // 计算需要添加的空白项数量
    _calculatePaddingItems();
    
    final centerOffset = _scrollController.offset + _viewportHeight / 2 - widget.itemExtent / 2;
    // 调整中心索引以考虑前导空白项
    final adjustedCenterIndex = (centerOffset / widget.itemExtent).round() - _leadingPaddingItems;
    final centerIndex = adjustedCenterIndex.clamp(0, widget.itemCount - 1);

    if (centerIndex != _centerItemIndex) {
      setState(() => _centerItemIndex = centerIndex);
      widget.onCenterIndexChanged?.call(centerIndex);
    }
  }

  void _calculatePaddingItems() {
    if (_viewportHeight > 0) {
      // 计算每边需要添加的空白项数量（屏幕高度能容纳的单词数量除以2）
      final itemsPerScreen = (_viewportHeight / widget.itemExtent).round();
      final paddingItems = (itemsPerScreen / 2).ceil();
      
      _leadingPaddingItems = paddingItems;
      _trailingPaddingItems = paddingItems;
    } else {
      _leadingPaddingItems = 0;
      _trailingPaddingItems = 0;
    }
  }

  void _snapToCenter() {
    if (_centerItemIndex == null) return;
    // 调整目标偏移量以考虑前导空白项
    final targetOffset = (_centerItemIndex! + _leadingPaddingItems) * widget.itemExtent - (_viewportHeight - widget.itemExtent) / 2;
    final difference = (targetOffset - _scrollController.offset).abs();

    if (difference > 1.0) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ).then((_) {
        _isUserScrolling = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateCenterItemIndex());
      });
    } else {
      _isUserScrolling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        _calculatePaddingItems();
        
        // 总项目数量包括前导和后缀的空白项
        final totalItemCount = widget.itemCount + _leadingPaddingItems + _trailingPaddingItems;
        
        return ListView.builder(
          controller: _scrollController,
          itemCount: totalItemCount,
          itemExtent: widget.itemExtent,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            // 如果是前导或后缀的空白项，则显示空容器
            if (index < _leadingPaddingItems || index >= (_leadingPaddingItems + widget.itemCount)) {
              return Container();
            }
            
            // 将索引调整为实际单词列表的索引
            final actualIndex = index - _leadingPaddingItems;
            final isCenter = actualIndex == _centerItemIndex;
            final showChinese = actualIndex < (_centerItemIndex ?? 0) || 
                (widget.forceShowChineseIndex != null && actualIndex == widget.forceShowChineseIndex!);
            return widget.itemBuilder(context, actualIndex, isCenter, showChinese);
          },
        );
      },
    );
  }
}