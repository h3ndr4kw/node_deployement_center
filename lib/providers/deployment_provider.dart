import 'package:file_picker/file_picker.dart';
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
  final String? selectedFile;
  final DeploymentStatus status;
  final List<NodeArea> selectedAreaOrder;
  final Map<NodeType, String> commandsByNodeType;
  final Map<NodeType, String?> filesByNodeType;
  final NodeType? selectedNodeType;

  DeploymentState({
    required this.nodes,
    required this.method,
    required this.inputCommand,
    this.selectedFile,
    required this.status,
    this.selectedAreaOrder = const [],
    this.commandsByNodeType = const {},
    this.filesByNodeType = const {},
    this.selectedNodeType,
  });

  int get selectedCount => nodes.where((n) => n.isSelected).length;

  /// Get list of node types that have selected nodes
  List<NodeType> get selectedNodeTypes {
    final types = nodes
        .where((n) => n.isSelected)
        .map((n) => n.type)
        .toSet()
        .toList();
    // Sort by enum index for consistent order
    types.sort((a, b) => a.index.compareTo(b.index));
    return types;
  }

  /// Get command for a specific node type
  String getCommandForType(NodeType type) {
    return commandsByNodeType[type] ?? '';
  }

  /// Get file for a specific node type
  String? getFileForType(NodeType type) {
    return filesByNodeType[type];
  }

  DeploymentState copyWith({
    List<Node>? nodes,
    DeploymentMethod? method,
    String? inputCommand,
    String? selectedFile,
    DeploymentStatus? status,
    List<NodeArea>? selectedAreaOrder,
    Map<NodeType, String>? commandsByNodeType,
    Map<NodeType, String?>? filesByNodeType,
    NodeType? selectedNodeType,
    bool clearSelectedNodeType = false,
  }) {
    return DeploymentState(
      nodes: nodes ?? this.nodes,
      method: method ?? this.method,
      inputCommand: inputCommand ?? this.inputCommand,
      selectedFile: selectedFile ?? this.selectedFile,
      status: status ?? this.status,
      selectedAreaOrder: selectedAreaOrder ?? this.selectedAreaOrder,
      commandsByNodeType: commandsByNodeType ?? this.commandsByNodeType,
      filesByNodeType: filesByNodeType ?? this.filesByNodeType,
      selectedNodeType: clearSelectedNodeType
          ? null
          : (selectedNodeType ?? this.selectedNodeType),
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
      inputCommand: '',
      selectedFile: null,
      status: DeploymentStatus.idle,
      selectedAreaOrder: [],
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

    // Update the selected area order
    List<NodeArea> newOrder = List.from(state.selectedAreaOrder);
    if (newSelectionState) {
      // Adding area - append to end if not already present
      if (!newOrder.contains(area)) {
        newOrder.add(area);
      }
    } else {
      // Removing area from selection order
      newOrder.remove(area);
    }

    state = state.copyWith(
      nodes: state.nodes.map((node) {
        if (node.area == area) {
          return node.copyWith(isSelected: newSelectionState);
        }
        return node;
      }).toList(),
      selectedAreaOrder: newOrder,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      nodes: state.nodes
          .map((node) => node.copyWith(isSelected: false))
          .toList(),
      selectedAreaOrder: [],
    );
  }

  void setMethod(DeploymentMethod method) {
    state = state.copyWith(method: method);
  }

  void setSelectedNodeType(NodeType type) {
    state = state.copyWith(selectedNodeType: type);
  }

  void updateInput(String value) {
    state = state.copyWith(inputCommand: value);
  }

  void updateCommandForType(NodeType type, String command) {
    final newCommands = Map<NodeType, String>.from(state.commandsByNodeType);
    newCommands[type] = command;
    state = state.copyWith(commandsByNodeType: newCommands);
  }

  void updateFileForType(NodeType type, String? fileName) {
    final newFiles = Map<NodeType, String?>.from(state.filesByNodeType);
    newFiles[type] = fileName;
    state = state.copyWith(filesByNodeType: newFiles);
  }

  Future<void> selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        // On web, path is null, so we use name. On desktop, we can use path or name.
        // For display purposes, name is sufficient.
        state = state.copyWith(selectedFile: result.files.single.name);
      } else {
        // User canceled the picker
      }
    } catch (e) {
      print('Error picking file: $e');
    }
  }

  void clearFile() {
    state = state.copyWith(
      selectedFile: null,
    ); // This effectively clears it, passing null explicitly
    // Note: copyWith implementation above uses ?? this.selectedFile, so passing null there keeps the old value if the parameter is optional and checked for null.
    // Wait, my copyWith implementation: selectedFile: selectedFile ?? this.selectedFile
    // If I pass null, it keeps this.selectedFile.
    // I need to fix copyWith to allow nullable update or use a different mechanism.
    // Let's modify copyWith to handle nullable updates correctly or just construct a new state.
    // Actually, simply constructing new State is cleaner for nullable fields update if copyWith is limited.
    state = DeploymentState(
      nodes: state.nodes,
      method: state.method,
      inputCommand: state.inputCommand,
      selectedFile: null,
      status: state.status,
    );
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
