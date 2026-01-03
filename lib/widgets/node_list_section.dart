import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/deployment_provider.dart';
import '../models/node_model.dart';
import 'area_node_section.dart';
import 'regional_selector.dart';

class NodeListSection extends ConsumerWidget {
  const NodeListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deploymentProvider);
    final notifier = ref.read(deploymentProvider.notifier);
    final theme = Theme.of(context);

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
          Row(
            children: [
              Icon(
                LucideIcons.server,
                size: 20,
                color: theme.textTheme.displayLarge?.color,
              ),
              const SizedBox(width: 8),
              Text(
                'Target Nodes',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: theme.textTheme.displayLarge?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Text(
          //   'Select nodes for deployment',
          //   style: GoogleFonts.inter(
          //     fontSize: 14,
          //     color: theme.textTheme.bodyMedium?.color,
          //   ),
          // ),
          // const SizedBox(height: 20),
          const RegionalSelector(),
          if (state.selectedCount > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: notifier.clearSelection,
                icon: Icon(
                  LucideIcons.x,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  'Clear Selection',
                  style: GoogleFonts.inter(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Builder(
                builder: (context) {
                  // Sort areas: selected areas first (in selection order), then unselected
                  final selectedOrder = state.selectedAreaOrder;
                  final sortedAreas = List<NodeArea>.from(NodeArea.values);
                  sortedAreas.sort((a, b) {
                    final aSelected = selectedOrder.contains(a);
                    final bSelected = selectedOrder.contains(b);

                    if (aSelected && bSelected) {
                      // Both selected: sort by selection order
                      return selectedOrder
                          .indexOf(a)
                          .compareTo(selectedOrder.indexOf(b));
                    } else if (aSelected) {
                      // a is selected, b is not: a comes first
                      return -1;
                    } else if (bSelected) {
                      // b is selected, a is not: b comes first
                      return 1;
                    } else {
                      // Neither selected: maintain original order
                      return NodeArea.values
                          .indexOf(a)
                          .compareTo(NodeArea.values.indexOf(b));
                    }
                  });

                  // Area-specific colors (matching RegionalSelector)
                  const areaColors = {
                    NodeArea.sumbagut: Color(0xFF2979FF), // Blue
                    NodeArea.sumbagteng: Color(0xFF00C853), // Green
                    NodeArea.sumbagsel: Color(0xFFFFA000), // Amber/Orange
                    NodeArea.jabo: Color(0xFFFF2E63), // Pink/Red
                    NodeArea.jabar: Color(0xFFAA00FF), // Purple
                    NodeArea.kalimantan: Color(0xFF00E5FF), // Cyan
                    NodeArea.sulawesi: Color(0xFF536DFE), // Indigo
                    NodeArea.malirja: Color(0xFFFF6D00), // Deep Orange
                    NodeArea.testbed: Colors.grey,
                  };

                  return Column(
                    children: sortedAreas.map((area) {
                      final areaNodes = state.nodes
                          .where((n) => n.area == area)
                          .toList();
                      if (areaNodes.isEmpty) return const SizedBox.shrink();

                      // Check if all nodes in this area are selected
                      final isAreaSelected =
                          areaNodes.isNotEmpty &&
                          areaNodes.every((node) => node.isSelected);

                      final areaColor = areaColors[area] ?? Colors.grey;

                      return AreaNodeSection(
                        title: area.name.toUpperCase(),
                        nodes: areaNodes,
                        onToggle: notifier.toggleSelection,
                        isAreaSelected: isAreaSelected,
                        areaColor: areaColor,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
