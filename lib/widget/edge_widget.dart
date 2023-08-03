import 'package:flutter/material.dart';

import '../model/edge.dart';
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
    parentData.edge = edge;
  }

  @override
  Type get debugTypicalAncestorWidgetClass => ForceDirectedGraphBody;
}
