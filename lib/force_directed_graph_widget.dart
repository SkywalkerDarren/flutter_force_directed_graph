import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
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

class _ForceDirectedGraphState<T> extends State<ForceDirectedGraphWidget<T>>
    with SingleTickerProviderStateMixin {
  ForceDirectedGraphController<T> get controller => widget.controller;
  late Ticker ticker;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((elapsed) {
      final isMoving = controller.update();
      if (!isMoving) {
        ticker.stop();
      }
      print("ticker: $elapsed");
    });
    controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    print("_onControllerChange");
    if (!ticker.isTicking) {
      ticker.start();
    }
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
  }) : super(key: key, children: [...edges, ...nodes]);

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
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // print("paint");
    final center = offset + size.center(Offset.zero);
    // print("center: $center");
    context.canvas.translate(center.dx, center.dy);
    // 获取children
    final children = getChildrenAsList();
    for (final child in children) {
      context.canvas.save();

      final parentData = child.parentData! as ForceDirectedGraphParentData;
      final childCenter = child.size.center(Offset.zero);
      if (parentData.node != null) {
        final data = parentData.node!.data;
        final node = _graph.nodes.firstWhere((element) => element.data == data);
        final moveOffset = Offset(node.position.x, -node.position.y);
        final finalOffset = -childCenter + moveOffset;
        // print("node: $node, parentOffset: ${parentData.offset}, moveOffset: $moveOffset, finalOffset: $finalOffset");
        context.paintChild(child, finalOffset);
        final childOffset = moveOffset + center - offset - childCenter;
        parentData.transform = Matrix4.identity()
          ..translate(childOffset.dx, childOffset.dy);
        // print("parentData.offset: ${parentData.offset}");
      } else if (parentData.edge != null) {
        final edge = _graph.edges.firstWhere((element) => element == parentData.edge);
        final edgeCenter = (edge.a.position + edge.b.position) / 2;
        final moveOffset = Offset(edgeCenter.x, -edgeCenter.y);
        final finalOffset = -childCenter + moveOffset;
        // print("edgeCenter: $edgeCenter, edge: $edge, parentOffset: ${parentData.offset}, moveOffset: $moveOffset, finalOffset: $finalOffset");
        context.canvas.translate(moveOffset.dx, moveOffset.dy);
        context.canvas.rotate(edge.angle);
        context.canvas.translate(-moveOffset.dx, -moveOffset.dy);
        context.paintChild(child, finalOffset);
        final childOffset = moveOffset + center - offset - childCenter;
        parentData.transform = Matrix4.identity()
          ..translate(childOffset.dx + childCenter.dx, childOffset.dy + childCenter.dy)
          ..rotateZ(edge.angle)
          ..translate(-childCenter.dx, -childCenter.dy);
        // print("parentData.offset: ${parentData.offset}");
      }
      context.canvas.restore();
    }

    // for debug
    // context.canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.red);
    // context.canvas.translate(-center.dx, -center.dy);
    // for (final child in children) {
    //   final parentData = child.parentData! as ForceDirectedGraphParentData;
    //   context.canvas.drawCircle(parentData.offset, 3, Paint()..color = Colors.yellow);
    // }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as ForceDirectedGraphParentData;
      Matrix4 transform = Matrix4.identity();
      transform.translate(childParentData.offset.dx, childParentData.offset.dy);
      final bool isHit = result.addWithPaintTransform(
        transform: childParentData.transform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childParentData.previousSibling;
    }
    return false;
  }
}

class ForceDirectedGraphParentData extends ContainerBoxParentData<RenderBox> {
  Node? node;
  Edge? edge;
  Matrix4? transform;

  ForceDirectedGraphParentData();
}
