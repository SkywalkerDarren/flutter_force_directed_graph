import 'package:flutter/widgets.dart';
import 'package:flutter_force_directed_graph/algo/models.dart';
import 'package:collection/collection.dart';
import 'package:vector_math/vector_math.dart';

class ForceDirectedGraphController<T> extends ChangeNotifier {
  ForceDirectedGraph<T> _graph;

  set graph(ForceDirectedGraph<T> value) {
    _graph = value;
    notifyListeners();
  }

  ForceDirectedGraph<T> get graph => _graph;

  ForceDirectedGraphController({ForceDirectedGraph<T>? graph}) : _graph = graph ?? ForceDirectedGraph();

  void center() {
    Vector2 sum = Vector2.zero();
    for (final node in _graph.nodes) {
      sum.add(node.position);
    }
    sum.scale(1.0 / _graph.nodes.length);
    for (final node in _graph.nodes) {
      node.position -= sum;
    }
    notifyListeners();
  }

  void locateTo(T data) {
    final located = _graph.nodes.firstWhereOrNull((element) => element.data == data)?.position;
    if (located != null) {
      for (final node in _graph.nodes) {
        node.position -= located;
      }
      notifyListeners();
    }
  }

  Node<T> addNode(T data) {
    final node = Node(data);
    _graph.addNode(node);
    notifyListeners();
    return node;
  }

  void addEdgeByNode(Node<T> a, Node<T> b) {
    _graph.addEdge(a.connect(b));
    notifyListeners();
  }

  void addEdgeByData(T a, T b) {
    final nodeA = _graph.nodes.firstWhere((element) => element.data == a, orElse: () => addNode(a));
    final nodeB = _graph.nodes.firstWhere((element) => element.data == b, orElse: () => addNode(b));
    addEdgeByNode(nodeA, nodeB);
  }

  void deleteNode(Node<T> node) {
    _graph.nodes.remove(node);
    _graph.edges.removeWhere((element) => element.a == node || element.b == node);
    notifyListeners();
  }

  void deleteNodeByData(T data) {
    final node = _graph.nodes.firstWhereOrNull((element) => element.data == data);
    if (node != null) {
      deleteNode(node);
    }
  }

  void deleteEdge(Edge edge) {
    _graph.edges.remove(edge);
    notifyListeners();
  }

  void deleteEdgeByData(T a, T b) {
    final nodeA = _graph.nodes.firstWhereOrNull((element) => element.data == a);
    final nodeB = _graph.nodes.firstWhereOrNull((element) => element.data == b);
    if (nodeA != null && nodeB != null) {
      final edge = _graph.edges.firstWhereOrNull((element) => element.a == nodeA && element.b == nodeB);
      if (edge != null) {
        deleteEdge(edge);
      }
    }
  }

  void needUpdate() {
    notifyListeners();
  }
}
