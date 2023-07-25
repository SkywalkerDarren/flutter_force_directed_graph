import 'package:flutter_force_directed_graph/algo/models.dart';

class ForceDirectedGraphController<T> {
  final ForceDirectedGraph<T> _graph;
  ForceDirectedGraph<T> get graph => _graph;

  ForceDirectedGraphController({ForceDirectedGraph<T>? graph}) : _graph = graph ?? ForceDirectedGraph();

  Node<T> addNode(T data) {
    final node = Node(data);
    _graph.addNode(node);
    return node;
  }

  void addEdgeByNode(Node<T> a, Node<T> b) {
    _graph.addEdge(a.connect(b));
  }

  void addEdgeByData(T a, T b) {
    final nodeA = _graph.nodes.firstWhere((element) => element.data == a, orElse: () => addNode(a));
    final nodeB = _graph.nodes.firstWhere((element) => element.data == b, orElse: () => addNode(b));
    addEdgeByNode(nodeA, nodeB);
  }
}
