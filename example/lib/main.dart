import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/force_directed_graph_controller.dart';
import 'package:flutter_force_directed_graph/force_directed_graph_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Force Directed Graph Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Force Directed Graph Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ForceDirectedGraphController<int> controller = ForceDirectedGraphController();
  int nodeCount = 0;
  Set<int> nodes = {};
  Set<String> edges = {};

  @override
  void initState() {
    super.initState();
    final a = nodeCount;
    nodeCount++;
    final b = nodeCount;
    nodeCount++;
    controller.addEdgeByData(a, b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Wrap(
            children: [
              ElevatedButton(
                onPressed: () {
                  final a = nodeCount;
                  nodeCount++;
                  controller.addNode(a);
                  nodes.clear();
                  edges.clear();
                },
                child: const Text('add node'),
              ),
              ElevatedButton(
                onPressed: () {
                  for (final node in nodes) {
                    controller.deleteNodeByData(node);
                  }
                  nodes.clear();
                  edges.clear();
                },
                child: const Text('del node'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nodes.length == 2) {
                    final a = nodes.first;
                    final b = nodes.last;
                    controller.addEdgeByData(a, b);
                  }
                  nodes.clear();
                  edges.clear();
                },
                child: const Text('add edge'),
              ),
              ElevatedButton(
                onPressed: () {
                  for (final edge in edges) {
                    final a = int.parse(edge.split(' <-> ').first);
                    final b = int.parse(edge.split(' <-> ').last);
                    controller.deleteEdgeByData(a, b);
                  }
                },
                child: const Text('del edge'),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.needUpdate();
                },
                child: const Text('update'),
              ),
            ],
          ),
          Expanded(
            child: ForceDirectedGraphWidget(
              controller: controller,
              nodesBuilder: (context, data) {
                return GestureDetector(
                  onTap: () {
                    print("onTap $data");
                    setState(() {
                      if (nodes.contains(data)) {
                        nodes.remove(data);
                      } else {
                        nodes.add(data);
                      }
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    color: nodes.contains(data) ? Colors.green : Colors.red,
                    child: Text('$data'),
                  ),
                );
              },
              edgesBuilder: (context, a, b) {
                return GestureDetector(
                  onTap: () {
                    final edge = "$a <-> $b";
                    setState(() {
                      if (edges.contains(edge)) {
                        edges.remove(edge);
                      } else {
                        edges.add(edge);
                      }
                      print("onTap $a <-> $b");
                    });
                  },
                  child: Container(
                    width: 80,
                    height: 16,
                    color: edges.contains("$a <-> $b") ? Colors.green : Colors.blue,
                    alignment: Alignment.center,
                    child: Text('$a <-> $b'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
