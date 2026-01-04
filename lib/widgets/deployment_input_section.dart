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
          // Node Type Tabs (only show if there are selected nodes)
          if (selectedNodeTypes.isNotEmpty) ...[
            _buildNodeTypeTabs(
              context,
              selectedNodeTypes,
              currentNodeType,
              notifier,
              isDark,
            ),
            const SizedBox(height: 16),
          ],

          // Command or File input based on method
          if (state.method == DeploymentMethod.command) ...[
            // Text(
            //   'Command',
            //   style: GoogleFonts.inter(
            //     fontSize: 14,
            //     fontWeight: FontWeight.w600,
            //     color: theme.textTheme.displayMedium?.color,
            //   ),
            // ),
            // const SizedBox(height: 8),
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
            // const SizedBox(height: 8),
            // Text(
            //   currentNodeType != null
            //       ? 'Execute command on all selected ${currentNodeType.name.toUpperCase()} nodes'
            //       : 'Select nodes from the Target Nodes panel',
            //   style: GoogleFonts.inter(
            //     fontSize: 13,
            //     color: theme.textTheme.bodyMedium?.color,
            //   ),
            // ),
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
}
