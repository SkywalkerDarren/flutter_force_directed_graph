import 'dart:math';

import 'package:vector_math/vector_math.dart';

// 摩擦力系数 0-1
const kFriction = 0.8;
// 力缩放系数 0-1
const kDamping = 0.1;
// 弹力系数 >0
const kElasticity = 1.0;
// 斥力系数 >0
const kRepulsion = 15.0;
// 最低速度 >0
const kMinVelocity = 2;
// 最低力度 >0
const kMinForce = 3;

class Node<T> {
  final T data;
  Vector2 position = (Vector2.random() - Vector2(0.5, 0.5)) * 200;
  Vector2 force = Vector2.zero();
  Vector2 velocity = Vector2.zero();

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

  bool updatePosition({double damping = kDamping}) {
    final friction = -velocity.normalized() * kFriction; // 计算摩擦力
    velocity += force * damping + friction; // 更新速度
    if (velocity.length < kMinVelocity && force.length < kMinForce) {
      // print("final velocity: ${velocity.length}");
      velocity = Vector2.zero();
      force = Vector2.zero();
      return false;
    }
    position += velocity; // 更新位置

    // final angle = velocity.angleTo(force);
    // print("angle: $angle");

    force = Vector2.zero(); // 清空力
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
    // print("actualAngle: $actualAngle");
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
        print("break at $i");
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
    print("this: $this");
    for (final node in nodes) {
      positionUpdated |= node.updatePosition();
      // print(node);
    }
    return positionUpdated;
  }

  @override
  String toString() {
    return "\nnodes:\n$nodes,\nedges:\n$edges";
  }
}
