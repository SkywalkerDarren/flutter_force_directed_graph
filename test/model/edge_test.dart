// ignore_for_file: avoid_print

import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  group('Edge', () {
    late Node nodeA;
    late Node nodeB;
    late Edge edge;

    setUp(() {
      // Create two nodes for testing
      nodeA = Node(1);
      nodeA.position = Vector2(-1, -1);
      nodeB = Node(2);
      nodeB.position = Vector2(2, 3);

      // Create an edge connecting the two nodes
      edge = Edge(nodeA, nodeB);
    });

    test('Edge distance calculation', () {
      expect(edge.distance, closeTo(5, 0.0001));
    });

    test('Attraction force calculation', () {
      expect(edge.calculateAttractionForce(k: 10, length: 50),
          closeTo(-450, 0.0001));
    });

    test('Attraction force direction for node A', () {
      final forceDirection = edge.calculateAttractionForceDirectionA();
      expect(forceDirection.x, closeTo(0.6, 0.0001));
      expect(forceDirection.y, closeTo(0.8, 0.0001));
    });

    test('Attraction force direction for node B', () {
      final forceDirection = edge.calculateAttractionForceDirectionB();
      expect(forceDirection.x, closeTo(-0.6, 0.0001));
      expect(forceDirection.y, closeTo(-0.8, 0.0001));
    });

    test('Balance test', () {
      const config = GraphConfig();

      for (int i = 0; i < 100; i++) {
        final f1 = nodeA.calculateRepulsionForce(nodeB, k: config.repulsion);
        final f2 = nodeB.calculateRepulsionForce(nodeA, k: config.repulsion);
        nodeA.applyForce(f1);
        nodeB.applyForce(f2);
        print(nodeA);
        print(nodeB);
        print('fr: ${f1.length}');
        print('计算斥力-------------------');
        final fa = edge.calculateAttractionForce(
            k: config.elasticity, length: config.length);
        final faa = edge.calculateAttractionForceDirectionA();
        final fab = edge.calculateAttractionForceDirectionB();
        nodeA.applyForce(faa * fa);
        nodeB.applyForce(fab * fa);
        print(nodeA);
        print(nodeB);
        print("fa=$fa, faa=$faa, fab=$fab");
        print('计算引力-------------------');
        final canUpdateA = nodeA.updatePosition(
          scaling: config.scaling,
          minVelocity: config.minVelocity,
          maxStaticFriction: config.maxStaticFriction,
          damping: config.damping,
        );
        final canUpdateB = nodeB.updatePosition(
          scaling: config.scaling,
          minVelocity: config.minVelocity,
          maxStaticFriction: config.maxStaticFriction,
          damping: config.damping,
        );
        if (!canUpdateA && !canUpdateB) {
          print('平衡, $nodeA, $nodeB, ${edge.distance}');

          final a = nodeA.updatePosition(
            scaling: config.scaling,
            minVelocity: config.minVelocity,
            maxStaticFriction: config.maxStaticFriction,
            damping: config.damping,
          );
          final b = nodeB.updatePosition(
            scaling: config.scaling,
            minVelocity: config.minVelocity,
            maxStaticFriction: config.maxStaticFriction,
            damping: config.damping,
          );
          expect(b, false);
          expect(a, false);

          return;
        }
        print(nodeA);
        print(nodeB);
        print('edge distance: ${edge.distance}');
        print('---------step: $i---------');
        print('');
      }
      fail('未达到平衡');
    });
  });
}
