
class Node {
  final String id;
  final String name;
  final String ip;
  final bool isOnline;
  final bool isSelected;

  const Node({
    required this.id,
    required this.name,
    required this.ip,
    required this.isOnline,
    this.isSelected = false,
  });

  Node copyWith({
    String? id,
    String? name,
    String? ip,
    bool? isOnline,
    bool? isSelected,
  }) {
    return Node(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      isOnline: isOnline ?? this.isOnline,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
