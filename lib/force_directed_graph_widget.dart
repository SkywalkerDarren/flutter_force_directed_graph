import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_force_directed_graph/edge_widget.dart';
import 'package:flutter_force_directed_graph/node_widget.dart';

import 'force_directed_graph_controller.dart';
import 'algo/models.dart';

typedef NodeBuilder<T> = Widget Function(BuildContext context, T data);
typedef EdgeBuilder<T> = Widget Function(BuildContext context, T a, T b);

class ForceDirectedGraphWidget<T> extends StatefulWidget {
  const ForceDirectedGraphWidget({
    super.key,
    required this.controller,
    required this.nodesBuilder,
    required this.edgesBuilder,
  });

  final ForceDirectedGraphController<T> controller;
  final NodeBuilder<T> nodesBuilder;
  final EdgeBuilder<T> edgesBuilder;

  @override
  State<ForceDirectedGraphWidget<T>> createState() => _ForceDirectedGraphState<T>();
}

class _ForceDirectedGraphState<T> extends State<ForceDirectedGraphWidget<T>> {
  ForceDirectedGraphController<T> get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    print("_onControllerChange");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final nodes = controller.graph.nodes.map((e) {
      final child = widget.nodesBuilder(context, e.data);
      if (child is NodeWidget) {
        assert(child.node == e);
        return child;
      }
      return NodeWidget(
        node: e,
        child: child,
      );
    });

    final edges = controller.graph.edges.map((e) {
      final child = widget.edgesBuilder(context, e.a.data, e.b.data);
      if (child is EdgeWidget) {
        assert(child.edge == e);
        return child;
      }
      return EdgeWidget(
        edge: e,
        child: child,
      );
    });

    if (nodes.isEmpty) {
      return Container();
    }

    return ForceDirectedGraphBody(
      changing: () => controller.isUpdating,
      graph: widget.controller.graph,
      nodes: nodes,
      edges: edges,
    );
  }
}

class ForceDirectedGraphBody extends MultiChildRenderObjectWidget {
  final ForceDirectedGraph graph;
  final bool Function() changing;

  ForceDirectedGraphBody({
    Key? key,
    required this.changing,
    required this.graph,
    required Iterable<NodeWidget> nodes,
    required Iterable<EdgeWidget> edges,
  }) : super(key: key, children: [...nodes, ...edges]);

  @override
  ForceDirectedGraphRenderObject createRenderObject(BuildContext context) {
    print("createRenderObject");
    return ForceDirectedGraphRenderObject(graph: graph, changing: changing);
  }

  @override
  void updateRenderObject(BuildContext context, ForceDirectedGraphRenderObject renderObject) {
    print("updateRenderObject");
    renderObject.graph = graph;
  }
}

class ForceDirectedGraphRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ForceDirectedGraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ForceDirectedGraphParentData> {
  ForceDirectedGraphRenderObject({required ForceDirectedGraph graph, required this.changing})
      : _graph = graph;

  final bool Function() changing;

  ForceDirectedGraph _graph;

  set graph(ForceDirectedGraph value) {
    if (_graph == value) {
      return;
    }
    _graph = value;
    print("markNeedsPaint");
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ForceDirectedGraphParentData) {
      child.parentData = ForceDirectedGraphParentData();
    }
  }

  @override
  void performLayout() {
    size = constraints.biggest;
    print("size: $size, constraints: $constraints");
    final children = getChildrenAsList();
    for (final child in children) {
      final parentData = child.parentData! as ForceDirectedGraphParentData;
      assert(parentData.node != null || parentData.edge != null);
      final innerConstraints = constraints.loosen();
      child.layout(innerConstraints, parentUsesSize: true);
      parentData.offset = child.size.center(Offset.zero);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // print("paint");
    final center = offset + size.center(Offset.zero);
    context.canvas.translate(center.dx, center.dy);
    // 获取children
    final children = getChildrenAsList();
    for (final child in children) {
      context.canvas.save();

      final parentData = child.parentData! as ForceDirectedGraphParentData;
      if (parentData.node != null) {
        final data = parentData.node!.data;
        final node = _graph.nodes.firstWhere((element) => element.data == data);
        final moveOffset = Offset(node.position.x, -node.position.y);
        final finalOffset = -parentData.offset + moveOffset;
        // print("node: $node, parentOffset: ${parentData.offset}, moveOffset: $moveOffset, finalOffset: $finalOffset");
        context.paintChild(child, finalOffset);
      } else if (parentData.edge != null) {
        final edge = _graph.edges.firstWhere((element) => element == parentData.edge);
        final edgeCenter = (edge.a.position + edge.b.position) / 2;
        final moveOffset = Offset(edgeCenter.x, -edgeCenter.y);
        final finalOffset = -parentData.offset + moveOffset;
        // print("edgeCenter: $edgeCenter, edge: $edge, parentOffset: ${parentData.offset}, moveOffset: $moveOffset, finalOffset: $finalOffset");
        context.canvas.translate(moveOffset.dx, moveOffset.dy);
        context.canvas.rotate(edge.angle);
        context.canvas.translate(-moveOffset.dx, -moveOffset.dy);
        context.paintChild(child, finalOffset);
      }
      context.canvas.restore();
    }
    context.canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.red);
  }
}

class ForceDirectedGraphParentData extends ContainerBoxParentData<RenderBox> {
  Node? node;
  Edge? edge;

  ForceDirectedGraphParentData();
}
