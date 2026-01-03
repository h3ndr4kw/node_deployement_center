import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/node_model.dart';
import 'node_tile.dart';

class AreaNodeSection extends StatelessWidget {
  final String title;
  final List<Node> nodes;
  final Function(String id) onToggle;
  final bool isAreaSelected;
  final Color areaColor;

  const AreaNodeSection({
    super.key,
    required this.title,
    required this.nodes,
    required this.onToggle,
    this.isAreaSelected = false,
    this.areaColor = Colors.grey,
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isAreaSelected ? 12 : 0,
              vertical: isAreaSelected ? 6 : 0,
            ),
            decoration: BoxDecoration(
              color: isAreaSelected ? areaColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: isAreaSelected
                  ? [
                      BoxShadow(
                        color: areaColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isAreaSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                letterSpacing: 1.2,
              ),
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
