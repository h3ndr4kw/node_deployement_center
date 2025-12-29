import 'dart:io';
import 'package:path/path.dart' as p;

Future<String> loadNodesConfigImpl() async {
  var fullPath = p.join(
    Directory.current.path,
    'data',
    'settings',
    'nodes.txt',
  );
  return File(fullPath).readAsString();
}
