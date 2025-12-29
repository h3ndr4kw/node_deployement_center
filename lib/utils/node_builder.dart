import '../models/node_model.dart';

class NodeBuilder {
  final String _content;
  final List<String> _nodeName = [];
  final List<Node> _nodes = [];
  final Map<String, Node> byNodeName = {};
  final Map<NodeArea, List<Node>> byArea = {};

  NodeBuilder({required String content}) : _content = content {
    _build();
  }

  List<String> getNodeName() {
    return _nodeName;
  }

  List<Node> getNodes() {
    return _nodes;
  }

  Node? getNodeByName(String name) {
    return byNodeName[name];
  }

  List<Node>? getNodesByArea(NodeArea area) {
    return byArea[area];
  }

  void _build() {
    final lines = _content.split('\n');
    // final nodes = <Node>[];

    for (var line in lines) {
      if (line.trim().isEmpty) continue;

      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 4) continue;

      final name = parts[0];
      final ip = parts[1];
      final areaStr = parts[2].toLowerCase();
      final typeStr = parts[3].toLowerCase();
      _nodeName.add(name);

      final area = NodeArea.values.firstWhere(
        (e) => e.name == areaStr,
        orElse: () => throw Exception('Unknown area: $areaStr'),
      );

      final type = NodeType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => throw Exception('Unknown type: $typeStr'),
      );

      byNodeName[name] = Node(
        id: name,
        name: name,
        ip: ip,
        area: area,
        type: type,
        isOnline: false, // Default value
      );

      byArea
          .putIfAbsent(area, () => [])
          .add(
            Node(
              id: name,
              name: name,
              ip: ip,
              area: area,
              type: type,
              isOnline: false, // Default value
            ),
          );

      _nodes.add(
        Node(
          id: name,
          name: name,
          ip: ip,
          area: area,
          type: type,
          isOnline: false, // Default value
        ),
      );
    }
  }
}

// void main()  {
//   var nodeBuilder = NodeBuilder(path: 'data/settings/nodes.txt');
//   for (var node in nodeBuilder.getNodeName()) {
//     print(node);
//   }
// }
