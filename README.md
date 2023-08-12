# Flutter Force Directed Graph

Flutter Force Directed Graph is a Flutter package that helps you create a force directed graph
visualization in your Flutter applications.

[![](https://img.shields.io/pub/v/flutter_force_directed_graph.svg)](https://pub.dartlang.org/packages/flutter_force_directed_graph)
[![](https://github.com/SkywalkerDarren/flutter_force_directed_graph/actions/workflows/publish.yaml/badge.svg)](https://pub.dartlang.org/packages/flutter_force_directed_graph)

## Features

- Create a force directed graph with customizable nodes and edges.
- Add, remove or update nodes and edges dynamically.
- Use the provided `ForceDirectedGraphWidget` for easy integration into your app.
- Built-in gesture detection for nodes, edges and graph panning and zooming.
- Comes with a `ForceDirectedGraphController` for easy management of the graph’s state.

## Demo

![example.gif](https://raw.githubusercontent.com/SkywalkerDarren/flutter_force_directed_graph/master/doc/example.gif)

## Getting Started

### Installation

Add the following in your `pubspec.yaml` file under `dependencies`:

```yaml
dependencies:
  flutter_force_directed_graph: ^1.0.3
```

Then install it by running `flutter pub get` in your terminal.

## Usage

Here’s a basic example on how to use the `ForceDirectedGraphWidget`
and `ForceDirectedGraphController`.

```dart
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';

ForceDirectedGraphController<int> controller = ForceDirectedGraphController();

final fdgWidget = ForceDirectedGraphWidget(
  controller: controller,
  onDraggingStart: (data) {
    print('Dragging started on node $data');
  },
  onDraggingEnd: (data) {
    print('Dragging ended on node $data');
  },
  onDraggingUpdate: (data) {
    print('Dragging updated on node $data');
  },
  nodesBuilder: (context, data) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      color: Colors.red,
      child: Text('$data'),
    );
  },
  edgesBuilder: (context, a, b, distance) {
    return Container(
      width: distance,
      height: 16,
      color: Colors.blue,
      alignment: Alignment.center,
      child: Text('$a <-> $b'),
    );
  },
);
```

For a more detailed example, please view
the [example directory](https://github.com/SkywalkerDarren/flutter_force_directed_graph/tree/master/example)
in this repository. This example includes additional features and gesture support.

# Contributing

We welcome contributions! If you find a bug or want a feature that isn't yet implemented, feel free
to open an issue. If you want to contribute code, feel free to open a PR.

If you have any questions or need further guidance, please open an issue and we'll be glad to help
out.

# License

This project is licensed under the BSD 3-Clause License - see the LICENSE file for details.