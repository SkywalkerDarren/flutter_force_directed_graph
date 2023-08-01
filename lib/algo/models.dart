import 'dart:math';

import 'package:vector_math/vector_math.dart';

// 最大静摩擦力
const kMaxStaticFriction = 10.0;
// 力缩放系数 0-1
const kScaling = 0.01;
// 弹力系数 >0
const kElasticity = 0.5;
// 斥力系数 >0
const kRepulsion = 15.0;
// 最低速度 >0
const kMinVelocity = 5;

class Node<T> {
  final T data;
  final double mass = 1.0;
  Vector2 position = (Vector2.random() - Vector2(0.5, 0.5)) * 200;
  Vector2 force = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isFixed = false;

  Node(this.data);

  // 库仑定律计算排斥力
  Vector2 calculateRepulsionForce(Node other, {double k = kRepulsion}) {
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
  bool updatePosition({double scaling = kScaling}) {
    if (isFixed) {
      force = Vector2.zero();
      velocity = Vector2.zero();
      return false;
    }
    if (velocity.length < kMinVelocity) {
      // 静止状态
      if (force.length < kMaxStaticFriction) {
        // 静止状态下力度太小，不需要计算
        velocity = Vector2.zero();
        force = Vector2.zero();
        return false;
      }
    }

    // 运动状态
    final friction = -velocity.normalized() * kMaxStaticFriction;
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
  double calculateAttractionForce({double k = kElasticity}) {
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

class ForceDirectedGraph<T> {
  final List<Node<T>> nodes = [];
  final List<Edge> edges = [];

  ForceDirectedGraph();

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
        final repulsionForce = node.calculateRepulsionForce(other);
        node.applyForce(repulsionForce);
      }
    }
    for (final edge in edges) {
      final attractionForce = edge.calculateAttractionForce();
      final attractionForceDirectionA = edge.calculateAttractionForceDirectionA();
      final fa = attractionForceDirectionA * attractionForce;
      edge.a.applyForce(fa);
      edge.b.applyForce(-fa);
    }
    bool positionUpdated = false;
    for (final node in nodes) {
      positionUpdated |= node.updatePosition();
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
