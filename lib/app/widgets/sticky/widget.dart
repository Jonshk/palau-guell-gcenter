import 'package:flutter/material.dart';

import './render.dart';

typedef StickyHeaderWidgetBuilder = Widget Function(BuildContext context, double stuckAmount);

class StickyHeader extends MultiChildRenderObjectWidget {
  final Widget header;
  final Widget content;
  final bool overlapHeaders;
  final ScrollController? controller;
  final RenderStickyHeaderCallback? callback;
  final double offset;

  StickyHeader({
    super.key,
    required this.header,
    required this.content,
    this.overlapHeaders = false,
    this.controller,
    this.callback,
    this.offset = 0,
  }) : super(children: [content, header]);

  @override
  RenderStickyHeader createRenderObject(BuildContext context) {
    final scrollPosition = controller?.position ?? Scrollable.of(context).position;
    return RenderStickyHeader(
      scrollPosition: scrollPosition,
      callback: callback,
      overlapHeaders: overlapHeaders,
      stickyOffset: offset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderStickyHeader renderObject) {
    final scrollPosition = controller?.position ?? Scrollable.of(context).position;
    renderObject
      ..scrollPosition = scrollPosition
      ..callback = callback
      ..stickyOffset = offset
      ..overlapHeaders = overlapHeaders;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      renderObject.markNeedsLayout();
    });
  }
}

class StickyHeaderBuilder extends StatefulWidget {
  final StickyHeaderWidgetBuilder builder;
  final Widget content;
  final bool overlapHeaders;
  final ScrollController? controller;

  const StickyHeaderBuilder({
    super.key,
    required this.builder,
    required this.content,
    this.overlapHeaders = false,
    this.controller,
  });

  @override
  State<StickyHeaderBuilder> createState() => _StickyHeaderBuilderState();
}

class _StickyHeaderBuilderState extends State<StickyHeaderBuilder> {
  double? _stuckAmount;

  @override
  Widget build(BuildContext context) {
    return StickyHeader(
      overlapHeaders: widget.overlapHeaders,
      header: LayoutBuilder(builder: (context, _) => widget.builder(context, _stuckAmount ?? 0.0)),
      content: widget.content,
      controller: widget.controller,
      callback: (double stuckAmount) {
        if (_stuckAmount != stuckAmount) {
          _stuckAmount = stuckAmount;
          WidgetsBinding.instance.endOfFrame.then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        }
      },
    );
  }
}
