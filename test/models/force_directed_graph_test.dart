import 'package:flutter_force_directed_graph/algo/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart';


void main() {
  group('Force Directed Graph', () {
    test('fdg test', () {
      final fdg = ForceDirectedGraph();
      final nodeA = Node(1);
      nodeA.position = Vector2(-1, -1);
      final nodeB = Node(2);
      nodeB.position = Vector2(2, 3);
      final nodeC = Node(3);
      nodeC.position = Vector2(-2, 2);

      fdg.addNode(nodeA);
      fdg.addNode(nodeB);
      fdg.addNode(nodeC);

      fdg.addEdge(nodeA.connect(nodeB));
      fdg.addEdge(nodeA.connect(nodeC));
      fdg.addEdge(nodeB.connect(nodeC));

      fdg.updateAllNodesByStep(100);
    });
  });
}