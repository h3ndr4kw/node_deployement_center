import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/node_model.dart';
import '../providers/deployment_provider.dart';

class RegionalSelector extends ConsumerWidget {
  const RegionalSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deploymentProvider);
    final notifier = ref.read(deploymentProvider.notifier);
    final theme = Theme.of(context);

    // Styling constants
    final isDark = theme.brightness == Brightness.dark;

    final inactiveColor = isDark ? theme.colorScheme.surface : Colors.white;
    final activeTextColor = Colors.white;
    final inactiveTextColor = isDark
        ? Colors.white.withOpacity(0.8)
        : Colors.black.withOpacity(0.6);
    final borderColor = isDark
        ? theme.colorScheme.outline.withOpacity(0.5)
        : Colors.grey.withOpacity(0.2);

    return Column(
      children: [
        Text(
          'REGIONAL',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? theme.cardColor : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? theme.dividerColor : Colors.grey.withOpacity(0.1),
            ),
          ),
          child: Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: NodeArea.values.map((area) {
                // Determine selection state based on nodes
                final areaNodes = state.nodes
                    .where((n) => n.area == area)
                    .toList();

                // If no nodes, can't be selected. If nodes exist, check if all are selected.
                final isSelected =
                    areaNodes.isNotEmpty &&
                    areaNodes.every((node) => node.isSelected);

                final label = area.name.toUpperCase();

                // Area-specific colors
                final areaColors = {
                  NodeArea.sumbagut: const Color(0xFF2979FF), // Blue
                  NodeArea.sumbagteng: const Color(0xFF00C853), // Green
                  NodeArea.sumbagsel: const Color(0xFFFFA000), // Amber/Orange
                  NodeArea.jabo: const Color(0xFFFF2E63), // Pink/Red
                  NodeArea.jabar: const Color(0xFFAA00FF), // Purple
                  NodeArea.kalimantan: const Color(0xFF00E5FF), // Cyan
                  NodeArea.sulawesi: const Color(0xFF536DFE), // Indigo
                  NodeArea.malirja: const Color(0xFFFF6D00), // Deep Orange
                  NodeArea.testbed: Colors.grey,
                };

                final activeColor = areaColors[area] ?? const Color(0xFFFF2E63);

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      notifier.selectNodesByArea(area);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor : inactiveColor,
                        borderRadius: BorderRadius.circular(24),
                        border: isSelected
                            ? null
                            : Border.all(color: borderColor),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.05),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? activeTextColor
                              : inactiveTextColor,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
