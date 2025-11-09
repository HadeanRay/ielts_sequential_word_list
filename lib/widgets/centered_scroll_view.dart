import 'dart:async';
import 'package:flutter/material.dart';

// 自定义滚动吸附视图组件
class CenteredScrollView extends StatefulWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double itemHeight;
  final Function(int centerIndex)? onCenterIndexChanged;
  final ScrollController? controller;

  const CenteredScrollView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemHeight = 76.0,
    this.onCenterIndexChanged,
    this.controller,
  });

  @override
  State<CenteredScrollView> createState() => _CenteredScrollViewState();
}

class _CenteredScrollViewState extends State<CenteredScrollView> {
  late ScrollController _scrollController;
  int? _centerItemIndex;
  bool _isScrolling = false;
  bool _isUserScrolling = false; // 标记是否是用户主动滚动
  Timer? _scrollEndTimer;
  Timer? _debounceTimer;
  double _viewportHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    // 延迟初始化中心项索引，避免初始滚动
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
    _debounceTimer?.cancel();
    _scrollEndTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // 标记用户正在滚动
    if (!_isUserScrolling) {
      _isUserScrolling = true;
    }
    
    // 标记正在滚动
    if (!_isScrolling) {
      setState(() {
        _isScrolling = true;
      });
    }

    // 取消之前的定时器
    _scrollEndTimer?.cancel();
    _debounceTimer?.cancel();

    // 使用定时器延迟更新中心单词索引，避免滚动过程中频繁更新
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      if (mounted) {
        _updateCenterItemIndex();
      }
    });

    // 设置滚动结束检测，滚动结束后执行吸附动画
    _scrollEndTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted && _isScrolling) {
        setState(() {
          _isScrolling = false;
        });
        
        // 只有用户主动滚动结束后才执行吸附
        if (_isUserScrolling) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _snapToCenter();
          });
        }
      }
    });
  }

  void _updateCenterItemIndex() {
    _viewportHeight = MediaQuery.of(context).size.height;
    
    // 计算屏幕中心位置对应的索引
    final centerOffset = _scrollController.offset + _viewportHeight / 2;
    final centerIndex = (centerOffset / widget.itemHeight).round();
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
    final targetOffset = _centerItemIndex! * widget.itemHeight - _viewportHeight / 2 + widget.itemHeight / 2;
    final currentOffset = _scrollController.offset;
    final difference = (targetOffset - currentOffset).abs();

    // 如果当前位置与目标位置差距大于一个像素，则执行吸附动画
    // 增加阈值以避免微小滚动触发吸附
    // 只有用户主动滚动时才执行吸附
    if (difference > 5.0 && _isUserScrolling) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      ).then((_) {
        // 吸附完成后重置用户滚动标记
        _isUserScrolling = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewportHeight = constraints.maxHeight;
        
        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // 顶部填充，使列表项从屏幕中心开始
            SliverToBoxAdapter(
              child: SizedBox(
                height: _viewportHeight / 2 - widget.itemHeight / 2,
              ),
            ),
            // 单词列表
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final isCenter = index == _centerItemIndex;
                  return widget.itemBuilder(context, index);
                },
                childCount: widget.itemCount,
              ),
            ),
            // 底部填充 - 留出底部按钮的空间
            SliverToBoxAdapter(
              child: SizedBox(
                height: _viewportHeight / 2,
              ),
            ),
          ],
        );
      },
    );
  }
}