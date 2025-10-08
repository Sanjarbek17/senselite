// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/update_status.dart';
import '../../../../core/providers/update_provider.dart';
import 'update_dialog.dart';

/// A banner widget that appears when updates are available
class UpdateNotificationBanner extends ConsumerWidget {
  /// Creates an UpdateNotificationBanner widget
  const UpdateNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateNotifierProvider);
    final updateNotifier = ref.read(updateNotifierProvider.notifier);

    // Only show banner for available updates or ready to install
    if (updateState.status != UpdateStatus.available && updateState.status != UpdateStatus.downloaded) {
      return const SizedBox.shrink();
    }

    final isCritical = updateState.updateInfo?.isCritical ?? false;
    final isReadyToInstall = updateState.status == UpdateStatus.downloaded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: isCritical ? Colors.orange.shade100 : Colors.blue.shade100,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isReadyToInstall
                    ? Icons.install_desktop
                    : isCritical
                    ? Icons.warning
                    : Icons.system_update,
                color: isCritical ? Colors.orange.shade700 : Colors.blue.shade700,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isReadyToInstall
                          ? 'Update Ready to Install'
                          : isCritical
                          ? 'Critical Update Available'
                          : 'Update Available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCritical ? Colors.orange.shade700 : Colors.blue.shade700,
                      ),
                    ),
                    if (updateState.updateInfo != null)
                      Text(
                        isReadyToInstall ? 'Version ${updateState.updateInfo!.version} is ready to install' : 'Version ${updateState.updateInfo!.version} is now available',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCritical ? Colors.orange.shade600 : Colors.blue.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReadyToInstall)
                    ElevatedButton(
                      onPressed: () {
                        updateNotifier.installUpdate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCritical ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('Install'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: !isCritical,
                          builder: (context) => UpdateDialog(isCritical: isCritical),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCritical ? Colors.orange : Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text('View'),
                    ),
                  const SizedBox(width: 8),
                  if (!isCritical || !isReadyToInstall)
                    IconButton(
                      onPressed: () {
                        updateNotifier.skipUpdate();
                      },
                      icon: const Icon(Icons.close),
                      iconSize: 20,
                      color: isCritical ? Colors.orange.shade700 : Colors.blue.shade700,
                      tooltip: 'Dismiss',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
