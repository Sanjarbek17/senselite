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

/// Widget for displaying and managing update settings
class UpdateSettingsCard extends ConsumerWidget {
  /// Creates an UpdateSettingsCard widget
  const UpdateSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateNotifierProvider);
    final updateNotifier = ref.read(updateNotifierProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.system_update,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Updates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(updateState),
              ],
            ),
            const SizedBox(height: 16),
            _buildAutoUpdateToggle(context, updateState, updateNotifier),
            const SizedBox(height: 12),
            _buildCheckIntervalSettings(context, updateState, updateNotifier),
            const SizedBox(height: 12),
            _buildLastCheckInfo(updateState),
            const SizedBox(height: 16),
            _buildActionButtons(context, updateState, updateNotifier),
          ],
        ),
      ),
    );
  }

  /// Builds the status chip showing current update status
  Widget _buildStatusChip(UpdateState state) {
    Color chipColor;
    IconData chipIcon;
    String chipText;

    switch (state.status) {
      case UpdateStatus.available:
        chipColor = Colors.orange;
        chipIcon = Icons.new_releases;
        chipText = 'Update Available';
        break;
      case UpdateStatus.upToDate:
        chipColor = Colors.green;
        chipIcon = Icons.check_circle;
        chipText = 'Up to Date';
        break;
      case UpdateStatus.error:
        chipColor = Colors.red;
        chipIcon = Icons.error;
        chipText = 'Error';
        break;
      case UpdateStatus.downloading:
        chipColor = Colors.blue;
        chipIcon = Icons.download;
        chipText = 'Downloading';
        break;
      case UpdateStatus.downloaded:
        chipColor = Colors.purple;
        chipIcon = Icons.install_desktop;
        chipText = 'Ready to Install';
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.help_outline;
        chipText = state.status.description;
    }

    return Chip(
      avatar: Icon(chipIcon, size: 16, color: Colors.white),
      label: Text(
        chipText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
    );
  }

  /// Builds the automatic update toggle switch
  Widget _buildAutoUpdateToggle(
    BuildContext context,
    UpdateState state,
    UpdateNotifier notifier,
  ) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Automatic Updates',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'Check for updates automatically',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: state.autoCheckEnabled,
          onChanged: (enabled) {
            notifier.setAutoUpdateConfig(enabled: enabled);
          },
        ),
      ],
    );
  }

  /// Builds the check interval settings
  Widget _buildCheckIntervalSettings(
    BuildContext context,
    UpdateState state,
    UpdateNotifier notifier,
  ) {
    return Row(
      children: [
        const Icon(Icons.schedule, size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check Interval',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'How often to check for updates',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        DropdownButton<int>(
          value: state.checkIntervalHours,
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 hour')),
            DropdownMenuItem(value: 6, child: Text('6 hours')),
            DropdownMenuItem(value: 12, child: Text('12 hours')),
            DropdownMenuItem(value: 24, child: Text('24 hours')),
            DropdownMenuItem(value: 168, child: Text('Weekly')),
          ],
          onChanged: state.autoCheckEnabled
              ? (hours) {
                  if (hours != null) {
                    notifier.setAutoUpdateConfig(
                      enabled: state.autoCheckEnabled,
                      checkIntervalHours: hours,
                    );
                  }
                }
              : null,
        ),
      ],
    );
  }

  /// Builds the last check information display
  Widget _buildLastCheckInfo(UpdateState state) {
    final lastCheck = state.lastCheckTime;
    final lastCheckText = lastCheck != null ? 'Last checked: ${_formatDateTime(lastCheck)}' : 'Never checked for updates';

    return Row(
      children: [
        const Icon(Icons.history, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          lastCheckText,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Builds the action buttons
  Widget _buildActionButtons(
    BuildContext context,
    UpdateState state,
    UpdateNotifier notifier,
  ) {
    return Row(
      children: [
        // Check Now button
        ElevatedButton.icon(
          onPressed: state.status.isActive
              ? null
              : () {
                  notifier.checkForUpdates(forceCheck: true);
                },
          icon: state.status == UpdateStatus.checking
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: const Text('Check Now'),
        ),
        const SizedBox(width: 8),

        // Show Update button (if available)
        if (state.status == UpdateStatus.available || state.status == UpdateStatus.downloaded)
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const UpdateDialog(),
              );
            },
            icon: const Icon(Icons.system_update),
            label: Text(
              state.status == UpdateStatus.downloaded ? 'Install Update' : 'View Update',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),

        const Spacer(),

        // Cleanup button
        TextButton.icon(
          onPressed: () {
            notifier.cleanupOldUpdates();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Old update files cleaned up'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.cleaning_services, size: 16),
          label: const Text('Cleanup'),
        ),
      ],
    );
  }

  /// Formats a DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
