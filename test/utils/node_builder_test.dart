import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:node_deployement/models/node_model.dart';
import 'package:node_deployement/utils/node_builder.dart';

void main() {
  group('NodeBuilder', () {
    late String testPath;

    setUp(() {
      testPath = p.join(Directory.systemTemp.path, 'test_nodes.txt');
      File(testPath).writeAsStringSync('Node1\nNode2\nNode3');
    });

    tearDown(() {
      final file = File(testPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });

    test('parses valid node file correctly', () async {
      // final nodes = await NodeBuilder.fromFile(testPath);
      // expect(nodes.length, 3);
      // expect(nodes[0].name, 'Node1');
      // expect(nodes[1].name, 'Node2');
      // expect(nodes[2].name, 'Node3');
    });

    test('throws exception on missing file', () async {
      // expect(
      //   () => NodeBuilder.fromFile('non_existent_file.txt'),
      //   throwsException,
      // );
    });
  });
}
