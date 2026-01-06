import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/node_model.dart';

class NodeTile extends StatelessWidget {
  final Node node;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  const NodeTile({
    super.key,
    required this.node,
    required this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: node.isSelected
                ? _getNodeTypeColor(node.type)
                : theme.dividerColor,
            width: node.isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: node.isSelected 
                  ? _getNodeTypeColor(node.type).withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              node.name,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                // color: theme.textTheme.displayMedium?.color,
                color: _getNodeTypeColor(node.type),
              ),
            ),
            // const SizedBox(height: 4),
            // Text(
            //   node.type.name.toUpperCase(),
            //   style: GoogleFonts.inter(
            //     fontSize: 12,
            //     fontWeight: FontWeight.w500,
            //     color: _getNodeTypeColor(node.type),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
  Color _getNodeTypeColor(NodeType type) {
    switch (type) {
      case NodeType.standalone:
        return Colors.blue;
      case NodeType.gwc:
        return Colors.green;
      case NodeType.gwu:
        return Colors.orange;
      case NodeType.pcc:
        return Colors.purple;
      case NodeType.pcg:
        return Colors.red;
    }
  }
}
