// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_force_directed_graph/flutter_force_directed_graph.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group("test fdg widget", () {
    testWidgets("test fdg widget", (widgetTester) async {
      int nodeCount = 0;
      final ForceDirectedGraphController<int> controller =
          ForceDirectedGraphController(
        graph: ForceDirectedGraph.generateNTree(
          nodeCount: 3,
          maxDepth: 3,
          n: 3,
          generator: () {
            nodeCount++;
            return nodeCount;
          },
        ),
      )..setOnScaleChange((scale) {
              // print("scale: $scale");
            });
      final fdgw = ForceDirectedGraphWidget(
          controller: controller,
          onDraggingStart: (data) {
            print("start drag: $data");
          },
          onDraggingEnd: (data) {
            print("end drag: $data");
          },
          nodesBuilder: (context, data) {
            return Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
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
          });

      final wrapper = MaterialApp(home: fdgw);
      widgetTester.view.physicalSize = const Size(800, 600);
      await widgetTester.pumpWidget(wrapper);
      final size = widgetTester.getSize(find.byWidget(fdgw));
      print("size: $size");
      controller.needUpdate();
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      print(controller.graph);
      nodeCount++;
      controller.addNode(nodeCount);
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      controller.addEdgeByData(nodeCount, nodeCount - 1);
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      controller.deleteEdgeByData(nodeCount, nodeCount - 1);
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      controller.deleteNodeByData(nodeCount);
      nodeCount--;
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      final saved = controller.toJson();
      controller.graph = ForceDirectedGraph.fromJson(saved);
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      for (int i = 1; i <= nodeCount; i++) {
        controller.locateTo(i);
        await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      }
      controller.center();
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      controller.minScale = 0.1;
      controller.maxScale = 2;
      controller.scale = 2;
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      controller.scale = 1;
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      controller.locateTo(1);
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      final center = widgetTester.getCenter(find.byWidget(fdgw));
      await widgetTester.timedDragFrom(
        center,
        center + const Offset(100, 100),
        const Duration(seconds: 1),
      );
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      nodeCount = 0;
      controller.graph = ForceDirectedGraph.generateNNodes(
        nodeCount: 1,
        generator: () {
          nodeCount++;
          return nodeCount;
        },
      );
      await widgetTester.pumpAndSettle(const Duration(seconds: 5));
      await widgetTester.timedDragFrom(
        Offset.zero,
        const Offset(20, 20),
        const Duration(seconds: 1),
      );
    });

    testWidgets("Change controller", (widgetTester) async {
      final a = ForceDirectedGraphController();

      int i = 0;
      final b = ForceDirectedGraphController(
        graph: ForceDirectedGraph.generateNTree(
          nodeCount: 3,
          maxDepth: 3,
          n: 3,
          generator: () {
            i++;
            return i;
          },
        ),
      );

      i = 0;
      final c = ForceDirectedGraphController(
        graph: ForceDirectedGraph.generateNNodes(
          nodeCount: 3,
          generator: () {
            i++;
            return i;
          },
        ),
      );

      ForceDirectedGraphController controller = a;

      double cachePaintOffset = 10;

      int intrinsicType = 0;

      void Function(void Function())? setter;
      final wrapper = StatefulBuilder(builder: (context, setState) {
        setter = setState;
        Widget child = ForceDirectedGraphWidget(
          cachePaintOffset: cachePaintOffset,
          controller: controller,
          nodesBuilder: (context, data) {
            return Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
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
        switch (intrinsicType) {
          case 1:
            child = Column(
              children: [
                Expanded(child: IntrinsicHeight(child: child)),
              ],
            );
            break;
          case 2:
            child = Row(
              children: [
                Expanded(child: IntrinsicWidth(child: child)),
              ],
            );
            break;
        }
        return MaterialApp(
          home: child,
        );
      });

      await widgetTester.pumpWidget(wrapper);
      await widgetTester.pumpAndSettle();
      setter?.call(() {
        controller = b;
        cachePaintOffset = 20;
      });
      await widgetTester.pumpAndSettle();
      setter?.call(() {
        controller = c;
        cachePaintOffset = 30;
      });
      await widgetTester.pumpAndSettle();
      setter?.call(() {
        intrinsicType = 1;
      });
      await widgetTester.pumpAndSettle();
      setter?.call(() {
        intrinsicType = 2;
      });
      await widgetTester.pumpAndSettle();
    });
  });
}
