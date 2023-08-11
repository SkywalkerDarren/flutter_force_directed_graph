import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math.dart';

import '../model/edge.dart';
import '../model/graph.dart';
import '../model/node.dart';

class ForceDirectedGraphController<T> extends ChangeNotifier {
  final ForceDirectedGraph<T> _graph;

  /// Set graph.
  set graph(ForceDirectedGraph<T> graph) {
    _graph.nodes.clear();
    _graph.edges.clear();
    _graph.nodes.addAll(graph.nodes);
    _graph.edges.addAll(graph.edges);
    notifyListeners();
  }

  /// Get graph.
  ForceDirectedGraph<T> get graph => _graph;

  ForceDirectedGraphController(
      {ForceDirectedGraph<T>? graph,
      double minScale = 0.1,
      double maxScale = 2.0})
      : _graph = graph ?? ForceDirectedGraph(),
        assert(minScale <= maxScale),
        assert(minScale > 0),
        assert(maxScale > 0),
        _minScale = minScale,
        _maxScale = maxScale;

  /// Min scale of the graph.
  double _minScale;

  /// Max scale of the graph.
  double _maxScale;

  double get minScale => _minScale;

  double get maxScale => _maxScale;

  set minScale(double minScale) {
    assert(minScale <= _maxScale);
    assert(minScale > 0);
    _minScale = minScale;
  }

  set maxScale(double maxScale) {
    assert(maxScale >= _minScale);
    assert(maxScale > 0);
    _maxScale = maxScale;
  }

  double _scale = 1.0;

  /// Scale of the graph. Clamped between [minScale] and [maxScale].
  set scale(double scale) {
    _scale = scale.clamp(minScale, maxScale);
    _onScaleChange?.call(_scale);
    notifyListeners();
  }

  Function(double scale)? _onScaleChange;

  void setOnScaleChange(Function(double scale) onScaleChange) {
    _onScaleChange = onScaleChange;
  }

  /// Scale of the graph. Clamped between [minScale] and [maxScale].
  double get scale => _scale;

  /// Center the graph.
  void center() {
    Vector2 sum = Vector2.zero();
    for (final node in _graph.nodes) {
      sum.add(node.position);
    }
    sum.scale(1.0 / _graph.nodes.length);
    locateToPosition(sum.x, sum.y);
    notifyListeners();
  }

  /// Locate to the given position.
  void locateToPosition(double x, double y) {
    final position = Vector2(x, y);
    for (final node in _graph.nodes) {
      node.position -= position;
    }
    notifyListeners();
  }

  /// Locate to the node with the given data.
  void locateTo(T data) {
    final located = _graph.nodes
        .firstWhereOrNull((element) => element.data == data)
        ?.position;
    if (located != null) {
      locateToPosition(located.x, located.y);
      notifyListeners();
    }
  }

  /// Add node. Returns the added node.
  Node<T> addNode(T data) {
    final node = Node(data);
    _graph.addNode(node);
    notifyListeners();
    return node;
  }

  /// Add edge by node.
  void addEdgeByNode(Node<T> a, Node<T> b) {
    _graph.addEdge(a.connect(b));
    notifyListeners();
  }

  /// Add edge by data. If the node is not found, add it.
  void addEdgeByData(T a, T b) {
    final nodeA = _graph.nodes
        .firstWhere((element) => element.data == a, orElse: () => addNode(a));
    final nodeB = _graph.nodes
        .firstWhere((element) => element.data == b, orElse: () => addNode(b));
    addEdgeByNode(nodeA, nodeB);
  }

  /// Delete node. If the node is not found, do nothing.
  void deleteNode(Node<T> node) {
    _graph.nodes.remove(node);
    _graph.edges
        .removeWhere((element) => element.a == node || element.b == node);
    notifyListeners();
  }

  /// Delete node by data. If the node is not found, do nothing.
  void deleteNodeByData(T data) {
    final node =
        _graph.nodes.firstWhereOrNull((element) => element.data == data);
    if (node != null) {
      deleteNode(node);
    }
  }

  /// Delete edge. If the edge is not found, do nothing.
  void deleteEdge(Edge edge) {
    _graph.edges.remove(edge);
    notifyListeners();
  }

  /// Delete edge by data. If the edge is not found, do nothing.
  void deleteEdgeByData(T a, T b) {
    final nodeA = _graph.nodes.firstWhereOrNull((element) => element.data == a);
    final nodeB = _graph.nodes.firstWhereOrNull((element) => element.data == b);
    if (nodeA != null && nodeB != null) {
      final edge = _graph.edges.firstWhereOrNull(
          (element) => element.a == nodeA && element.b == nodeB);
      if (edge != null) {
        deleteEdge(edge);
      }
    }
  }

  /// Notifies listeners that they should update.
  void needUpdate() {
    notifyListeners();
  }

  /// Serialize to json.
  String toJson() {
    return _graph.toJson();
  }
}
