import 'package:vector_math/vector_math.dart';

import 'edge.dart';

class Node<T> {
  final T data;
  double mass = 1.0;
  Vector2 position = (Vector2.random() - Vector2(0.5, 0.5)) * 200;
  Vector2 _force = Vector2.zero();
  Vector2 _velocity = Vector2.zero();
  bool _isFixed = false;

  Node(this.data);

  /// Coulomb's law calculates the repulsive force
  Vector2 calculateRepulsionForce(Node other, {required double k}) {
    final distance = position.distanceTo(other.position);
    final direction = (position - other.position).normalized();
    return direction * k * k / distance;
  }

  void applyForce(Vector2 force) {
    _force += force;
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
    if (_isFixed) {
      _force = Vector2.zero();
      _velocity = Vector2.zero();
      return false;
    }
    if (_velocity.length < minVelocity) {
      // static state
      if (_force.length < maxStaticFriction) {
        // If the force is too small in the static state, no calculation is required
        _velocity = Vector2.zero();
        _force = Vector2.zero();
        return false;
      }
    }

    // dynamic state
    final friction = -_velocity.normalized() * maxStaticFriction;
    _force += friction;
    _velocity += _force / mass;
    position += _velocity * scaling;
    _force = Vector2.zero();
    return true;
  }

  Edge connect(Node other) {
    return Edge(this, other);
  }

  @override
  String toString() {
    return 'Node{data: $data, position: $position, force: ${_force.length}, velocity: ${_velocity.length}}';
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
    _isFixed = true;
  }

  void unStatic() {
    _isFixed = false;
  }
}
