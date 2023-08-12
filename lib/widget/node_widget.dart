import 'package:flutter/material.dart';

import '../model/node.dart';
import 'force_directed_graph_widget.dart';

class NodeWidget extends ParentDataWidget<ForceDirectedGraphParentData> {
  final Node node;

  const NodeWidget({Key? key, required Widget child, required this.node})
      : super(key: key, child: child);

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is ForceDirectedGraphParentData);
    final parentData = renderObject.parentData! as ForceDirectedGraphParentData;
    parentData.node = node;
  }

  // coverage:ignore-start
  @override
  Type get debugTypicalAncestorWidgetClass => ForceDirectedGraphBody;
  // coverage:ignore-end
}
