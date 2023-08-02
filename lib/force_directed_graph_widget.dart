import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_force_directed_graph/edge_widget.dart';
import 'package:flutter_force_directed_graph/node_widget.dart';
import 'package:vector_math/vector_math.dart' as vector;

import 'force_directed_graph_controller.dart';
import 'algo/models.dart';

typedef NodeBuilder<T> = Widget Function(BuildContext context, T data);
typedef EdgeBuilder<T> = Widget Function(BuildContext context, T a, T b, double distance);

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
  ForceDirectedGraphController<T> get _controller => widget.controller;
  late Ticker _ticker;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final isMoving = _controller.graph.updateAllNodes();
    if (!isMoving) {
      _ticker.stop();
    }
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant ForceDirectedGraphWidget<T> oldWidget) {
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_onControllerChange);
      widget.controller.addListener(_onControllerChange);

      if (_ticker.isActive) {
        _ticker.stop();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _controller.graph.nodes.map((e) {
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

    final edges = _controller.graph.edges.map((e) {
      final child = widget.edgesBuilder(context, e.a.data, e.b.data, e.distance);
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



    return GestureDetector(
      onScaleStart: (details) {
        _scale = _controller.scale;
      },
      onScaleUpdate: (details) {
        final scale = (_scale * details.scale).clamp(_controller.minScale, _controller.maxScale);
        _controller.scale = scale;
      },
      child: RepaintBoundary(
        child: ClipRect(
          child: ForceDirectedGraphBody(
            controller: _controller,
            graph: _controller.graph,
            scale: _controller.scale,
            nodes: nodes,
            edges: edges,
          ),
        ),
      ),
    );
  }
}

class ForceDirectedGraphBody extends MultiChildRenderObjectWidget {
  final ForceDirectedGraph graph;
  final ForceDirectedGraphController controller;
  final double scale;

  ForceDirectedGraphBody({
    Key? key,
    required this.controller,
    required this.graph,
    required this.scale,
    required Iterable<NodeWidget> nodes,
    required Iterable<EdgeWidget> edges,
  }) : super(key: key, children: [...edges, ...nodes]);

  @override
  ForceDirectedGraphRenderObject createRenderObject(BuildContext context) {
    return ForceDirectedGraphRenderObject(graph: graph, controller: controller);
  }

  @override
  void updateRenderObject(BuildContext context, ForceDirectedGraphRenderObject renderObject) {
    renderObject
      ..graph = graph
      .._scale = scale;
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

  double _scale = 1;

  set scale(double value) {
    _scale = value;
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
    context.canvas.scale(_scale, _scale);
    // 获取children
    final children = getChildrenAsList();
    for (final child in children) {
      context.canvas.save();

      final parentData = child.parentData! as ForceDirectedGraphParentData;
      final childCenter = child.size.center(Offset.zero);

      if (parentData.node != null) {
        // 绘制节点
        final data = parentData.node!.data;
        final node = _graph.nodes.firstWhere((element) => element.data == data);
        final moveOffset = Offset(node.position.x, -node.position.y);
        final finalOffset = -childCenter + moveOffset;
        context.paintChild(child, finalOffset);
        final childOffset = moveOffset + center - offset - childCenter;
        parentData.transform = Matrix4.identity()
          ..translate(center.dx, center.dy)
          ..scale(_scale, _scale)
          ..translate(-center.dx, -center.dy)
          ..translate(childOffset.dx, childOffset.dy);
      } else if (parentData.edge != null) {
        // 绘制边
        final edge = _graph.edges.firstWhere((element) => element == parentData.edge);
        final edgeCenter = (edge.a.position + edge.b.position) / 2;
        final moveOffset = Offset(edgeCenter.x, -edgeCenter.y);
        final finalOffset = -childCenter + moveOffset;
        context.canvas
          ..translate(moveOffset.dx, moveOffset.dy)
          ..rotate(edge.angle)
          ..translate(-moveOffset.dx, -moveOffset.dy);
        context.paintChild(child, finalOffset);
        final childOffset = moveOffset + center - offset - childCenter;
        parentData.transform = Matrix4.identity()
          ..translate(center.dx, center.dy)
          ..scale(_scale, _scale)
          ..translate(-center.dx, -center.dy)
          ..translate(childOffset.dx + childCenter.dx, childOffset.dy + childCenter.dy)
          ..rotateZ(edge.angle)
          ..translate(-childCenter.dx, -childCenter.dy);
      } else {
        throw Exception('Unknown child');
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
      final bool isHit = result.addWithPaintTransform(
        transform: childParentData.transform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        _draggingNode = childParentData.node;
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
        _draggingNode!.isFixed = true;
      }
      // ignore
    } else if (event is PointerMoveEvent) {
      if (_draggingNode != null) {
        // 移动节点
        _draggingNode!.isFixed = true;
        _downPosition = _downPosition! + vector.Vector2(event.delta.dx / _scale, -event.delta.dy / _scale);
        _draggingNode!.position = _downPosition!;
        markNeedsPaint();
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          controller.needUpdate();
        });
      } else {
        // 移动画布
        for (final node in _graph.nodes) {
          node.position += vector.Vector2(event.delta.dx / _scale, -event.delta.dy / _scale);
        }
        markNeedsPaint();
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_draggingNode != null) {
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          controller.needUpdate();
        });
      }
      _downPosition = null;
      _draggingNode = null;
    }
  }
}

class ForceDirectedGraphParentData extends ContainerBoxParentData<RenderBox> {
  Node? node;
  Edge? edge;
  Matrix4? transform;

  ForceDirectedGraphParentData();
}
