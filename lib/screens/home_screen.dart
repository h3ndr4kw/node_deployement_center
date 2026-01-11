import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/deployment_provider.dart';
import '../widgets/deployment_input_section.dart';
import '../widgets/execution_status_table.dart';
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
          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive layout: Column on small screens, Row on large
              if (constraints.maxWidth < 800) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      _buildExecutionCard(context, state, notifier),
                      const SizedBox(height: 24),
                      DeploymentInputSection(),
                      const SizedBox(height: 24),
                      const ExecutionStatusTable(),
                      const SizedBox(height: 24),
                      const SizedBox(height: 500, child: NodeListSection()),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 3,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // _buildExecutionCard(context, state, notifier),
                              // const SizedBox(height: 8),
                              DeploymentInputSection(),
                              const SizedBox(height: 16),
                              const ExecutionStatusTable(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right Column
                      Expanded(flex: 2, child: const NodeListSection()),
                    ],
                  ),
                );
              }
            },
          ),

          Positioned(
            bottom: 70,
            right: 50,
            child: IconButton(
              onPressed: () {
                ref.read(themeProvider.notifier).toggleTheme();
              },
              icon: Icon(
                themeMode == ThemeMode.dark
                    ? LucideIcons.sun
                    : LucideIcons.moon,
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
          // Toggle Switch
          const Spacer(),
          ElevatedButton.icon(
            onPressed:
                state.selectedCount > 0 &&
                    state.status != DeploymentStatus.running
                ? () async {
                    final error = await notifier.executeDeployment();
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
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
                  : 'Run      ',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
