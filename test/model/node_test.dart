import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  group('Node', () {
    const config = GraphConfig(
      maxStaticFriction: 20.0,
      scaling: 0.01,
      elasticity: 1.0,
      repulsion: 30.0,
      repulsionRange: 150.0,
      minVelocity: 10,
      length: 50.0,
      damping: 0.93,
    );

    test('should calculate repulsive force between two nodes', () {
      final node1 = Node(1);
      node1.position = Vector2(0, 1);
      final node2 = Node(2);
      node2.position = Vector2(1, 0);

      final force = node1.calculateRepulsionForce(node2, k: config.repulsion);

      expect(force.x, closeTo(-450, 0.001));
      expect(force.y, closeTo(450, 0.001));
    });

    test('max repulsion distance', () {
      final node1 = Node(1);
      node1.position = Vector2(0, 100);
      final node2 = Node(2);
      node2.position = Vector2(0, 0);

      final force = node1.calculateRepulsionForce(node2, k: config.repulsion);

      expect(force.x, closeTo(0, 0.001));
      expect(force.y, closeTo(9, 0.001));
    });

    test('should connect two nodes with an edge', () {
      final node1 = Node(1);
      final node2 = Node(2);

      final edge = node1.connect(node2);

      expect(edge.a, equals(node1));
      expect(edge.b, equals(node2));

      bool hasCatch = false;
      try {
        node1.connect(node1);
      } on Exception catch (e) {
        hasCatch = true;
        expect(e, isA<Exception>());
        expect(e.toString(), contains("Cannot create edge between the same node"));
      }
      expect(hasCatch, true);
    });

    test('should compare nodes based on their data', () {
      final node1 = Node(1);
      final node2 = Node(2);

      expect(node1 == node2, isFalse);

      final node3 = Node(1);

      expect(node1 == node3, isTrue);
    });

    test('should get hash code based on data', () {
      final node1 = Node(1);
      final node2 = Node(2);

      expect(node1.hashCode, isNot(equals(node2.hashCode)));

      final node3 = Node(1);

      expect(node1.hashCode, equals(node3.hashCode));
    });
  });
}
