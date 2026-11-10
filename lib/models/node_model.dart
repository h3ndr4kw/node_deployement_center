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

enum NodeExecutionStatus {
  ready,
  login,
  checkUser,
  loadScript,
  validate,
  commit,
  done,
  failed,
}

enum ExecutionMethod { standard, broadcast }

enum DeploymentMode { quick, schedule }

enum NodeSource { all, byu, nonByu }

class Node {
  final String id;
  final String name;
  final String ip;
  final NodeArea area;
  final NodeType type;
  final bool isOnline;
  final bool isSelected;
  final NodeExecutionStatus executionStatus;
  final DateTime? executionDate;

  const Node({
    required this.id,
    required this.name,
    required this.ip,
    required this.area,
    required this.type,
    required this.isOnline,
    this.isSelected = false,
    this.executionStatus = NodeExecutionStatus.ready,
    this.executionDate,
  });

  Node copyWith({
    String? id,
    String? name,
    String? ip,
    NodeArea? area,
    NodeType? type,
    bool? isOnline,
    bool? isSelected,
    NodeExecutionStatus? executionStatus,
    DateTime? executionDate,
  }) {
    return Node(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      area: area ?? this.area,
      type: type ?? this.type,
      isOnline: isOnline ?? this.isOnline,
      isSelected: isSelected ?? this.isSelected,
      executionStatus: executionStatus ?? this.executionStatus,
      executionDate: executionDate ?? this.executionDate,
    );
  }
}

class ScheduleEntry {
  final String id;
  final String activityName;
  final String scheduleType; // "onetime" | "recurring"
  final String date;
  final String time;
  final String? repeatMode; // "daily" | "weekly" | "monthly"
  final String? repeatDay;
  final List<String> nodeIds;
  final List<String> commands;
  final String executionMethod;
  final String createdAt;
  final String status; // "waiting" | "running" | "success" | "failed" | "cancelled"

  ScheduleEntry({
    required this.id,
    required this.activityName,
    required this.scheduleType,
    required this.date,
    required this.time,
    this.repeatMode,
    this.repeatDay,
    required this.nodeIds,
    required this.commands,
    required this.executionMethod,
    required this.createdAt,
    required this.status,
  });

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'] as String,
      activityName: json['activity_name'] as String,
      scheduleType: json['schedule_type'] as String,
      date: json['date'] as String,
      time: json['time'] as String,
      repeatMode: json['repeat_mode'] as String?,
      repeatDay: json['repeat_day'] as String?,
      nodeIds: List<String>.from(json['node_ids']),
      commands: List<String>.from(json['commands']),
      executionMethod: json['execution_method'] as String? ?? 'broadcast',
      createdAt: json['created_at'] as String,
      status: json['status'] as String,
    );
  }
}
