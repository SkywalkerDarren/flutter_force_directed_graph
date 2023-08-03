import 'dart:convert';
import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'config.dart';
import 'edge.dart';
import 'node.dart';

class ForceDirectedGraph<T> {
  final List<Node<T>> nodes = [];
  final List<Edge> edges = [];
  final GraphConfig config;

  /// Create an empty graph.
  ForceDirectedGraph({this.config = const GraphConfig()});

  /// Generate a random tree graph.
  /// [nodeCount] is the max node count.
  /// [maxDepth] is the max depth of the tree.
  /// [n] is the max children count of a node.
  /// [generator] is the generator of the node data. Make sure the data is unique.
  ForceDirectedGraph.generateNTree({
    required int nodeCount,
    required int maxDepth,
    required int n,
    required T Function() generator,
    this.config = const GraphConfig(),
  }) {
    Random random = Random();
    final root = Node(generator());
    nodes.add(root);
    _createNTree(root, nodeCount - 1, maxDepth - 1, n, random, generator);
  }

  ForceDirectedGraph.fromJson(
    String json, {
    bool resetPosition = false,
    this.config = const GraphConfig(),
  }) {
    final data = jsonDecode(json);
    final nodeMap = <T, Node<T>>{};
    for (final nodeData in data['nodes']) {
      final node = Node(nodeData['data'] as T);
      if (!resetPosition && nodeData['position'] != null) {
        node.position =
            Vector2(nodeData['position']['x'], nodeData['position']['y']);
      }
      nodes.add(node);
      nodeMap[node.data] = node;
    }
    for (final edgeData in data['edges']) {
      final a = nodeMap[edgeData['a']];
      final b = nodeMap[edgeData['b']];
      if (a != null && b != null) {
        final edge = Edge(a, b);
        edges.add(edge);
      }
    }
  }

  void _createNTree(
    Node<T> node,
    int remainingNodes,
    int remainingDepth,
    int n,
    Random random,
    T Function() generator,
  ) {
    if (remainingNodes <= 0 || remainingDepth == 0) {
      return;
    }

    int nodesAtThisLevel = min(n, remainingNodes);
    final children = [];
    for (int i = 0; i < nodesAtThisLevel; i++) {
      final newNode = Node(generator());
      children.add(newNode);
      addNode(newNode);
      addEdge(Edge(node, newNode));
      remainingNodes--;
    }

    for (final childNode in children) {
      if (remainingNodes <= 0) {
        break;
      }
      int childNodeCount = random.nextInt(remainingNodes + 1);
      _createNTree(
        childNode,
        childNodeCount,
        remainingDepth - 1,
        n,
        random,
        generator,
      );
      remainingNodes -= childNodeCount;
    }
  }

  void addNode(Node<T> node) {
    if (nodes.contains(node)) {
      throw Exception('Node already exists');
    }
    nodes.add(node);
  }

  void addEdge(Edge edge) {
    if (edges.contains(edge)) {
      throw Exception('Edge already exists');
    }
    edges.add(edge);
  }

  void deleteNode(Node node) {
    nodes.remove(node);
    edges.removeWhere((edge) => edge.a == node || edge.b == node);
  }

  void deleteEdge(Edge edge) {
    edges.remove(edge);
  }

  void updateAllNodesByStep(int step) {
    for (int i = 0; i < step; i++) {
      if (!updateAllNodes()) {
        break;
      }
    }
  }

  bool updateAllNodes() {
    for (final node in nodes) {
      for (final other in nodes) {
        if (node == other) continue;
        if (node.position.distanceTo(other.position) > config.repulsionRange) {
          continue;
        }
        final repulsionForce =
            node.calculateRepulsionForce(other, k: config.repulsion);
        node.applyForce(repulsionForce);
      }
    }
    for (final edge in edges) {
      final attractionForce = edge.calculateAttractionForce(
          k: config.elasticity, length: config.length);
      final attractionForceDirectionA =
          edge.calculateAttractionForceDirectionA();
      final fa = attractionForceDirectionA * attractionForce;
      edge.a.applyForce(fa);
      edge.b.applyForce(-fa);
    }
    bool positionUpdated = false;
    for (final node in nodes) {
      positionUpdated |= node.updatePosition(
        scaling: config.scaling,
        minVelocity: config.minVelocity,
        maxStaticFriction: config.maxStaticFriction,
      );
    }
    return positionUpdated;
  }

  void unStaticAllNodes() {
    for (final node in nodes) {
      node.unStatic();
    }
  }

  @override
  String toString() {
    return "\nnodes:\n$nodes,\nedges:\n$edges";
  }

  String toJson() {
    return jsonEncode({
      'nodes': nodes
          .map((e) => {
                'data': e.data,
                'position': {'x': e.position.x, 'y': e.position.y},
              })
          .toList(),
      'edges': edges
          .map((e) => {
                'a': e.a.data,
                'b': e.b.data,
              })
          .toList(),
    });
  }
}
