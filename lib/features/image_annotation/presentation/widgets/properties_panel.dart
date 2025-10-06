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
import '../../../../core/models/image_item.dart';
import '../../../../core/models/project.dart';
import '../../../../core/models/label.dart';
import '../../../../core/providers/label_providers.dart';
import '../../../label_management/presentation/widgets/label_dialog.dart';

/// Widget for displaying properties and annotation tools
class PropertiesPanel extends ConsumerStatefulWidget {
  /// The current project
  final Project project;

  /// Currently selected image
  final ImageItem? selectedImage;

  /// Creates a new PropertiesPanel widget
  const PropertiesPanel({
    super.key,
    required this.project,
    this.selectedImage,
  });

  @override
  ConsumerState<PropertiesPanel> createState() => _PropertiesPanelState();
}

class _PropertiesPanelState extends ConsumerState<PropertiesPanel> {
  @override
  void initState() {
    super.initState();
    // Load labels and create defaults if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(projectLabelsNotifierProvider(widget.project.id).notifier);
      notifier.loadLabels().then((_) {
        notifier.createDefaultLabelsIfEmpty();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Properties',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: widget.selectedImage != null ? _buildImageProperties(context) : _buildNoSelectionState(context),
          ),
        ],
      ),
    );
  }

  /// Builds the properties display for selected image
  Widget _buildImageProperties(BuildContext context) {
    final image = widget.selectedImage!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Image info section
        _buildSection(
          context,
          'Image Information',
          [
            _buildInfoRow(context, 'Filename', image.filename),
            _buildInfoRow(context, 'Dimensions', '${image.width} × ${image.height}'),
            _buildInfoRow(context, 'File Size', _formatFileSize(image.fileSize)),
            _buildInfoRow(context, 'Annotated', image.isAnnotated ? 'Yes' : 'No'),
            _buildInfoRow(context, 'Annotations', '${image.annotationCount}'),
          ],
        ),

        const SizedBox(height: 24),

        // Labels section
        _buildSection(
          context,
          'Labels',
          [
            _buildLabelsManagement(context),
          ],
        ),

        const SizedBox(height: 24),

        // Annotations section (placeholder)
        _buildSection(
          context,
          'Annotations',
          [
            const Center(
              child: Text(
                'Annotations list coming soon',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the no selection state
  Widget _buildNoSelectionState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Image Selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an image to view its properties',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds a section with title and content
  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  /// Builds an information row
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the labels management widget
  Widget _buildLabelsManagement(BuildContext context) {
    final labelsAsync = ref.watch(projectLabelsNotifierProvider(widget.project.id));
    final selectedLabel = ref.watch(selectedLabelProvider);

    return Column(
      children: [
        // Header with add button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Labels',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: () => _showLabelDialog(context),
              icon: const Icon(Icons.add, size: 20),
              tooltip: 'Add Label',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Labels list
        SizedBox(
          height: 200,
          child: labelsAsync.isEmpty
              ? _buildEmptyLabelsState(context)
              : ListView.builder(
                  itemCount: labelsAsync.length,
                  itemBuilder: (context, index) {
                    final label = labelsAsync[index];
                    final isSelected = selectedLabel?.id == label.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: isSelected ? 2 : 0,
                      color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : null,
                      child: ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: label.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text(
                          label.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : null,
                          ),
                        ),
                        subtitle: label.shortcut != null
                            ? Text(
                                'Shortcut: ${label.shortcut}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${label.annotationCount}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            PopupMenuButton<String>(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'select',
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle, size: 16),
                                      SizedBox(width: 8),
                                      Text('Select'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 16),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                if (label.annotationCount == 0)
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, size: 16, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                              ],
                              onSelected: (value) => _handleLabelAction(context, label, value),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.more_vert, size: 16),
                            ),
                          ],
                        ),
                        onTap: () => _selectLabel(label),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Builds the empty labels state
  Widget _buildEmptyLabelsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.label_outline,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Labels',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create labels to categorize your annotations',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showLabelDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Label'),
          ),
        ],
      ),
    );
  }

  /// Shows the label creation/edit dialog
  Future<void> _showLabelDialog(BuildContext context, [Label? existingLabel]) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => LabelDialog(
        projectId: widget.project.id,
        existingLabel: existingLabel,
      ),
    );

    if (result == true) {
      // Refresh labels after creation/update
      ref.read(projectLabelsNotifierProvider(widget.project.id).notifier).refresh();
    }
  }

  /// Handles label actions from popup menu
  void _handleLabelAction(BuildContext context, Label label, String action) {
    switch (action) {
      case 'select':
        _selectLabel(label);
        break;
      case 'edit':
        _showLabelDialog(context, label);
        break;
      case 'delete':
        _showDeleteLabelDialog(context, label);
        break;
    }
  }

  /// Selects a label
  void _selectLabel(Label label) {
    ref.read(selectedLabelProvider.notifier).selectLabel(label);
  }

  /// Shows delete confirmation dialog
  Future<void> _showDeleteLabelDialog(BuildContext context, Label label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Label'),
        content: Text('Are you sure you want to delete "${label.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(projectLabelsNotifierProvider(widget.project.id).notifier).deleteLabel(label.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Label "${label.name}" deleted')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting label: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Formats file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
