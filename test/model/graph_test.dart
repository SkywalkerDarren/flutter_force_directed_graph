// ignore_for_file: avoid_print

import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Force Directed Graph', () {
    test('fdg test', () {
      final fdg = ForceDirectedGraph();
      final nodeA = Node(1);
      // nodeA.position = Vector2(-1, -1);
      final nodeB = Node(2);
      // nodeB.position = Vector2(2, 3);
      final nodeC = Node(3);
      // nodeC.position = Vector2(-2, 2);

      fdg.addNode(nodeA);
      fdg.addNode(nodeB);
      fdg.addNode(nodeC);

      fdg.addEdge(nodeA.connect(nodeB));
      fdg.addEdge(nodeA.connect(nodeC));
      fdg.addEdge(nodeB.connect(nodeC));

      int stepLeft = 120 * 1000;
      while (stepLeft > 0) {
        if (!fdg.updateAllNodes()) {
          print("graph: $fdg, stepLeft: $stepLeft");
          final retry = fdg.updateAllNodes();
          expect(retry, false);
          return;
        }
        stepLeft--;
      }
      fail("fdg test failed");
    });

    test("fdg json", () {
      int i = 0;
      final fdg = ForceDirectedGraph.generateNTree(
          nodeCount: 50, maxDepth: 3, n: 3, generator: () => i++);
      final json = fdg.toJson();
      final fdg2 = ForceDirectedGraph.fromJson(json);
      expect(fdg2.nodes.length, fdg.nodes.length);
      expect(fdg2.edges.length, fdg.edges.length);
    });

    test("fdg serialize json", () {
      int i = 0;
      final fdg = ForceDirectedGraph.generateNTree(
          nodeCount: 50, maxDepth: 3, n: 3, generator: () => _TestModel(i++));
      final json = fdg.toJson(serializeData: (data) => data.toJson());
      final fdg2 = ForceDirectedGraph.fromJson(json,
          deserializeData: (json) => _TestModel.fromJson(json));
      expect(fdg2.nodes.length, fdg.nodes.length);
      expect(fdg2.edges.length, fdg.edges.length);
    });
  });
}

class _TestModel {
  final int id;

  _TestModel(this.id);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }

  factory _TestModel.fromJson(Map<String, dynamic> json) {
    return _TestModel(json['id']);
  }

  @override
  bool operator ==(Object other) {
    if (other is _TestModel) {
      return id == other.id;
    }
    return false;
  }

  @override
  int get hashCode => id.hashCode;

}
