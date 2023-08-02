import 'dart:math';

import 'package:vector_math/vector_math.dart';

class Node<T> {
  final T data;
  final double mass = 1.0;
  Vector2 position = (Vector2.random() - Vector2(0.5, 0.5)) * 200;
  Vector2 force = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isFixed = false;

  Node(this.data);

  // 库仑定律计算排斥力
  Vector2 calculateRepulsionForce(Node other, {required double k}) {
    final distance = position.distanceTo(other.position);
    final direction = (position - other.position).normalized();
    return direction * k * k / distance;
  }

  void applyForce(Vector2 force) {
    this.force += force;
  }

  /// scaling: 位移缩放系数 0-1
  /// return: 是否处于运动状态
  /// 在一个时间步长内，根据力学计算节点的位移，
  /// 还需要考虑当前节点是否静止，然后考虑静摩擦力，考虑动摩擦力
  /// 静止状态下和运动状态下的计算方式应该不同
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
      // 静止状态
      if (force.length < maxStaticFriction) {
        // 静止状态下力度太小，不需要计算
        velocity = Vector2.zero();
        force = Vector2.zero();
        return false;
      }
    }

    // 运动状态
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
}

class Edge {
  final Node a;
  final Node b;
  final double length = 50.0;

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

  // 胡克定律计算引力
  double calculateAttractionForce({required double k}) {
    final distance = this.distance;
    final deformation = distance - length;
    return k * deformation;
  }

  // 计算节点A受到的引力方向
  Vector2 calculateAttractionForceDirectionA() {
    return (b.position - a.position).normalized();
  }

  // 计算节点B受到的引力方向
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
  /// 最大静摩擦力 >0
  final double kMaxStaticFriction;

  /// 力缩放系数 0-1
  final double kScaling;

  /// 弹力系数 >0
  final double kElasticity;

  /// 斥力系数 >0
  final double kRepulsion;

  /// 斥力最大范围 >0
  final double kRepulsionRange;

  /// 最低速度 >0
  final double kMinVelocity;

  const GraphConfig({
    this.kMaxStaticFriction = 20.0,
    this.kScaling = 0.01,
    this.kElasticity = 1.0,
    this.kRepulsion = 30.0,
    this.kRepulsionRange = 150.0,
    this.kMinVelocity = 5,
  });
}

class ForceDirectedGraph<T> {
  final List<Node<T>> nodes = [];
  final List<Edge> edges = [];
  final GraphConfig config;

  ForceDirectedGraph({this.config = const GraphConfig()});

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
        if (node.position.distanceTo(other.position) > config.kRepulsionRange) {
          continue;
        }
        final repulsionForce =
            node.calculateRepulsionForce(other, k: config.kRepulsion);
        node.applyForce(repulsionForce);
      }
    }
    for (final edge in edges) {
      final attractionForce =
          edge.calculateAttractionForce(k: config.kElasticity);
      final attractionForceDirectionA =
          edge.calculateAttractionForceDirectionA();
      final fa = attractionForceDirectionA * attractionForce;
      edge.a.applyForce(fa);
      edge.b.applyForce(-fa);
    }
    bool positionUpdated = false;
    for (final node in nodes) {
      positionUpdated |= node.updatePosition(
        scaling: config.kScaling,
        minVelocity: config.kMinVelocity,
        maxStaticFriction: config.kMaxStaticFriction,
      );
    }
    if (!positionUpdated) {
      for (final node in nodes) {
        node.isFixed = false;
      }
    }
    return positionUpdated;
  }

  @override
  String toString() {
    return "\nnodes:\n$nodes,\nedges:\n$edges";
  }
}
