enum NodeArea {
  sumbagut,
  sumbagteng,
  sumbagsel,
  jabo,
  jabar,
  kalimantan,
  sulawesi,
  malirja,
  testbed,
}

enum NodeType { standalone, gwc, gwu, pcc, pcg }

class Node {
  final String id;
  final String name;
  final String ip;
  final NodeArea area;
  final NodeType type;
  final bool isOnline;
  final bool isSelected;

  const Node({
    required this.id,
    required this.name,
    required this.ip,
    required this.area,
    required this.type,
    required this.isOnline,
    this.isSelected = false,
  });

  Node copyWith({
    String? id,
    String? name,
    String? ip,
    NodeArea? area,
    NodeType? type,
    bool? isOnline,
    bool? isSelected,
  }) {
    return Node(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      area: area ?? this.area,
      type: type ?? this.type,
      isOnline: isOnline ?? this.isOnline,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
