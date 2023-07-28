import 'package:flutter/widgets.dart';
import 'package:flutter_force_directed_graph/algo/models.dart';
import 'package:collection/collection.dart';

class ForceDirectedGraphController<T> extends ChangeNotifier {
  final ForceDirectedGraph<T> _graph;
  ForceDirectedGraph<T> get graph => _graph;

  ForceDirectedGraphController({ForceDirectedGraph<T>? graph}) : _graph = graph ?? ForceDirectedGraph();

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

  bool isUpdating = false;

  Future updateToFinish() async {
    if (isUpdating) {
      return;
    }
    print("start graph: $_graph");
    int stepLeft = 120 * 1000;
    isUpdating = true;
    while (true) {
      if (!_graph.updateAllNodes()) {
        print("finished graph: $_graph");
        notifyListeners();
        break;
      }
      notifyListeners();
      print("stepLeft: $stepLeft");
      await WidgetsBinding.instance.endOfFrame;
      await WidgetsBinding.instance.endOfFrame;
      stepLeft--;
    }
    isUpdating = false;
  }

  void update() {
    isUpdating = true;
    _graph.updateAllNodes();
    notifyListeners();
    isUpdating = false;
  }
}
