import 'package:flutter/material.dart';

import 'algo/models.dart';
import 'force_directed_graph_widget.dart';

class NodeWidget extends ParentDataWidget<ForceDirectedGraphParentData> {
  final Node node;

  const NodeWidget({Key? key, required Widget child, required this.node}) : super(key: key, child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is ForceDirectedGraphParentData);
    final parentData = renderObject.parentData! as ForceDirectedGraphParentData;
    if (parentData.node != node) {
      parentData.node = node;
      final ForceDirectedGraphRenderObject targetParent =
          renderObject.parent! as ForceDirectedGraphRenderObject;
      targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => ForceDirectedGraphBody;
}
