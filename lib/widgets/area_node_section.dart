import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/node_model.dart';
import 'node_tile.dart';

class AreaNodeSection extends StatelessWidget {
  final String title;
  final List<Node> nodes;
  final Function(String id) onToggle;

  const AreaNodeSection({
    super.key,
    required this.title,
    required this.nodes,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(
          height: 100, // Fixed height for the horizontal list
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: nodes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final node = nodes[index];
              return NodeTile(node: node, onTap: () => onToggle(node.id));
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
