import 'dart:convert';
import 'dart:math';

import 'package:vector_math/vector_math.dart';

class Node<T> {
  final T data;
  double mass = 1.0;
  Vector2 position = (Vector2.random() - Vector2(0.5, 0.5)) * 200;
  Vector2 force = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isFixed = false;

  Node(this.data);

  /// Coulomb's law calculates the repulsive force
  Vector2 calculateRepulsionForce(Node other, {required double k}) {
    final distance = position.distanceTo(other.position);
    final direction = (position - other.position).normalized();
    return direction * k * k / distance;
  }

  void applyForce(Vector2 force) {
    this.force += force;
  }

  /// scaling: displacement scaling factor 0-1
  /// return: whether it is in motion
  /// Within a time step, calculate the displacement of the node based on mechanics,
  /// also need to consider whether the current node is stationary,
  /// then consider the static friction, consider the dynamic friction
  bool updatePosition({
    required double scaling,
    required double minVelocity,
    required double maxStaticFriction,
  }) {
    if (isFixed) {
      force = Vector2.zero();
      velocity = Vector2.zero();
      return false;
    }
    if (velocity.length < minVelocity) {
      // static state
      if (force.length < maxStaticFriction) {
        // If the force is too small in the static state, no calculation is required
        velocity = Vector2.zero();
        force = Vector2.zero();
        return false;
      }
    }

    // dynamic state
    final friction = -velocity.normalized() * maxStaticFriction;
    force += friction;
    velocity += force / mass;
    position += velocity * scaling;
    force = Vector2.zero();
    return true;
  }

  Edge connect(Node other) {
    return Edge(this, other);
  }

  @override
  String toString() {
    return 'Node{data: $data, position: $position, force: ${force.length}, velocity: ${velocity.length}}';
  }

  @override
  bool operator ==(Object other) {
    if (other is Node) {
      return data == other.data;
    }
    return false;
  }

  @override
  int get hashCode => data.hashCode;

  void static() {
    isFixed = true;
    // mass = double.infinity;
  }
  void unStatic() {
    isFixed = false;
    // mass = 1.0;
  }
}

class Edge {
  final Node a;
  final Node b;

  Edge(this.a, this.b);

  double get distance => a.position.distanceTo(b.position);

  double get angle {
    final actualAngle = (a.position - b.position).angleToSigned(Vector2(0, -1));
    if (actualAngle >= 0 && actualAngle <= pi) {
      return actualAngle - pi / 2;
    } else {
      return actualAngle + pi / 2;
    }
  }

  /// Hooke's law calculates the elastic force
  double calculateAttractionForce({required double k, required double length}) {
    final distance = this.distance;
    final deformation = distance - length;
    return k * deformation;
  }

  /// Calculate the elastic force direction of node A
  Vector2 calculateAttractionForceDirectionA() {
    return (b.position - a.position).normalized();
  }

  /// Calculate the elastic force direction of node B
  Vector2 calculateAttractionForceDirectionB() {
    return (a.position - b.position).normalized();
  }

  @override
  String toString() {
    return "Edge{a: ${a.data}, b: ${b.data}, distance: $distance, angle: $angle}";
  }

  @override
  bool operator ==(Object other) {
    if (other is Edge) {
      return (a == other.a && b == other.b) || (a == other.b && b == other.a);
    }
    return false;
  }

  @override
  int get hashCode => a.hashCode ^ b.hashCode;
}

class GraphConfig {
  /// Max static friction >0
  final double maxStaticFriction;

  /// Force scaling >0
  final double scaling;

  /// Elasticity >0
  final double elasticity;

  /// Repulsion >0
  final double repulsion;

  /// Repulsion range >0
  final double repulsionRange;

  /// Min velocity >0
  final double minVelocity;

  /// Spring length >0
  final double length = 50.0;

  const GraphConfig({
    this.maxStaticFriction = 20.0,
    this.scaling = 0.01,
    this.elasticity = 1.0,
    this.repulsion = 30.0,
    this.repulsionRange = 150.0,
    this.minVelocity = 5,
  });
}

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

  ForceDirectedGraph.fromJson(String json,
      {this.config = const GraphConfig()}) {
    final data = jsonDecode(json);
    final nodeMap = <T, Node<T>>{};
    for (final nodeData in data['nodes']) {
      final node = Node(nodeData['data'] as T);
      node.position =
          Vector2(nodeData['position']['x'], nodeData['position']['y']);
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
