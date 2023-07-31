import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_force_directed_graph/edge_widget.dart';
import 'package:flutter_force_directed_graph/node_widget.dart';
import 'package:vector_math/vector_math.dart' as vector;

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
      final isMoving = controller.graph.updateAllNodes();
      if (!isMoving) {
        ticker.stop();
      }
    });
    controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  void _onControllerChange() {
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
      controller: controller,
      graph: widget.controller.graph,
      nodes: nodes,
      edges: edges,
    );
  }
}

class ForceDirectedGraphBody extends MultiChildRenderObjectWidget {
  final ForceDirectedGraph graph;
  final ForceDirectedGraphController controller;

  ForceDirectedGraphBody({
    Key? key,
    required this.controller,
    required this.graph,
    required Iterable<NodeWidget> nodes,
    required Iterable<EdgeWidget> edges,
  }) : super(key: key, children: [...edges, ...nodes]);

  @override
  ForceDirectedGraphRenderObject createRenderObject(BuildContext context) {
    return ForceDirectedGraphRenderObject(graph: graph, controller: controller);
  }

  @override
  void updateRenderObject(BuildContext context, ForceDirectedGraphRenderObject renderObject) {
    renderObject.graph = graph;
  }
}

class ForceDirectedGraphRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ForceDirectedGraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, ForceDirectedGraphParentData> {
  ForceDirectedGraphRenderObject({required ForceDirectedGraph graph, required this.controller})
      : _graph = graph;

  final ForceDirectedGraphController controller;

  ForceDirectedGraph _graph;

  set graph(ForceDirectedGraph value) {
    _graph = value;
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
    final center = offset + size.center(Offset.zero);
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
        context.paintChild(child, finalOffset);
        final childOffset = moveOffset + center - offset - childCenter;
        parentData.transform = Matrix4.identity()..translate(childOffset.dx, childOffset.dy);
      } else if (parentData.edge != null) {
        final edge = _graph.edges.firstWhere((element) => element == parentData.edge);
        final edgeCenter = (edge.a.position + edge.b.position) / 2;
        final moveOffset = Offset(edgeCenter.x, -edgeCenter.y);
        final finalOffset = -childCenter + moveOffset;
        context.canvas.translate(moveOffset.dx, moveOffset.dy);
        context.canvas.rotate(edge.angle);
        context.canvas.translate(-moveOffset.dx, -moveOffset.dy);
        context.paintChild(child, finalOffset);
        final childOffset = moveOffset + center - offset - childCenter;
        parentData.transform = Matrix4.identity()
          ..translate(childOffset.dx + childCenter.dx, childOffset.dy + childCenter.dy)
          ..rotateZ(edge.angle)
          ..translate(-childCenter.dx, -childCenter.dy);
      }
      context.canvas.restore();
    }
  }

  Node? _draggingNode;

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
          _draggingNode = childParentData.node;
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

  @override
  bool hitTestSelf(Offset position) => true;

  vector.Vector2? _downPosition;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent) {
      if (_draggingNode != null) {
        _downPosition = _draggingNode!.position;
      }
      // ignore
    } else if (event is PointerMoveEvent) {
      if (_draggingNode != null) {
        // 移动节点
        _downPosition = _downPosition! + vector.Vector2(event.delta.dx, -event.delta.dy);
        _draggingNode!.position = _downPosition!;
        markNeedsPaint();
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          controller.needUpdate();
        });
      } else {
        // 移动画布
        for (final node in _graph.nodes) {
          node.position += vector.Vector2(event.delta.dx, -event.delta.dy);
        }
        markNeedsPaint();
      }
    } else if (event is PointerUpEvent) {
      if (_draggingNode != null) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          controller.needUpdate();
        });
      }
      _downPosition = null;
      _draggingNode = null;
    }
    return super.handleEvent(event, entry);
  }
}

class ForceDirectedGraphParentData extends ContainerBoxParentData<RenderBox> {
  Node? node;
  Edge? edge;
  Matrix4? transform;

  ForceDirectedGraphParentData();
}
