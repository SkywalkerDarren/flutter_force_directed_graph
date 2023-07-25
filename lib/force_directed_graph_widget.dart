import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_force_directed_graph/force_directed_graph_controller.dart';

typedef NodeBuilder<T> = Widget Function(BuildContext context, T data);

class ForceDirectedGraphWidget<T> extends MultiChildRenderObjectWidget {
  ForceDirectedGraphWidget({
    super.key,
    required ForceDirectedGraphController<T> controller,
    required NodeBuilder<T> childrenBuilder,
    required WidgetBuilder edgesBuilder,
  });

  @override
  ForceDirectedGraphRenderObject createRenderObject(BuildContext context) {
    return ForceDirectedGraphRenderObject();
  }
}

class ForceDirectedGraphRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ForceDirectedGraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ForceDirectedGraphParentData> {
  ForceDirectedGraphRenderObject();

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ForceDirectedGraphParentData) {
      child.parentData = ForceDirectedGraphParentData();
    }
  }

  @override
  void performLayout() {
    // TODO: implement performLayout
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // TODO: implement paint
  }
}

class ForceDirectedGraphParentData extends ContainerBoxParentData<RenderBox> {}
