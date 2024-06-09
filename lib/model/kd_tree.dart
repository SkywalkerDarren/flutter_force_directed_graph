import 'package:vector_math/vector_math.dart';

import 'node.dart';

// A Class implementing the concept of [KDNode], a node within a [KDTree], and
// holding references to the left and right child nodes ([KDNode] instances), as
// well as the dimension of the split. Furthermore, it holds a reference to the
// [Node] it represents in the graph.
class KDNode {
  Node node;
  KDNode? left;
  KDNode? right;
  int dim = 0;

  Vector2 get point => node.position;

  KDNode(this.node, {this.left, this.right});
}

/// A class implementing the concept of a kd-tree. A kd-tree is a binary tree that
/// splits the space in k dimensions. It is used to store points in k-dimensional
/// space and efficiently answer nearest neighbor queries.
///
/// Nodes in a [KDTree] are implemented by [KDNode].
///
/// References:
/// [Bio informatics lecture notes from CMU](https://www.cs.cmu.edu/~ckingsf/bioinfo-lectures/kdtrees.pdf)
/// [English Wikipedia article about kd-trees](https://en.wikipedia.org/wiki/K-d_tree)
/// [CS168: The Modern Algorithmic Toolbox Lecture #3: Similarity Metrics and kd-Trees](https://web.stanford.edu/class/cs168/l/l3.pdf)
class KDTree {
  static const dim = 2;
  KDNode? _root;
  final bool _useVariance;

  /// Construct a [KDTree] from a list of [Node] instances.
  ///
  /// It takes the forementioned list of nodes and an optional parameter [useVariance].
  /// The [Node] instances are mapped to [KDNode] instances for use in the kd-tree
  /// algorithms.
  ///
  /// For more information, also about the concept of `variance` please refere
  /// to the documents linked above.
  KDTree.fromNode(List<Node> nodes, [bool useVariance = true])
      : _useVariance = useVariance {
    _root = _buildTree(nodes.map((e) => KDNode(e)).toList(), 0);
  }

  int _varianceDimension(List<KDNode> nodes) {
    int maxDim = 0;
    double maxVariance = 0;
    for (int i = 0; i < dim; i++) {
      final variance = _variance(nodes, i);
      if (variance > maxVariance) {
        maxVariance = variance;
        maxDim = i;
      }
    }
    return maxDim;
  }

  double _variance(List<KDNode> nodes, int dim) {
    double sum = 0;
    double sum2 = 0;
    for (final point in nodes.map((e) => e.point)) {
      sum += point[dim];
      sum2 += point[dim] * point[dim];
    }

    double variance =
        sum2 / nodes.length - (sum / nodes.length) * (sum / nodes.length);
    return variance;
  }

  KDNode? _buildTree(List<KDNode> nodes, int currentAxis) {
    if (nodes.isEmpty) {
      return null;
    }
    final axis = _useVariance ? _varianceDimension(nodes) : (currentAxis % dim);
    nodes.sort((a, b) => a.point[axis].compareTo(b.point[axis]));
    final median = nodes.length ~/ 2;
    final node = nodes[median]..dim = axis;
    if (nodes.length > 1) {
      node.left = _buildTree(nodes.sublist(0, median), axis + 1);
      node.right = _buildTree(nodes.sublist(median + 1), axis + 1);
    }
    return node;
  }

  List<Node> findNeighbors(Vector2 target, double radius) {
    List<Node> results = [];
    _searchNeighbors(_root, target, radius, results);
    return results;
  }

  double _distance(Vector2 point1, Vector2 point2) {
    return (point1 - point2).length;
  }

  void _searchNeighbors(
      KDNode? node, Vector2 target, double radius, List<Node> results,
      [int depth = 0]) {
    if (node == null) {
      return;
    }

    double d = _distance(node.point, target);

    if (d <= radius) {
      results.add(node.node);
    }

    int axis = node.dim;
    double diff = target[axis] - node.point[axis];

    if (diff <= 0.0) {
      // target point is on the left of split plane
      _searchNeighbors(node.left, target, radius, results, depth + 1);

      if (diff.abs() <= radius) {
        // check if we need to go to the right side
        _searchNeighbors(node.right, target, radius, results, depth + 1);
      }
    } else {
      // target point is on the right of split plane
      _searchNeighbors(node.right, target, radius, results, depth + 1);

      if (diff.abs() <= radius) {
        // check if we need to go to the left side
        _searchNeighbors(node.left, target, radius, results, depth + 1);
      }
    }
  }
}
