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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // // Header
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           // Text(
                //           //   // 'Node Deployment Center',
                //           //   'EPG Deployment Center',
                //           //   style: GoogleFonts.inter(
                //           //     fontSize: 28,
                //           //     fontWeight: FontWeight.w800,
                //           //     color: Theme.of(
                //           //       context,
                //           //     ).textTheme.displayLarge?.color,
                //           //     letterSpacing: -0.5,
                //           //   ),
                //           // ),
                //           // const SizedBox(height: 8),
                //           // Text(
                //           //   'Deploy file or command to selected nodes simultaneously',
                //           //   style: GoogleFonts.inter(
                //           //     fontSize: 16,
                //           //     color: Theme.of(context).textTheme.bodyMedium?.color,
                //           //   ),
                //           // ),
                //         ],
                //       ),
                //     ),
                //     IconButton(
                //       onPressed: () {
                //         ref.read(themeProvider.notifier).toggleTheme();
                //       },
                //       icon: Icon(
                //         themeMode == ThemeMode.dark
                //             ? LucideIcons.sun
                //             : LucideIcons.moon,
                //         color: Theme.of(context).textTheme.bodyMedium?.color,
                //       ),
                //     ),
                //   ],
                // ),
                // const SizedBox(height: 32),

                // Main Content Area
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Responsive layout: Column on small screens, Row on large
                    if (constraints.maxWidth < 800) {
                      return Column(
                        children: [
                          _buildExecutionCard(context, state, notifier),
                          const SizedBox(height: 24),
                          DeploymentInputSection(),
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
                                _buildExecutionCard(context, state, notifier),
                                const SizedBox(height: 8),
                                DeploymentInputSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          // Right Column
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 800, // Fixed height for scrolling list
                              child: const NodeListSection(),
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

          Positioned(
            top: 50,
            right: 50,
            child: IconButton(
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              icon: Icon(
                themeMode == ThemeMode.dark ? LucideIcons.sun : LucideIcons.moon,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionCard(
    BuildContext context,
    DeploymentState state,
    DeploymentNotifier notifier,
  ) {
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
            child: Icon(
              LucideIcons.server,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              size: 24,
            ),
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
          // Toggle Switch
          Container(
            width: 200, // Fixed width for the toggle
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                ),
                _buildTab(
                  context,
                  DeploymentMethod.file,
                  'File',
                  state.method,
                  notifier,
                ),
              ],
            ),
          ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  : 'Execute      ',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
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
    DeploymentNotifier notifier,
  ) {
    final bool isSelected = method == current;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => notifier.setMethod(method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color.fromARGB(255, 50, 165, 96)
                : Colors.transparent, // Darker Green
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
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
                  fontSize: 13, // Slightly smaller for the bar
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
