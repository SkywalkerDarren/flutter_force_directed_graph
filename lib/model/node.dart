import 'package:vector_math/vector_math.dart';

import 'edge.dart';

/// A class representing a node in a graph, holding a reference to arbitrary
/// data of type [T].
///
/// It also holds information needed to play its role in the context of a
/// force directed graph, like [position] in the 2D space as a [Vector2], the
/// [mass] as a [double].
///
/// Internally if also holds the [_force] acting on the [Node], the current
/// [_velocity] and whether the [Node] is fixed in place.
///
/// [Node] instances are referenced by [Edge] instances to implement the concept
/// of a graph.
///
/// Furthermore [Node] instances are referenced by [KDNode] instances to allow
/// their information to be used in the [KDTree] implementation.
class Node<T> {
  final T data;
  double mass = 1.0;
  Vector2 position;
  Vector2 _force = Vector2.zero();
  Vector2 _velocity = Vector2.zero();
  bool _isFixed = false;

  /// Construct a [Node] instance from a given [data] of type [T].
  ///
  /// Optionally a [position] can be provided, otherwise a random position is
  /// generated.
  Node(this.data, [Vector2? position])
      : position = position ?? (Vector2.random() - Vector2(0.5, 0.5)) * 200;

  /// Calculate the repulsive force following Coulomb's law.
  ///
  /// The force is calculated based on the distance between the current [Node] and
  /// the [other] [Node], and the required [double] value [k].
  Vector2 calculateRepulsionForce(Node other, {required double k}) {
    final distance = position.distanceTo(other.position);
    final direction = (position - other.position).normalized();
    return direction * k * k / distance;
  }

  /// Adds a force to the current force acting on the [Node].
  void applyForce(Vector2 force) {
    _force += force;
  }

  /// Calculates the displacement within a time step and by that the new
  /// position of the [Node] based on mechanics using the given parameters.
  ///
  /// It takes the displacement [scaling] as factor of 0 to 1, the
  /// [minimumVelocity] as a [double], the [maxStaticFriction] as a [double], as well
  /// as the [damping] as a [double].
  ///
  /// It returns: whether the [Node] is considered currently in motion.
  ///
  /// If fixed, the [Node] is not moving and the force and velocity on it is zero.
  /// When moving slower than [minVelocity] and the force is smaller than the
  /// [maxStaticFriction], the [Node] is considered in a static state and no
  /// calculation is required.
  bool updatePosition({
    required double scaling,
    required double minVelocity,
    required double maxStaticFriction,
    required double damping,
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
    _velocity *= damping;
    position += _velocity * scaling;
    _force = Vector2.zero();
    return true;
  }

  /// Connects the current [Node] with the [other] [Node] by creating
  /// (and returning) an [Edge]
  Edge connect(Node other) {
    return Edge(this, other);
  }

  /// Returns a string representation of the [Node] instance, including the
  /// [data], the [position], the [_force] and the [_velocity].
  @override
  String toString() {
    return 'Node{data: $data, position: $position, force: ${_force.length}, velocity: ${_velocity.length}}';
  }

  /// Implements equality based on if the [other] is a [Node] and the [data] is
  /// equal.
  // TODO: Discuss why not simply leveraging the type system to only allow
  // [Node] instances as [other]?
  @override
  bool operator ==(Object other) {
    if (other is Node) {
      return data == other.data;
    }
    return false;
  }

  @override
  int get hashCode => data.hashCode;

  // TODO: Naming suggestion: `makeStatic()`
  void static() {
    _isFixed = true;
  }

  // TODO: Naming suggestion: `makeDynamic()`
  void unStatic() {
    _isFixed = false;
  }
}
