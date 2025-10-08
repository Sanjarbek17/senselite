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

/// Dialog widget for displaying update information and allowing user interaction
class UpdateDialog extends ConsumerWidget {
  /// Whether this is a critical update that requires immediate installation
  final bool isCritical;

  /// Creates an UpdateDialog widget
  const UpdateDialog({
    super.key,
    this.isCritical = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateNotifierProvider);
    final updateNotifier = ref.read(updateNotifierProvider.notifier);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            isCritical ? Icons.warning : Icons.system_update,
            color: isCritical ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 8),
          Text(isCritical ? 'Critical Update Available' : 'Update Available'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (updateState.updateInfo != null) ...[
              _buildVersionInfo(updateState),
              const SizedBox(height: 16),
              _buildReleaseNotes(updateState),
              const SizedBox(height: 16),
              _buildFileSize(updateState),
              if (updateState.status == UpdateStatus.downloading) ...[
                const SizedBox(height: 16),
                _buildDownloadProgress(updateState),
              ],
              if (updateState.errorMessage != null) ...[
                const SizedBox(height: 16),
                _buildErrorMessage(updateState),
              ],
            ],
          ],
        ),
      ),
      actions: _buildActions(context, updateState, updateNotifier),
    );
  }

  /// Builds the version information display
  Widget _buildVersionInfo(UpdateState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.new_releases, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version ${state.updateInfo!.version}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Build ${state.updateInfo!.buildNumber}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Released: ${_formatDate(state.updateInfo!.releaseDate)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the release notes display
  Widget _buildReleaseNotes(UpdateState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What\'s New:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Text(
              state.updateInfo!.releaseNotes,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the file size information
  Widget _buildFileSize(UpdateState state) {
    final sizeInMB = (state.updateInfo!.fileSize / (1024 * 1024)).toStringAsFixed(1);
    return Row(
      children: [
        const Icon(Icons.download, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          'Download size: $sizeInMB MB',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Builds the download progress indicator
  Widget _buildDownloadProgress(UpdateState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Downloading...'),
            Text('${(state.downloadProgress * 100).toInt()}%'),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: state.downloadProgress,
          backgroundColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  /// Builds the error message display
  Widget _buildErrorMessage(UpdateState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the action buttons based on current state
  List<Widget> _buildActions(
    BuildContext context,
    UpdateState state,
    UpdateNotifier notifier,
  ) {
    final actions = <Widget>[];

    // Always show close/cancel button (unless critical update and downloading/installing)
    if (!(isCritical && (state.status == UpdateStatus.downloading || state.status == UpdateStatus.installing))) {
      actions.add(
        TextButton(
          onPressed: () {
            notifier.skipUpdate();
            Navigator.of(context).pop();
          },
          child: Text(isCritical ? 'Later' : 'Skip'),
        ),
      );
    }

    // Retry button on error
    if (state.status == UpdateStatus.error) {
      actions.add(
        ElevatedButton(
          onPressed: () {
            notifier.clearError();
          },
          child: const Text('Retry'),
        ),
      );
    }

    // Download button
    if (state.status == UpdateStatus.available) {
      actions.add(
        ElevatedButton(
          onPressed: () {
            notifier.downloadUpdate();
          },
          child: const Text('Download'),
        ),
      );
    }

    // Install button
    if (state.status == UpdateStatus.downloaded) {
      actions.add(
        ElevatedButton(
          onPressed: () {
            notifier.installUpdate();
          },
          child: const Text('Install & Restart'),
        ),
      );
    }

    // Show progress for active states
    if (state.status.isActive && state.status != UpdateStatus.downloading) {
      actions.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return actions;
  }

  /// Formats a date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
