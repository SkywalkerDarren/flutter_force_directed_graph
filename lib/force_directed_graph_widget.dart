import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_force_directed_graph/edge_widget.dart';
import 'package:flutter_force_directed_graph/node_widget.dart';
import 'package:vector_math/vector_math.dart' as vector;

import 'force_directed_graph_controller.dart';
import 'algo/models.dart';

/// A builder that builds a node.
/// [context] is the build context.
/// [data] is the data of the node.
typedef NodeBuilder<T> = Widget Function(BuildContext context, T data);

/// A builder that builds an edge.
/// [context] is the build context.
/// [a] is the data of the node at the start of the edge.
/// [b] is the data of the node at the end of the edge.
/// [distance] is the distance between the two nodes.
typedef EdgeBuilder<T> = Widget Function(
    BuildContext context, T a, T b, double distance);

/// A widget that displays a force-directed graph.
class ForceDirectedGraphWidget<T> extends StatefulWidget {
  const ForceDirectedGraphWidget({
    super.key,
    required this.controller,
    required this.nodesBuilder,
    required this.edgesBuilder,
    this.onDraggingStart,
    this.onDraggingUpdate,
    this.onDraggingEnd,
  });

  /// The controller of the graph.
  final ForceDirectedGraphController<T> controller;

  /// The builder of the nodes.
  final NodeBuilder<T> nodesBuilder;

  /// The builder of the edges.
  final EdgeBuilder<T> edgesBuilder;

  /// Called when a node is start dragging.
  final void Function(T data)? onDraggingStart;

  /// Called when a node is dragging.
  final void Function(T data)? onDraggingUpdate;

  /// Called when a node is end dragging.
  final void Function(T data)? onDraggingEnd;

  @override
  State<ForceDirectedGraphWidget<T>> createState() =>
      _ForceDirectedGraphState<T>();
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
      final child =
          widget.edgesBuilder(context, e.a.data, e.b.data, e.distance);
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
        final scale = (_scale * details.scale)
            .clamp(_controller.minScale, _controller.maxScale);
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
            onDraggingStart: (data) {
              widget.onDraggingStart?.call(data);
            },
            onDraggingEnd: (data) {
              widget.onDraggingEnd?.call(data);
            },
            onDraggingUpdate: (data) {
              widget.onDraggingUpdate?.call(data);
            },
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
  final void Function(dynamic data) onDraggingStart;
  final void Function(dynamic data) onDraggingEnd;
  final void Function(dynamic data) onDraggingUpdate;

  ForceDirectedGraphBody({
    Key? key,
    required this.controller,
    required this.graph,
    required this.scale,
    required Iterable<NodeWidget> nodes,
    required Iterable<EdgeWidget> edges,
    required this.onDraggingUpdate,
    required this.onDraggingStart,
    required this.onDraggingEnd,
  }) : super(key: key, children: [...edges, ...nodes]);

  @override
  ForceDirectedGraphRenderObject createRenderObject(BuildContext context) {
    return ForceDirectedGraphRenderObject(
        graph: graph,
        controller: controller,
        onDraggingUpdate: onDraggingUpdate,
        onDraggingStart: onDraggingStart,
        onDraggingEnd: onDraggingEnd);
  }

  @override
  void updateRenderObject(
      BuildContext context, ForceDirectedGraphRenderObject renderObject) {
    renderObject
      ..graph = graph
      .._scale = scale;
  }
}

class ForceDirectedGraphRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ForceDirectedGraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            ForceDirectedGraphParentData> {
  ForceDirectedGraphRenderObject(
      {required ForceDirectedGraph graph,
      required this.controller,
      required this.onDraggingUpdate,
      required this.onDraggingStart,
      required this.onDraggingEnd})
      : _graph = graph;

  final ForceDirectedGraphController controller;

  final void Function(dynamic data) onDraggingStart;
  final void Function(dynamic data) onDraggingUpdate;
  final void Function(dynamic data) onDraggingEnd;

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
    context.canvas.save();
    context.canvas.translate(center.dx, center.dy);
    context.canvas.scale(_scale, _scale);

    final children = getChildrenAsList();
    for (final child in children) {
      context.canvas.save();

      final parentData = child.parentData! as ForceDirectedGraphParentData;
      final childCenter = child.size.center(Offset.zero);

      if (parentData.node != null) {
        // paint node
        final node = parentData.node!;
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
        // paint edge
        final edge = parentData.edge!;
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
          ..translate(
              childOffset.dx + childCenter.dx, childOffset.dy + childCenter.dy)
          ..rotateZ(edge.angle)
          ..translate(-childCenter.dx, -childCenter.dy);
      } else {
        throw Exception('Unknown child');
      }
      context.canvas.restore();
    }
    context.canvas.restore();
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
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      if (_draggingNode != null) {
        onDraggingStart(_draggingNode!.data);
        _downPosition = _draggingNode!.position;
        _graph.unStaticAllNodes();
        _draggingNode!.static();
      }
    } else if (event is PointerMoveEvent) {
      if (_draggingNode != null) {
        // move node
        onDraggingUpdate(_draggingNode!.data);
        _downPosition = _downPosition! +
            vector.Vector2(event.delta.dx / _scale, -event.delta.dy / _scale);
        _draggingNode!.position = _downPosition!;
        markNeedsPaint();
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          controller.needUpdate();
        });
      } else {
        // move graph
        for (final node in _graph.nodes) {
          node.position +=
              vector.Vector2(event.delta.dx / _scale, -event.delta.dy / _scale);
        }
        markNeedsPaint();
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      if (_draggingNode != null) {
        _draggingNode?.unStatic();
        onDraggingEnd(_draggingNode!.data);
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
