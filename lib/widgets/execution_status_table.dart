import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/node_model.dart';
import '../providers/deployment_provider.dart';

class ExecutionStatusTable extends ConsumerWidget {
  const ExecutionStatusTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deploymentProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get selected nodes
    final selectedNodes = state.nodes.where((n) => n.isSelected).toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // // Header
          // Padding(
          //   padding: const EdgeInsets.all(20),
          //   child: Row(
          //     children: [
          //       // Icon(
          //       //   Icons.table_chart_outlined,
          //       //   size: 20,
          //       //   color: theme.textTheme.displayLarge?.color,
          //       // ),
          //       // const SizedBox(width: 8),
          //       // Text(
          //       //   'Execution Status',
          //       //   style: GoogleFonts.inter(
          //       //     fontSize: 16,
          //       //     fontWeight: FontWeight.w700,
          //       //     color: theme.textTheme.displayLarge?.color,
          //       //   ),
          //       // ),
          //       // const SizedBox(width: 12),
          //       Container(
          //         padding: const EdgeInsets.symmetric(
          //           horizontal: 8,
          //           vertical: 4,
          //         ),
          //         decoration: BoxDecoration(
          //           color: isDark
          //               ? theme.colorScheme.surfaceContainerHighest
          //               : Colors.grey.shade100,
          //           borderRadius: BorderRadius.circular(12),
          //         ),
          //         child: Text(
          //           '${selectedNodes.length} nodes',
          //           style: GoogleFonts.inter(
          //             fontSize: 12,
          //             fontWeight: FontWeight.w500,
          //             color: theme.textTheme.bodyMedium?.color,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),

          // // Divider
          // Divider(height: 1, color: theme.dividerColor),

          // Table or Empty State
          if (selectedNodes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No nodes selected',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select nodes from the Target Nodes panel to see execution status',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.grey[600] : Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width * 0.4,
                  ),
                  child: DataTable(
                    headingRowColor: WidgetStatePropertyAll(
                      isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : Colors.grey.shade50,
                    ),
                    dataRowColor: WidgetStatePropertyAll(Colors.transparent),
                    columnSpacing: 24,
                    horizontalMargin: 20,
                    headingTextStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                    dataTextStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    columns: const [
                      DataColumn(label: Text('NODE NAME')),
                      DataColumn(label: Text('IP ADDRESS')),
                      DataColumn(label: Text('AREA')),
                      DataColumn(label: Text('NODE TYPE')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('DATE EXECUTION')),
                    ],
                    rows: selectedNodes.map((node) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              node.name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(Text(node.ip)),
                          DataCell(Text(node.area.name.toUpperCase())),
                          DataCell(Text(node.type.name.toUpperCase())),
                          DataCell(
                            _buildStatusBadge(node.executionStatus, isDark),
                          ),
                          DataCell(
                            Text(
                              node.executionDate != null
                                  ? DateFormat(
                                      'yyyy-MM-dd HH:mm:ss',
                                    ).format(node.executionDate!)
                                  : '-',
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(NodeExecutionStatus status, bool isDark) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusConfig.color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusConfig.color.withValues(alpha: isDark ? 0.4 : 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusConfig.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusConfig.label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusConfig.color,
            ),
          ),
        ],
      ),
    );
  }

  ({Color color, String label}) _getStatusConfig(NodeExecutionStatus status) {
    switch (status) {
      case NodeExecutionStatus.ready:
        return (color: Colors.grey, label: 'Ready');
      case NodeExecutionStatus.login:
        return (color: const Color(0xFF2196F3), label: 'Login');
      case NodeExecutionStatus.checkUser:
        return (color: const Color(0xFF00BCD4), label: 'Check User');
      case NodeExecutionStatus.loadScript:
        return (color: const Color(0xFFFF9800), label: 'Load Script');
      case NodeExecutionStatus.validate:
        return (color: const Color(0xFF9C27B0), label: 'Validate');
      case NodeExecutionStatus.commit:
        return (color: const Color(0xFFFFC107), label: 'Commit');
      case NodeExecutionStatus.done:
        return (color: const Color(0xFF4CAF50), label: 'Done');
    }
  }
}
