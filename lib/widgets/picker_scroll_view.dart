import 'dart:async';
import 'package:flutter/material.dart';

// 滚动选择器视图组件
class PickerScrollView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index, bool isCenter) itemBuilder;
  final double itemExtent;
  final Function(int centerIndex)? onCenterIndexChanged;
  final ScrollController? controller;

  const PickerScrollView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemExtent = 100.0,
    this.onCenterIndexChanged,
    this.controller,
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

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    // 延迟初始化中心项索引
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateCenterItemIndex();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    _scrollEndTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // 标记用户正在滚动
    if (!_isUserScrolling) {
      _isUserScrolling = true;
    }

    // 取消之前的定时器
    _scrollEndTimer?.cancel();

    // 设置滚动结束检测
    _scrollEndTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _isUserScrolling) {
        _snapToCenter();
      }
    });

    // 更新中心项索引
    _updateCenterItemIndex();
  }

  void _updateCenterItemIndex() {
    if (_viewportHeight <= 0) return;
    
    // 计算屏幕中心位置对应的索引
    // 屏幕中心位置 = 滚动偏移量 + 视口高度的一半 - 项高度的一半
    // 这样可以确保中心检测区域正确
    final centerOffset = _scrollController.offset + _viewportHeight / 2 - widget.itemExtent / 2;
    // 中心项索引 = 中心位置 / 项高度
    final centerIndex = (centerOffset / widget.itemExtent).round();
    final clampedIndex = centerIndex.clamp(0, widget.itemCount - 1);

    if (clampedIndex != _centerItemIndex) {
      setState(() {
        _centerItemIndex = clampedIndex;
      });
      
      // 通知外部中心项已更改
      if (widget.onCenterIndexChanged != null) {
        widget.onCenterIndexChanged!(clampedIndex);
      }
    }
  }

  void _snapToCenter() {
    if (_centerItemIndex == null) return;

    // 计算目标偏移量 - 确保目标项位于屏幕中央
    // 目标偏移量 = 目标项索引 * 项高度 - (视口高度 - 项高度) / 2 + 项高度 / 2
    // 修正：确保吸附位置正确
    final targetOffset = _centerItemIndex! * widget.itemExtent - (_viewportHeight - widget.itemExtent) / 2;
    final currentOffset = _scrollController.offset;
    final difference = (targetOffset - currentOffset).abs();

    // 如果当前位置与目标位置差距大于一个像素，则执行吸附动画
    if (difference > 1.0) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ).then((_) {
        // 吸附完成后重置用户滚动标记
        _isUserScrolling = false;
        // 在动画结束后更新中心项以确保准确性
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateCenterItemIndex();
        });
      });
    } else {
      _isUserScrolling = false;
    }
  }

  void _scrollToCenter(int index) {
    // 滚动到指定索引项居中位置
    final targetOffset = index * widget.itemExtent - (_viewportHeight - widget.itemExtent) / 2;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        
        return Stack(
          children: [
            // 主滚动列表 - 不使用padding，让第一个单词从顶部开始
            ListView.builder(
              controller: _scrollController,
              itemCount: widget.itemCount,
              itemExtent: widget.itemExtent,
              padding: EdgeInsets.zero, // 不使用padding
              itemBuilder: (context, index) {
                final isCenter = index == _centerItemIndex;
                return Container(
                  child: widget.itemBuilder(context, index, isCenter),
                );
              },
            ),
            // 中心指示器装饰层 - 位于列表下方以不干扰交互
            Positioned(
              top: (_viewportHeight - widget.itemExtent) / 2,
              left: 0,
              right: 0,
              height: widget.itemExtent,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border(
                    top: BorderSide(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1.0,
                    ),
                    bottom: BorderSide(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}