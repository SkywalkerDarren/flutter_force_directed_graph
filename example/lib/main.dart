// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';

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
  late final ForceDirectedGraphController<int> _controller =
      ForceDirectedGraphController(
    graph: ForceDirectedGraph.generateNTree(
      nodeCount: 50,
      maxDepth: 3,
      n: 4,
      generator: () {
        _nodeCount++;
        return _nodeCount;
      },
    ),
  );
  int _nodeCount = 0;
  final Set<int> _nodes = {};
  final Set<String> _edges = {};
  double _scale = 1.0;
  int _locatedTo = 0;
  int? _draggingData;
  String? _json;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _controller.needUpdate();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          _buildMenu(context),
          Expanded(
            child: ForceDirectedGraphWidget(
              controller: _controller,
              onDraggingStart: (data) {
                setState(() {
                  _draggingData = data;
                });
              },
              onDraggingEnd: (data) {
                setState(() {
                  _draggingData = null;
                });
              },
              onDraggingUpdate: (data) {},
              nodesBuilder: (context, data) {
                final Color color;
                if (_draggingData == data) {
                  color = Colors.yellow;
                } else if (_nodes.contains(data)) {
                  color = Colors.green;
                } else {
                  color = Colors.red;
                }

                return GestureDetector(
                  onTap: () {
                    print("onTap $data");
                    setState(() {
                      if (_nodes.contains(data)) {
                        _nodes.remove(data);
                      } else {
                        _nodes.add(data);
                      }
                    });
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('$data'),
                  ),
                );
              },
              edgesBuilder: (context, a, b, distance) {
                final Color color;
                if (_draggingData == a || _draggingData == b) {
                  color = Colors.yellow;
                } else if (_edges.contains("$a <-> $b")) {
                  color = Colors.green;
                } else {
                  color = Colors.blue;
                }
                return GestureDetector(
                  onTap: () {
                    final edge = "$a <-> $b";
                    setState(() {
                      if (_edges.contains(edge)) {
                        _edges.remove(edge);
                      } else {
                        _edges.add(edge);
                      }
                      print("onTap $a <-$distance-> $b");
                    });
                  },
                  child: Container(
                    width: distance,
                    height: 16,
                    color: color,
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

  Widget _buildMenu(BuildContext context) {
    return Wrap(
      children: [
        ElevatedButton(
          onPressed: () {
            _nodeCount++;
            _controller.addNode(_nodeCount);
            _nodes.clear();
            _edges.clear();
          },
          child: const Text('add node'),
        ),
        ElevatedButton(
          onPressed: () {
            for (final node in _nodes) {
              _controller.deleteNodeByData(node);
            }
            _nodes.clear();
            _edges.clear();
          },
          child: const Text('del node'),
        ),
        const SizedBox(width: 4),
        ElevatedButton(
          onPressed: () {
            if (_nodes.length == 2) {
              final a = _nodes.first;
              final b = _nodes.last;
              _controller.addEdgeByData(a, b);
            }
            _nodes.clear();
            _edges.clear();
          },
          child: const Text('add edge'),
        ),
        ElevatedButton(
          onPressed: () {
            for (final edge in _edges) {
              final a = int.parse(edge.split(' <-> ').first);
              final b = int.parse(edge.split(' <-> ').last);
              _controller.deleteEdgeByData(a, b);
            }
            _nodes.clear();
            _edges.clear();
          },
          child: const Text('del edge'),
        ),
        ElevatedButton(
          onPressed: () {
            _controller.needUpdate();
          },
          child: const Text('update'),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await _showTreeDialogWithInput(context);
            if (result == null) return;
            setState(() {
              _clearData();
              _controller.graph = ForceDirectedGraph.generateNTree(
                nodeCount: result['nodeCount'] as int,
                maxDepth: result['maxDepth'] as int,
                n: result['n'] as int,
                generator: () {
                  _nodeCount++;
                  return _nodeCount;
                },
              );
            });
          },
          child: const Text('new tree'),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await _showNodeDialogWithInput(context);
            if (result == null) return;
            setState(() {
              _clearData();
              _controller.graph = ForceDirectedGraph.generateNNodes(
                nodeCount: result['nodeCount'] as int,
                generator: () {
                  _nodeCount++;
                  return _nodeCount;
                },
              );
            });
          },
          child: const Text('new nodes'),
        ),
        ElevatedButton(
          onPressed: () {
            _controller.center();
          },
          child: const Text('center'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _locatedTo++;
              _locatedTo = _locatedTo % _controller.graph.nodes.length;
              final data = _controller.graph.nodes[_locatedTo].data;
              _controller.locateTo(data);
            });
          },
          child: Text('locateTo ${_controller.graph.nodes[_locatedTo].data}'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              if (_json != null) {
                _controller.graph = ForceDirectedGraph.fromJson(_json!);
                _clearData();
                _json = null;
              } else {
                _json = _controller.toJson();
              }
            });
          },
          child: Text(_json == null ? 'save' : 'load'),
        ),
        Slider(
          value: _scale,
          min: 0.1,
          max: 2.0,
          onChanged: (value) {
            setState(() {
              _scale = value;
              _controller.scale = value;
            });
          },
        )
      ],
    );
  }

  void _clearData() {
    _nodes.clear();
    _edges.clear();
    _nodeCount = 0;
    _locatedTo = 0;
  }

  Future<Map<String, int>?> _showTreeDialogWithInput(BuildContext context) {
    final TextEditingController nodeCountController =
        TextEditingController(text: '50');
    final TextEditingController maxDepthController =
        TextEditingController(text: '3');
    final TextEditingController nController = TextEditingController(text: '3');

    return showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Values'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nodeCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Node Count"),
              ),
              TextField(
                controller: maxDepthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Max Depth"),
              ),
              TextField(
                  controller: nController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Max Children"))
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                try {
                  final result = {
                    'nodeCount': int.parse(nodeCountController.text),
                    'maxDepth': int.parse(maxDepthController.text),
                    'n': int.parse(nController.text),
                  };
                  Navigator.of(context).pop(result);
                } catch (e) {
                  Navigator.of(context).pop(null);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>?> _showNodeDialogWithInput(BuildContext context) {
    final TextEditingController nodeCountController =
        TextEditingController(text: '50');

    return showDialog<Map<String, int>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Values'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nodeCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Node Count"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text('Submit'),
              onPressed: () {
                try {
                  final result = {
                    'nodeCount': int.parse(nodeCountController.text),
                  };
                  Navigator.of(context).pop(result);
                } catch (e) {
                  Navigator.of(context).pop(null);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
