import 'dart:math' show min, max;
// ignore: deprecated_member_use
import 'dart:ui' as ui show window;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef RenderStickyHeaderCallback = void Function(double stuckAmount);

class RenderStickyHeader extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  RenderStickyHeaderCallback? _callback;
  ScrollPosition _scrollPosition;
  bool _overlapHeaders;
  double _stickyOffset;

  RenderStickyHeader({
    required ScrollPosition scrollPosition,
    RenderStickyHeaderCallback? callback,
    bool overlapHeaders = false,
    RenderBox? header,
    RenderBox? content,
    double stickyOffset = 0,
  }) : _scrollPosition = scrollPosition,
       _callback = callback,
       _stickyOffset = stickyOffset,
       _overlapHeaders = overlapHeaders {
    if (content != null) add(content);
    if (header != null) add(header);
  }

  set scrollPosition(ScrollPosition newValue) {
    if (_scrollPosition == newValue) {
      return;
    }
    final ScrollPosition oldValue = _scrollPosition;
    _scrollPosition = newValue;
    markNeedsLayout();
    if (attached) {
      oldValue.removeListener(markNeedsLayout);
      newValue.addListener(markNeedsLayout);
    }
  }

  set callback(RenderStickyHeaderCallback? newValue) {
    if (_callback == newValue) {
      return;
    }
    _callback = newValue;
    markNeedsLayout();
  }

  set overlapHeaders(bool newValue) {
    if (_overlapHeaders == newValue) {
      return;
    }
    _overlapHeaders = newValue;
    markNeedsLayout();
  }

  set stickyOffset(double newValue) {
    if (_stickyOffset == newValue) {
      return;
    }
    _stickyOffset = newValue;
    markNeedsLayout();
  }

  double get stickyOffset => _stickyOffset;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollPosition.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _scrollPosition.removeListener(markNeedsLayout);
    super.detach();
  }

  RenderBox get _headerBox => lastChild!;

  RenderBox get _contentBox => firstChild!;

  // ignore: deprecated_member_use
  double get devicePixelRatio => ui.window.devicePixelRatio;

  double roundToNearestPixel(double offset) {
    return (offset * devicePixelRatio).roundToDouble() / devicePixelRatio;
  }

  @override
  void performLayout() {
    final childConstraints = constraints.loosen();
    _headerBox.layout(childConstraints, parentUsesSize: true);
    _contentBox.layout(childConstraints, parentUsesSize: true);

    final headerHeight = roundToNearestPixel(_headerBox.size.height);
    final contentHeight = roundToNearestPixel(_contentBox.size.height);

    final width = constraints.constrainWidth(max(constraints.minWidth, _contentBox.size.width));
    final height = constraints.constrainHeight(
      max(constraints.minHeight, _overlapHeaders ? contentHeight : headerHeight + contentHeight),
    );
    size = Size(width, height);

    final contentParentData = _contentBox.parentData as MultiChildLayoutParentData;
    contentParentData.offset = Offset(0.0, _overlapHeaders ? 0.0 : headerHeight);

    final double stuckOffset = roundToNearestPixel(determineStuckOffset() - _stickyOffset);

    final double maxOffset = height - headerHeight;
    final headerParentData = _headerBox.parentData as MultiChildLayoutParentData;
    headerParentData.offset = Offset(0.0, max(0.0, min(-stuckOffset, maxOffset)));

    if (_callback != null) {
      final adjustedStuckOffset = stuckOffset + _stickyOffset;
      final stuckAmount = max(min(headerHeight, adjustedStuckOffset), -headerHeight) / headerHeight;
      _callback!(stuckAmount);
    }
  }

  double determineStuckOffset() {
    final scrollBox = _scrollPosition.context.notificationContext!.findRenderObject();
    if (scrollBox?.attached ?? false) {
      try {
        return localToGlobal(Offset.zero, ancestor: scrollBox).dy;
        // ignore: empty_catches
      } catch (e) {}
    }
    return 0.0;
  }

  @override
  void setupParentData(RenderObject child) {
    super.setupParentData(child);
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _contentBox.getMinIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _contentBox.getMaxIntrinsicWidth(height);
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _overlapHeaders
        ? _contentBox.getMinIntrinsicHeight(width)
        : (_headerBox.getMinIntrinsicHeight(width) + _contentBox.getMinIntrinsicHeight(width));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _overlapHeaders
        ? _contentBox.getMaxIntrinsicHeight(width)
        : (_headerBox.getMaxIntrinsicHeight(width) + _contentBox.getMaxIntrinsicHeight(width));
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToHighestActualBaseline(baseline);
  }

  @override
  bool hitTestChildren(HitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result as BoxHitTestResult, position: position);
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }
}
