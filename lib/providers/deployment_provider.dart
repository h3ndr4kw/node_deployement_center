import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:node_deployement/utils/node_builder.dart';
import '../models/node_model.dart';
import '../services/config_service.dart';

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
  Future<void> loadNodes() async {
    try {
      final content = await loadNodesConfig();
      final nodeBuilder = NodeBuilder(content: content);
      state = state.copyWith(nodes: nodeBuilder.getNodes());
    } catch (e) {
      // Handle error appropriately, maybe update status to failure or log it
      print('Error loading nodes: $e');
    }
  }

  @override
  DeploymentState build() {
    // Load nodes asynchronously
    Future.microtask(() => loadNodes());

    return DeploymentState(
      nodes: [],
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
      nodes: state.nodes
          .map((node) => node.copyWith(isSelected: true))
          .toList(),
    );
  }

  void selectNodesByArea(NodeArea area) {
    final areaNodes = state.nodes.where((n) => n.area == area).toList();
    final allSelected = areaNodes.every((n) => n.isSelected);
    final newSelectionState = !allSelected;

    state = state.copyWith(
      nodes: state.nodes.map((node) {
        if (node.area == area) {
          return node.copyWith(isSelected: newSelectionState);
        }
        return node;
      }).toList(),
    );
  }

  void clearSelection() {
    state = state.copyWith(
      nodes: state.nodes
          .map((node) => node.copyWith(isSelected: false))
          .toList(),
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

final deploymentProvider =
    NotifierProvider<DeploymentNotifier, DeploymentState>(() {
      return DeploymentNotifier();
    });
