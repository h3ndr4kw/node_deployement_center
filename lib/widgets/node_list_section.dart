import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/deployment_provider.dart';
import 'node_tile.dart';
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
            child: ListView.builder(
              itemCount: state.nodes.length,
              itemBuilder: (context, index) {
                final node = state.nodes[index];
                return NodeTile(
                  node: node,
                  onTap: () => notifier.toggleSelection(node.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
