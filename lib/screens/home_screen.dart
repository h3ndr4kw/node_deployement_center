import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/deployment_provider.dart';
import '../widgets/deployment_input_section.dart';
import '../widgets/node_list_section.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deploymentProvider);
    final notifier = ref.read(deploymentProvider.notifier);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Node Deployment Center',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).textTheme.displayLarge?.color,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Deploy file, and commands to multiple nodes simultaneously',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(themeProvider.notifier).toggleTheme();
                  },
                  icon: Icon(
                    themeMode == ThemeMode.dark ? LucideIcons.sun : LucideIcons.moon,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Content Area
            LayoutBuilder(
              builder: (context, constraints) {
                // Responsive layout: Column on small screens, Row on large
                if (constraints.maxWidth < 800) {
                  return Column(
                    children: [
                      const DeploymentInputSection(),
                      const SizedBox(height: 24),
                      _buildExecutionCard(context, state, notifier),
                      const SizedBox(height: 24),
                      const SizedBox(height: 500, child: NodeListSection()),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 3,
                        child: Column(
                          children: [
                            const DeploymentInputSection(),
                            const SizedBox(height: 24),
                            _buildExecutionCard(context, state, notifier),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column
                      const Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 700, // Fixed height for scrolling list
                          child: NodeListSection(),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutionCard(BuildContext context, DeploymentState state, DeploymentNotifier notifier) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.server, color: Theme.of(context).textTheme.bodyMedium?.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${state.selectedCount} nodes selected',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.displayLarge?.color,
                  ),
                ),
                Text(
                  'Ready for deployment',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: state.selectedCount > 0 && state.status != DeploymentStatus.running
                ? notifier.executeDeployment
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B7280), // Greyish button as per screenshot
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
            icon: state.status == DeploymentStatus.running
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.play, size: 16),
            label: Text(
              state.status == DeploymentStatus.running ? 'Deploying...' : 'Execute Deployment',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
