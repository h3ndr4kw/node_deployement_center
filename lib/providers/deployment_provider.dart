import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/node_model.dart';

enum DeploymentMethod { command, file }
enum DeploymentStatus { idle, running, success, failure }

class DeploymentState {
  final List<Node> nodes;
  final DeploymentMethod method;
  final String inputCommand;
  final DeploymentStatus status;

  DeploymentState({
    required this.nodes,
    required this.method,
    required this.inputCommand,
    required this.status,
  });

  int get selectedCount => nodes.where((n) => n.isSelected).length;

  DeploymentState copyWith({
    List<Node>? nodes,
    DeploymentMethod? method,
    String? inputCommand,
    DeploymentStatus? status,
  }) {
    return DeploymentState(
      nodes: nodes ?? this.nodes,
      method: method ?? this.method,
      inputCommand: inputCommand ?? this.inputCommand,
      status: status ?? this.status,
    );
  }
}


class DeploymentNotifier extends Notifier<DeploymentState> {
  @override
  DeploymentState build() {
    return DeploymentState(
      nodes: [
        const Node(id: '1', name: 'node-prod-01', ip: '192.168.1.101', isOnline: true),
        const Node(id: '2', name: 'node-prod-02', ip: '192.168.1.102', isOnline: true),
        const Node(id: '3', name: 'node-staging-01', ip: '192.168.1.201', isOnline: true),
        const Node(id: '4', name: 'node-staging-02', ip: '192.168.1.202', isOnline: false),
        const Node(id: '5', name: 'node-dev-01', ip: '192.168.1.301', isOnline: true),
        const Node(id: '6', name: 'node-dev-02', ip: '192.168.1.302', isOnline: true),
      ],
      method: DeploymentMethod.command,
      inputCommand: 'show running-config | nomore',
      status: DeploymentStatus.idle,
    );
  }

  void toggleSelection(String id) {
    state = state.copyWith(
      nodes: state.nodes.map((node) {
        if (node.id == id) {
          return node.copyWith(isSelected: !node.isSelected);
        }
        return node;
      }).toList(),
    );
  }

  void selectAll() {
    state = state.copyWith(
      nodes: state.nodes.map((node) => node.copyWith(isSelected: true)).toList(),
    );
  }

  void clearSelection() {
    state = state.copyWith(
      nodes: state.nodes.map((node) => node.copyWith(isSelected: false)).toList(),
    );
  }

  void setMethod(DeploymentMethod method) {
    state = state.copyWith(method: method);
  }

  void updateInput(String value) {
    state = state.copyWith(inputCommand: value);
  }

  Future<void> executeDeployment() async {
    if (state.status == DeploymentStatus.running) return;
    if (state.selectedCount == 0) return;

    state = state.copyWith(status: DeploymentStatus.running);
    await Future.delayed(const Duration(seconds: 2)); // Mock execution
    state = state.copyWith(status: DeploymentStatus.success);
    
    // Reset to idle after a moment
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(status: DeploymentStatus.idle);
  }
}

final deploymentProvider = NotifierProvider<DeploymentNotifier, DeploymentState>(() {
  return DeploymentNotifier();
});
