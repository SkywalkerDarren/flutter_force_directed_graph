// ignore_for_file: avoid_print

import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:flutter_force_directed_graph/model/kd_tree.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math.dart';

void main() {
  group('KDTree test', () {
    test('KDTree test', () {
      for (int i = 0; i < 10; i++) {
        final nodes = List.generate(500, (index) => Node(index));
        final testNode = nodes[0];
        const radius = 20.0;

        final kdTree = KDTree.fromNode(nodes);

        final searched = kdTree.findNeighbors(testNode.position, radius);

        for (final n in nodes) {
          final distance = testNode.position.distanceTo(n.position);
          if (searched.contains(n)) {
            expect(distance, lessThanOrEqualTo(radius),
                reason: "distance: $distance, raw: $nodes");
          } else {
            expect(distance, greaterThanOrEqualTo(radius),
                reason: "distance: $distance, raw: $nodes");
          }
        }
      }
    });

    test('KDTree time test', () {
      final nodes = List.generate(1000, (index) => Node(index));
      const radius = 20.0;

      final t1 = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < 1000; i++) {
        final kdTree = KDTree.fromNode(nodes, false);
        for (final node in nodes) {
          kdTree.findNeighbors(node.position, radius);
        }
      }
      print("${DateTime.now().millisecondsSinceEpoch - t1}ms");
      final t2 = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < 1000; i++) {
        final kdTree = KDTree.fromNode(nodes, true);
        for (final node in nodes) {
          kdTree.findNeighbors(node.position, radius);
        }
      }
      print("${DateTime.now().millisecondsSinceEpoch - t2}ms");
    });

    test('debug', () {
      final nodes = [
        Node(0, Vector2(52.16178894042969, 60.370574951171875)),
        Node(1, Vector2(94.0291748046875, -61.245845794677734)),
        Node(2, Vector2(-28.89512825012207, -65.7607650756836)),
        Node(3, Vector2(-11.021280288696289, -37.021148681640625)),
        Node(4, Vector2(65.98552703857422, -96.6162109375)),
      ];

      final testNode = nodes[0];
      const radius = 20.0;

      final kdTree = KDTree.fromNode(nodes);

      final searched = kdTree.findNeighbors(testNode.position, radius);

      for (final n in nodes) {
        final distance = testNode.position.distanceTo(n.position);
        if (searched.contains(n)) {
          expect(distance, lessThanOrEqualTo(radius),
              reason: "distance: $distance, raw: $nodes");
        } else {
          expect(distance, greaterThanOrEqualTo(radius),
              reason: "distance: $distance, raw: $nodes");
        }
      }
    });
  });
}
