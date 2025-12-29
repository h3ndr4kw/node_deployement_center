import 'package:flutter/services.dart';

Future<String> loadNodesConfigImpl() async {
  return rootBundle.loadString('data/settings/nodes.txt');
}
