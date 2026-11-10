import 'package:flutter/services.dart';

Future<String> loadNodesConfigImpl() async {
  return rootBundle.loadString('data/settings/nodes.txt');
}

Future<String> loadByuNodesConfigImpl() async {
  return rootBundle.loadString('data/settings/byu_nodes.txt');
}
