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
    final centerOffset = _scrollController.offset + _viewportHeight / 2 - widget.itemExtent / 2;
    final centerIndex = (centerOffset / widget.itemExtent).round().clamp(0, widget.itemCount - 1);

    if (centerIndex != _centerItemIndex) {
      setState(() => _centerItemIndex = centerIndex);
      widget.onCenterIndexChanged?.call(centerIndex);
    }
  }

  void _snapToCenter() {
    if (_centerItemIndex == null) return;
    final targetOffset = _centerItemIndex! * widget.itemExtent - (_viewportHeight - widget.itemExtent) / 2;
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
        return ListView.builder(
          controller: _scrollController,
          itemCount: widget.itemCount,
          itemExtent: widget.itemExtent,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final isCenter = index == _centerItemIndex;
            final showChinese = index < (_centerItemIndex ?? 0) || 
                (widget.forceShowChineseIndex != null && index == widget.forceShowChineseIndex!);
            return widget.itemBuilder(context, index, isCenter, showChinese);
          },
        );
      },
    );
  }
}