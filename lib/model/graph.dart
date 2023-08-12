import 'dart:convert';
import 'dart:math';

import 'package:vector_math/vector_math.dart';

import 'config.dart';
import 'edge.dart';
import 'kd_tree.dart';
import 'node.dart';

typedef NodeDataSerializer<T> = dynamic Function(T data);
typedef NodeDataDeserializer<T> = T Function(dynamic data);

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

  /// Generate a graph with n nodes, no edges.
  /// [nodeCount] is the node count.
  /// [generator] is the generator of the node data. Make sure the data is unique.
  ForceDirectedGraph.generateNNodes({
    required int nodeCount,
    required T Function() generator,
    this.config = const GraphConfig(),
  }) {
    for (int i = 0; i < nodeCount; i++) {
      final node = Node(generator());
      nodes.add(node);
    }
  }

  /// Create a graph from json.
  /// [resetPosition] will reset the position of the nodes.
  ForceDirectedGraph.fromJson(
    String json, {
    NodeDataDeserializer<T>? deserializeData,
    bool resetPosition = false,
    this.config = const GraphConfig(),
  }) {
    final data = jsonDecode(json);
    final nodeMap = <T, Node<T>>{};
    for (final nodeData in data['nodes']) {
      final actualData = deserializeData == null
          ? nodeData['data'] as T
          : deserializeData(nodeData['data']);
      final node = Node(actualData);
      if (!resetPosition && nodeData['position'] != null) {
        node.position =
            Vector2(nodeData['position']['x'], nodeData['position']['y']);
      }
      nodes.add(node);
      nodeMap[node.data] = node;
    }
    for (final edgeData in data['edges']) {
      final actualDataA = deserializeData == null
          ? edgeData['a'] as T
          : deserializeData(edgeData['a']);
      final actualDataB = deserializeData == null
          ? edgeData['b'] as T
          : deserializeData(edgeData['b']);
      final a = nodeMap[actualDataA];
      final b = nodeMap[actualDataB];
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

  bool updateAllNodes() {
    final kdTree = KDTree.fromNode(nodes);
    for (final node in nodes) {
      final others = kdTree.findNeighbors(node.position, config.repulsionRange);
      for (final other in others) {
        if (node == other) continue;
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
        damping: config.damping,
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

  String toJson({NodeDataSerializer<T>? serializeData}) {
    return jsonEncode({
      'nodes': nodes
          .map((e) => {
                'data': serializeData == null ? e.data : serializeData(e.data),
                'position': {'x': e.position.x, 'y': e.position.y},
              })
          .toList(),
      'edges': edges
          .map((e) => {
                'a': serializeData == null ? e.a.data : serializeData(e.a.data),
                'b': serializeData == null ? e.b.data : serializeData(e.b.data),
              })
          .toList(),
    });
  }
}
