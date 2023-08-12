import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math.dart' as vector;

import '../model/edge.dart';
import '../model/graph.dart';
import '../model/node.dart';
import 'edge_widget.dart';
import 'force_directed_graph_controller.dart';
import 'node_widget.dart';

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
    this.cachePaintOffset = 50,
    required this.nodesBuilder,
    required this.edgesBuilder,
    this.onDraggingStart,
    this.onDraggingUpdate,
    this.onDraggingEnd,
  }) : assert(cachePaintOffset >= 0);

  /// The controller of the graph.
  final ForceDirectedGraphController<T> controller;

  /// Used to optimize drawing performance.
  /// When the center of the node is out of the screen by more than this offset,
  /// the drawing will stop.
  final double cachePaintOffset;

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
  Rect paintBound = Rect.zero;

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

  bool _isLineIntersectsRect(Offset p1, Offset p2, Rect rect) {
    // Rect four corners
    Offset topLeft = rect.topLeft;
    Offset topRight = rect.topRight;
    Offset bottomLeft = rect.bottomLeft;
    Offset bottomRight = rect.bottomRight;

    // Check if the line segment intersects any of the sides of the Rect
    return _isLineIntersect(p1, p2, topLeft, topRight) ||
        _isLineIntersect(p1, p2, topLeft, bottomLeft) ||
        _isLineIntersect(p1, p2, topRight, bottomRight) ||
        _isLineIntersect(p1, p2, bottomLeft, bottomRight);
  }

  bool _isLineIntersect(Offset p1, Offset p2, Offset q1, Offset q2) {
    double cross1 = _crossProduct(p1, p2, q1);
    double cross2 = _crossProduct(p1, p2, q2);
    double cross3 = _crossProduct(q1, q2, p1);
    double cross4 = _crossProduct(q1, q2, p2);

    // If the two cross products have different signs,
    // then the line segments are on opposite sides of the rectangle,
    // so they must intersect.
    return (cross1 * cross2 < 0) && (cross3 * cross4 < 0);
  }

  double _crossProduct(Offset a, Offset b, Offset c) {
    // Calculate the cross product of vectors AB and AC
    double y1 = b.dy - a.dy;
    double x1 = b.dx - a.dx;
    double y2 = c.dy - a.dy;
    double x2 = c.dx - a.dx;

    return (x1 * y2) - (x2 * y1);
  }

  bool _inRect(Offset offset, Rect rect) {
    return offset.dx >= rect.left &&
        offset.dx <= rect.right &&
        offset.dy >= rect.top &&
        offset.dy <= rect.bottom;
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _controller.graph.nodes.where((element) {
      final offset = Offset(element.position.x, element.position.y);
      return _inRect(offset, paintBound);
    }).map((e) {
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

    final edges = _controller.graph.edges.where((element) {
      final a = Offset(element.a.position.x, element.a.position.y);
      final b = Offset(element.b.position.x, element.b.position.y);
      return _inRect(a, paintBound) ||
          _inRect(b, paintBound) ||
          _isLineIntersectsRect(a, b, paintBound);
    }).map((e) {
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

    return GestureDetector(
      onScaleStart: (details) {
        _scale = _controller.scale;
      },
      onScaleUpdate: (details) {
        final scale = (_scale * details.scale)
            .clamp(_controller.minScale, _controller.maxScale);
        _controller.scale = scale;
      },
      child: NotificationListener<PaintBoundChangeNotification>(
        onNotification: (notification) {
          paintBound = notification.paintBound;
          return true;
        },
        child: RepaintBoundary(
          child: ClipRect(
            child: ForceDirectedGraphBody(
              controller: _controller,
              cachePaintOffset: widget.cachePaintOffset,
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
      ),
    );
  }
}

class ForceDirectedGraphBody extends MultiChildRenderObjectWidget {
  final ForceDirectedGraph graph;
  final ForceDirectedGraphController controller;
  final double scale;
  final double cachePaintOffset;
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
    required this.cachePaintOffset,
  }) : super(key: key, children: [...edges, ...nodes]);

  @override
  ForceDirectedGraphRenderObject createRenderObject(BuildContext context) {
    return ForceDirectedGraphRenderObject(
      graph: graph,
      scale: scale,
      cachePaintOffset: cachePaintOffset,
      controller: controller,
      onDraggingUpdate: onDraggingUpdate,
      onDraggingStart: onDraggingStart,
      onDraggingEnd: onDraggingEnd,
      onPaintBoundChange: (Rect rect) {
        PaintBoundChangeNotification(rect).dispatch(context);
      },
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, ForceDirectedGraphRenderObject renderObject) {
    renderObject
      ..graph = graph
      ..cachePaintOffset = cachePaintOffset
      ..scale = scale;
  }
}

class ForceDirectedGraphRenderObject extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, ForceDirectedGraphParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            ForceDirectedGraphParentData> {
  ForceDirectedGraphRenderObject({
    required ForceDirectedGraph graph,
    required double cachePaintOffset,
    required double scale,
    required this.controller,
    required this.onDraggingUpdate,
    required this.onDraggingStart,
    required this.onDraggingEnd,
    required this.onPaintBoundChange,
  })  : _graph = graph,
        _cachePaintOffset = cachePaintOffset,
        _scale = scale;

  final ForceDirectedGraphController controller;

  final void Function(dynamic data) onDraggingStart;
  final void Function(dynamic data) onDraggingUpdate;
  final void Function(dynamic data) onDraggingEnd;
  final void Function(Rect bound) onPaintBoundChange;

  ForceDirectedGraph _graph;

  set graph(ForceDirectedGraph value) {
    _graph = value;
    markNeedsPaint();
  }

  Rect _canPaintBound = Rect.zero;

  set canPaintBound(Rect value) {
    if (value == _canPaintBound) {
      return;
    }
    _canPaintBound = value;
    onPaintBoundChange(value);
  }

  Rect get canPaintBound => _canPaintBound;

  double _scale;

  set scale(double value) {
    if (value == _scale) {
      return;
    }
    _scale = value;
    canPaintBound = Rect.fromLTRB(
        (-size.width / 2 - cachePaintOffset) / _scale,
        (-size.height / 2 - cachePaintOffset) / _scale,
        (size.width / 2 + cachePaintOffset) / _scale,
        (size.height / 2 + cachePaintOffset) / _scale);
    markNeedsPaint();
  }

  double _cachePaintOffset;

  set cachePaintOffset(double value) {
    if (value == _cachePaintOffset) {
      return;
    }
    _cachePaintOffset = value;
    canPaintBound = Rect.fromLTRB(
        (-size.width / 2 - cachePaintOffset) / _scale,
        (-size.height / 2 - cachePaintOffset) / _scale,
        (size.width / 2 + cachePaintOffset) / _scale,
        (size.height / 2 + cachePaintOffset) / _scale);
    markNeedsPaint();
  }

  double get cachePaintOffset => _cachePaintOffset;

  // layout and paint logic ==============================================================

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! ForceDirectedGraphParentData) {
      child.parentData = ForceDirectedGraphParentData();
    }
  }

  @override
  void performLayout() {
    RenderBox? child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as ForceDirectedGraphParentData;
      child.layout(const BoxConstraints());
      child = parentData.nextSibling;
    }
  }

  Size? _oldSize;

  @override
  void performResize() {
    super.performResize();
    if (_oldSize != size) {
      canPaintBound = Rect.fromLTRB(
          (-size.width / 2 - cachePaintOffset) / _scale,
          (-size.height / 2 - cachePaintOffset) / _scale,
          (size.width / 2 + cachePaintOffset) / _scale,
          (size.height / 2 + cachePaintOffset) / _scale);
      _oldSize = size;
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      width.isInfinite ? 0 : width;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      height.isInfinite ? 0 : height;

  @override
  double computeMinIntrinsicHeight(double width) =>
      width.isInfinite ? 0 : width;

  @override
  double computeMinIntrinsicWidth(double height) =>
      height.isInfinite ? 0 : height;

  @override
  void paint(PaintingContext context, Offset offset) {
    final center = offset + size.center(Offset.zero);
    context.canvas.save();
    context.canvas.translate(center.dx, center.dy);
    context.canvas.scale(_scale, _scale);

    RenderBox? child = firstChild;
    while (child != null) {
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

        parentData.transform
          ..setIdentity()
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

        parentData.transform
          ..setIdentity()
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
      child = parentData.nextSibling;
    }
    context.canvas.restore();
  }

  // hit logic ================================================================

  Node? _hitNode;

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
        if (childParentData.node != null) {
          if (!_isDragging) {
            _hitNode = childParentData.node;
          }
        }
        return true;
      }
      child = childParentData.previousSibling;
    }
    if (!_isDragging) {
      _hitNode = null;
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  vector.Vector2? _downPosition;
  bool _isDragging = false;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      if (_hitNode != null) {
        _isDragging = true;
        onDraggingStart(_hitNode!.data);
        _downPosition = _hitNode!.position;
        _graph.unStaticAllNodes();
        _hitNode!.static();
      }
    } else if (event is PointerMoveEvent) {
      if (_hitNode != null && _isDragging) {
        // move node
        onDraggingUpdate(_hitNode!.data);
        _downPosition = _downPosition! +
            vector.Vector2(event.delta.dx / _scale, -event.delta.dy / _scale);
        _hitNode!.position = _downPosition!;
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
      _isDragging = false;
      if (_hitNode != null) {
        _hitNode?.unStatic();
        onDraggingEnd(_hitNode!.data);
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          controller.needUpdate();
        });
      }
      _downPosition = null;
      _hitNode = null;
    }
  }
}

class PaintBoundChangeNotification extends Notification {
  final Rect paintBound;

  PaintBoundChangeNotification(this.paintBound);
}

class ForceDirectedGraphParentData extends ContainerBoxParentData<RenderBox> {
  Node? node;
  Edge? edge;
  final Matrix4 transform = Matrix4.zero();

  ForceDirectedGraphParentData();
}
