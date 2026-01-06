import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/node_model.dart';
import '../providers/deployment_provider.dart';
import 'select_node_animation.dart';

class DeploymentInputSection extends ConsumerStatefulWidget {
  const DeploymentInputSection({super.key});

  @override
  ConsumerState<DeploymentInputSection> createState() =>
      _DeploymentInputSectionState();
}

class _DeploymentInputSectionState
    extends ConsumerState<DeploymentInputSection> {
  DropzoneViewController? dropZoneController;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deploymentProvider);
    final notifier = ref.read(deploymentProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get selected node types
    final selectedNodeTypes = state.selectedNodeTypes;

    // Determine current selected node type
    NodeType? currentNodeType = state.selectedNodeType;
    if (currentNodeType == null && selectedNodeTypes.isNotEmpty) {
      currentNodeType = selectedNodeTypes.first;
    }
    // Ensure current type is in selected types
    if (currentNodeType != null &&
        !selectedNodeTypes.contains(currentNodeType)) {
      currentNodeType = selectedNodeTypes.isNotEmpty
          ? selectedNodeTypes.first
          : null;
    }

    // Get command for current node type
    final currentCommand = currentNodeType != null
        ? state.getCommandForType(currentNodeType)
        : '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Tabs and Method Toggle
          if (selectedNodeTypes.isNotEmpty) ...[
            Row(
              children: [
                _buildNodeTypeTabs(
                  context,
                  selectedNodeTypes,
                  currentNodeType,
                  notifier,
                  isDark,
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed:
                      state.selectedCount > 0 &&
                          state.status != DeploymentStatus.running
                      ? notifier.executeDeployment
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(
                      255,
                      219,
                      71,
                      106,
                    ), // Light green as requested
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    elevation: 0,
                  ),
                  icon: state.status == DeploymentStatus.running
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.play, size: 16),
                  label: Text(
                    state.status == DeploymentStatus.running
                        ? 'Deploying...'
                        : 'Run      ',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: SizedBox() ),
                _buildMethodToggle(context, state, notifier)
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Command or File input based on method
          if (state.method == DeploymentMethod.command) ...[
            currentNodeType == null
                ? Container(
                    height:
                        480, // Default approximate height of 20 lines text field
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: const SelectNodeAnimation(),
                  )
                : TextFormField(
                    key: ValueKey('command_${currentNodeType.name}'),
                    controller: TextEditingController(text: currentCommand)
                      ..selection = TextSelection.fromPosition(
                        TextPosition(offset: currentCommand.length),
                      ),
                    onChanged: (value) {
                      notifier.updateCommandForType(currentNodeType!, value);
                    },
                    enabled: true,
                    keyboardType: TextInputType.multiline,
                    minLines: 20,
                    maxLines: 20,
                    style: GoogleFonts.sourceCodePro(
                      fontSize: 14,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Enter command for ${currentNodeType.name.toUpperCase()}...',
                      hintStyle: TextStyle(color: theme.hintColor),
                      filled: true,
                      fillColor: theme.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
          ] else if (state.method == DeploymentMethod.file) ...[
            if (kIsWeb) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Builder(
                      builder: (context) {
                        return DropzoneView(
                          operation: DragOperation.copyLink,
                          onHover: () => print('Hover DropZone'),
                          onLeave: () => print('Leave DropZone'),
                          onCreated: (ctrl) => dropZoneController = ctrl,
                          onDropFile: (event) =>
                              acceptFile(event, currentNodeType),
                        );
                      },
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.uploadCloud,
                          size: 32,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        const SizedBox(height: 8),

                        Text(
                          currentNodeType != null
                              ? 'Click to upload for ${currentNodeType.name.toUpperCase()}'
                              : 'Click to upload',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (Platform.isWindows) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.uploadCloud,
                      size: 32,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(height: 8),

                    Text(
                      currentNodeType != null
                          ? 'Click to upload for ${currentNodeType.name.toUpperCase()}'
                          : 'Click to upload',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (Platform.isLinux)
              ...[]
            else if (Platform.isMacOS)
              ...[],
          ],
        ],
      ),
    );
  }

  Widget _buildNodeTypeTabs(
    BuildContext context,
    List<NodeType> nodeTypes,
    NodeType? currentType,
    DeploymentNotifier notifier,
    bool isDark,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? theme.dividerColor : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: nodeTypes.map((type) {
          final isSelected = type == currentType;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => notifier.setSelectedNodeType(type),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? theme.cardColor : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                  border: isSelected
                      ? Border.all(
                          color: isDark
                              ? theme.dividerColor
                              : Colors.grey.shade300,
                        )
                      : null,
                ),
                child: Text(
                  type.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? theme.textTheme.displayLarge?.color
                        : (isDark ? Colors.grey[500] : Colors.grey[600]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> acceptFile(dynamic event, NodeType? nodeType) async {
    if (dropZoneController == null) {
      print('DropZone controller not initialized');
      return;
    }

    try {
      final name = await dropZoneController!.getFilename(event);
      final mime = await dropZoneController!.getFileMIME(event);
      final size = await dropZoneController!.getFileSize(event);
      final url = await dropZoneController!.createFileUrl(event);

      print('File name    : $name');
      print('File size    : $size bytes');
      print('MIME type    : $mime');
      print('File URL     : $url');
      print('Node type    : ${nodeType?.name ?? 'none'}');

      // Update the deployment provider with the file information for this node type
      if (nodeType != null) {
        ref.read(deploymentProvider.notifier).updateFileForType(nodeType, name);
      }
    } catch (e) {
      print('Error getting file info: $e');
    }
  }

  Widget _buildMethodToggle(
    BuildContext context,
    DeploymentState state,
    DeploymentNotifier notifier,
  ) {
    return Container(
      width: 200, // Fixed width for the toggle
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          _buildTab(
            context,
            DeploymentMethod.command,
            'Command',
            state.method,
            notifier,
            isEnabled: state.selectedCount > 0,
          ),
          _buildTab(
            context,
            DeploymentMethod.file,
            'File',
            state.method,
            notifier,
            isEnabled: state.selectedCount > 0,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    DeploymentMethod method,
    String label,
    DeploymentMethod current,
    DeploymentNotifier notifier, {
    bool isEnabled = true,
  }) {
    final bool isSelected = method == current;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: isEnabled ? () => notifier.setMethod(method) : null,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected && isEnabled
                  ? const Color.fromARGB(255, 50, 165, 96)
                  : Colors.transparent, // Darker Green
              borderRadius: BorderRadius.circular(6),
              boxShadow: isSelected && isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected && isEnabled
                        ? Colors.white
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
