```markdown
# Flutter Force Directed Graph

Flutter Force Directed Graph is a Flutter package that helps you create a force directed graph visualization in your Flutter applications.

## Features

- Create a force directed graph with customizable nodes and edges.
- Add, remove or update nodes and edges dynamically.
- Use the provided `ForceDirectedGraphWidget` for easy integration into your app.
- Built-in gesture detection for nodes and edges.
- Comes with a `ForceDirectedGraphController` for easy management of the graph’s state.

## Getting Started

### Installation

Add the following in your `pubspec.yaml` file under `dependencies`:

```yaml
dependencies:
  flutter_force_directed_graph: <latest_version>
```

Then install it by running `flutter pub get` in your terminal.

## Usage

Here’s a basic example on how to use the `ForceDirectedGraphWidget` and `ForceDirectedGraphController`.

```dart
import 'package:flutter_force_directed_graph/force_directed_graph_controller.dart';
import 'package:flutter_force_directed_graph/force_directed_graph_widget.dart';

ForceDirectedGraphController<int> controller = ForceDirectedGraphController();

final fdgWidget = ForceDirectedGraphWidget(
  controller: controller,
  nodesBuilder: (context, data) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      color: Colors.red,
      child: Text('$data'),
    );
  },
  edgesBuilder: (context, a, b) {
    return Container(
      width: 80,
      height: 16,
      color: Colors.blue,
      alignment: Alignment.center,
      child: Text('$a <-> $b'),
    );
  },
);
```

For a more detailed example, please view the [example directory](https://github.com/SkywalkerDarren/flutter_force_directed_graph/tree/master/example) in this repository.

## Additional Information

We welcome contributions! If you find a bug or want a feature that isn't yet implemented, feel free to open an issue. If you want to contribute code, feel free to open a PR.

If you have any questions or need further guidance, please open an issue and we'll be glad to help out.
```

Please replace `url-to-demo.gif` with the actual URL of your demo GIF and `your-github-username` with your actual GitHub username.