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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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

  @override
  void initState() {
    super.initState();
    final a = nodeCount;
    nodeCount++;
    final b = nodeCount;
    nodeCount++;
    controller.addEdgeByData(a, b);
    // controller.addEdgeByData('a', 'c');
    // controller.addEdgeByData('a', 'd');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  controller.updateToFinish();
                },
                child: Text('animate'),
              ),
              ElevatedButton(
                onPressed: () {
                  final a = nodeCount;
                  nodeCount++;
                  final b = nodeCount;
                  nodeCount++;
                  controller.addEdgeByData(a, b);
                },
                child: Text('add edge'),
              ),
              ElevatedButton(
                onPressed: () {
                  final data = nodeCount;
                  nodeCount++;
                  controller.addNode(data);
                },
                child: Text('add node'),
              ),
              ElevatedButton(
                onPressed: () {
                  nodeCount--;
                  controller.deleteNodeByData(nodeCount);
                },
                child: Text('delete node'),
              ),
            ],
          ),
          Expanded(
            child: ForceDirectedGraphWidget(
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
            ),
          ),
        ],
      ),
    );
  }
}
