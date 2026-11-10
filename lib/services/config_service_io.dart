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

Future<String> loadByuNodesConfigImpl() async {
  var fullPath = p.join(
    Directory.current.path,
    'data',
    'settings',
    'byu_nodes.txt',
  );
  return File(fullPath).readAsString();
}
