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
  final double length;

  /// Damping 0-1
  final double damping;

  const GraphConfig({
    this.maxStaticFriction = 20.0,
    this.scaling = 0.01,
    this.elasticity = 1.0,
    this.repulsion = 60.0,
    this.repulsionRange = 150.0,
    this.minVelocity = 10,
    this.length = 50.0,
    this.damping = 0.93,
  });
}
