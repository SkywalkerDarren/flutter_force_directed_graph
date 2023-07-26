import 'package:flutter/material.dart';

import 'algo/models.dart';
import 'force_directed_graph_widget.dart';

class EdgeWidget extends ParentDataWidget<ForceDirectedGraphParentData> {
  final Edge edge;

  const EdgeWidget({
    Key? key,
    required Widget child,
    required this.edge,
  }) : super(child: child, key: key);

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is ForceDirectedGraphParentData);
    final parentData = renderObject.parentData! as ForceDirectedGraphParentData;
    if (parentData.edge != edge) {
      parentData.edge = edge;
      final ForceDirectedGraphRenderObject targetParent =
          renderObject.parent! as ForceDirectedGraphRenderObject;
      targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => ForceDirectedGraphBody;
}
