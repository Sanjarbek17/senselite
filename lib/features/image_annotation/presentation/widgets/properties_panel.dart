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
import '../../../../core/models/annotation.dart';
import '../../../../core/providers/label_providers.dart';
import '../../../../core/providers/project_providers.dart';
import '../../../label_management/presentation/widgets/label_dialog.dart';
import '../../providers/annotation_providers.dart';

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
    // Load labels for the project and auto-select first label
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadAndSelectFirstLabel();
    });
  }

  @override
  void didUpdateWidget(PropertiesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the project changed, reload labels and select first one
    if (oldWidget.project.id != widget.project.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _loadAndSelectFirstLabel();
      });
    }
  }

  /// Loads labels for the current project and selects the first one
  Future<void> _loadAndSelectFirstLabel() async {
    // Clear any previously selected label first
    ref.read(selectedLabelProvider.notifier).clearSelection();

    // Load labels for the current project
    await ref.read(projectLabelsNotifierProvider(widget.project.id).notifier).loadLabels();

    // Always select the first label if available (regardless of previous selection)
    final labels = ref.read(projectLabelsNotifierProvider(widget.project.id));
    if (labels.isNotEmpty) {
      ref.read(selectedLabelProvider.notifier).selectLabel(labels.first);
    }
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
            child: widget.selectedImage != null
                ? _buildImageProperties(
                    context,
                  )
                : _buildNoSelectionState(
                    context,
                  ),
          ),
        ],
      ),
    );
  }

  /// Builds the properties display for selected image
  Widget _buildImageProperties(BuildContext context) {
    // final image = widget.selectedImage!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
            _buildAnnotationsManagement(context),
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

  /// Builds the annotations management widget
  Widget _buildAnnotationsManagement(BuildContext context) {
    if (widget.selectedImage == null) {
      return const Center(
        child: Text(
          'No image selected',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    final annotationsAsync = ref.watch(imageAnnotationsNotifierProvider(widget.selectedImage!.id));

    return Column(
      children: [
        // Header with count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'List (${widget.selectedImage!.annotationCount})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cleanup button for corrupted annotations
                IconButton(
                  onPressed: () => _cleanupCorruptedAnnotations(context),
                  icon: const Icon(Icons.cleaning_services, size: 16),
                  tooltip: 'Clean up corrupted annotations',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                if (widget.selectedImage!.annotationCount > 0)
                  TextButton.icon(
                    onPressed: () => _showDeleteAllAnnotationsDialog(context),
                    icon: const Icon(Icons.delete_sweep, size: 16),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Annotations list
        SizedBox(
          height: 200,
          child: annotationsAsync.when(
            data: (annotations) => annotations.isEmpty
                ? _buildEmptyAnnotationsState(context)
                : ListView.builder(
                    itemCount: annotations.length,
                    itemBuilder: (context, index) {
                      final annotation = annotations[index];
                      return _buildAnnotationCard(context, annotation, index + 1);
                    },
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading annotations',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the empty annotations state
  Widget _buildEmptyAnnotationsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notes_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Annotations',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start annotating this image to see annotations here',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Builds an annotation card
  Widget _buildAnnotationCard(BuildContext context, Annotation annotation, int index) {
    // Get label for this annotation - with null safety check
    final labelsAsync = ref.watch(projectLabelsNotifierProvider(widget.project.id));
    final labelId = annotation.labelId;

    // Handle case where labelId might be null or empty
    if (labelId.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$index',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
          title: Text(
            'Invalid Annotation',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                _getAnnotationTypeIcon(annotation.type),
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'No label assigned',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            itemBuilder: (context) => [
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
            onSelected: (value) => _handleAnnotationAction(context, annotation, value),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert, size: 16),
          ),
        ),
      );
    }

    final label = labelsAsync.firstWhere(
      (l) => l.id == labelId,
      orElse: () => Label(
        id: labelId,
        name: 'Unknown Label',
        color: Colors.grey,
        projectId: widget.project.id,
        createdAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$index',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: label.color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
        title: Text(
          label.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              _getAnnotationTypeIcon(annotation.type),
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _getAnnotationTypeLabel(annotation.type),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (annotation.notes != null && annotation.notes!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.note,
                size: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 16),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 16),
                  SizedBox(width: 8),
                  Text('Edit Notes'),
                ],
              ),
            ),
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
          onSelected: (value) => _handleAnnotationAction(context, annotation, value),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.more_vert, size: 16),
        ),
        onTap: () => _showAnnotationDetails(context, annotation, label),
      ),
    );
  }

  /// Gets the icon for annotation type
  IconData _getAnnotationTypeIcon(AnnotationType type) {
    switch (type) {
      case AnnotationType.boundingBox:
        return Icons.crop_free;
      case AnnotationType.polygon:
        return Icons.polyline;
      case AnnotationType.keypoint:
        return Icons.place;
    }
  }

  /// Gets the label for annotation type
  String _getAnnotationTypeLabel(AnnotationType type) {
    switch (type) {
      case AnnotationType.boundingBox:
        return 'Bounding Box';
      case AnnotationType.polygon:
        return 'Polygon';
      case AnnotationType.keypoint:
        return 'Keypoint';
    }
  }

  /// Handles annotation actions from popup menu
  void _handleAnnotationAction(BuildContext context, Annotation annotation, String action) {
    switch (action) {
      case 'view':
        final label = ref.read(projectLabelsNotifierProvider(widget.project.id)).firstWhere((l) => l.id == annotation.labelId);
        _showAnnotationDetails(context, annotation, label);
        break;
      case 'edit':
        _showEditAnnotationNotesDialog(context, annotation);
        break;
      case 'delete':
        _showDeleteAnnotationDialog(context, annotation);
        break;
    }
  }

  /// Shows annotation details dialog
  void _showAnnotationDetails(BuildContext context, Annotation annotation, Label label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: label.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text(label.name),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', _getAnnotationTypeLabel(annotation.type)),
              _buildDetailRow('Created', _formatDateTime(annotation.createdAt)),
              _buildDetailRow('Updated', _formatDateTime(annotation.updatedAt)),
              if (annotation.notes != null && annotation.notes!.isNotEmpty) _buildDetailRow('Notes', annotation.notes!),
              const SizedBox(height: 16),
              Text(
                'Coordinates:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildCoordinatesInfo(annotation),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditAnnotationLabelDialog(context, annotation);
            },
            child: const Text('Edit Label'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditAnnotationNotesDialog(context, annotation);
            },
            child: const Text('Edit Notes'),
          ),
        ],
      ),
    );
  }

  /// Builds a detail row for annotation details
  Widget _buildDetailRow(String label, String value) {
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

  /// Builds coordinates information based on annotation type
  Widget _buildCoordinatesInfo(Annotation annotation) {
    switch (annotation.type) {
      case AnnotationType.boundingBox:
        final bbox = annotation as BoundingBoxAnnotation;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('X: ${(bbox.x * 100).toStringAsFixed(1)}%'),
            Text('Y: ${(bbox.y * 100).toStringAsFixed(1)}%'),
            Text('Width: ${(bbox.width * 100).toStringAsFixed(1)}%'),
            Text('Height: ${(bbox.height * 100).toStringAsFixed(1)}%'),
          ],
        );
      case AnnotationType.polygon:
        final polygon = annotation as PolygonAnnotation;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Points: ${polygon.points.length}'),
            ...polygon.points.take(3).map((point) => Text('(${(point.x * 100).toStringAsFixed(1)}%, ${(point.y * 100).toStringAsFixed(1)}%)')),
            if (polygon.points.length > 3) Text('... and ${polygon.points.length - 3} more points'),
          ],
        );
      case AnnotationType.keypoint:
        final keypoints = annotation as KeypointAnnotation;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keypoints: ${keypoints.keypoints.length}'),
            ...keypoints.keypoints.take(3).map((kp) => Text('${kp.name}: (${(kp.point.x * 100).toStringAsFixed(1)}%, ${(kp.point.y * 100).toStringAsFixed(1)}%)')),
            if (keypoints.keypoints.length > 3) Text('... and ${keypoints.keypoints.length - 3} more keypoints'),
          ],
        );
    }
  }

  /// Shows edit annotation notes dialog
  void _showEditAnnotationNotesDialog(BuildContext context, Annotation annotation) {
    final notesController = TextEditingController(text: annotation.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Add notes for this annotation...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final notes = notesController.text.trim();
              Navigator.of(context).pop();

              try {
                Annotation updatedAnnotation;
                switch (annotation.type) {
                  case AnnotationType.boundingBox:
                    updatedAnnotation = (annotation as BoundingBoxAnnotation).copyWith(notes: notes.isEmpty ? null : notes);
                    break;
                  case AnnotationType.polygon:
                    updatedAnnotation = (annotation as PolygonAnnotation).copyWith(notes: notes.isEmpty ? null : notes);
                    break;
                  case AnnotationType.keypoint:
                    updatedAnnotation = (annotation as KeypointAnnotation).copyWith(notes: notes.isEmpty ? null : notes);
                    break;
                }

                await ref.read(imageAnnotationsNotifierProvider(widget.selectedImage!.id).notifier).updateAnnotation(updatedAnnotation);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notes updated successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error updating notes: ${e.toString()}'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Shows edit annotation label dialog
  Future<void> _showEditAnnotationLabelDialog(BuildContext context, Annotation annotation) async {
    final labels = ref.read(projectLabelsProvider(widget.project.id)).value ?? [];
    final currentLabel = labels.firstWhere((label) => label.id == annotation.labelId, orElse: () => labels.first);
    Label? selectedLabel = currentLabel;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select a new label for this annotation:',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children: labels.map((label) {
                      final isSelected = selectedLabel?.id == label.id;
                      return ListTile(
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: label.color,
                            borderRadius: BorderRadius.circular(4),
                            border: isSelected ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2) : null,
                          ),
                        ),
                        title: Text(label.name),
                        subtitle: label.description != null ? Text(label.description!) : null,
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            selectedLabel = label;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedLabel != null && selectedLabel!.id != annotation.labelId ? () => Navigator.of(context).pop(true) : null,
              child: const Text('Change Label'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedLabel != null && selectedLabel!.id != annotation.labelId) {
      try {
        Annotation updatedAnnotation;
        switch (annotation.type) {
          case AnnotationType.boundingBox:
            updatedAnnotation = (annotation as BoundingBoxAnnotation).copyWith(labelId: selectedLabel!.id);
            break;
          case AnnotationType.polygon:
            updatedAnnotation = (annotation as PolygonAnnotation).copyWith(labelId: selectedLabel!.id);
            break;
          case AnnotationType.keypoint:
            updatedAnnotation = (annotation as KeypointAnnotation).copyWith(labelId: selectedLabel!.id);
            break;
        }

        await ref.read(imageAnnotationsNotifierProvider(widget.selectedImage!.id).notifier).updateAnnotation(updatedAnnotation);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Label changed to "${selectedLabel!.name}"'),
              backgroundColor: selectedLabel!.color.withValues(alpha: 0.8),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating label: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Shows delete annotation confirmation dialog
  Future<void> _showDeleteAnnotationDialog(BuildContext context, Annotation annotation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Annotation'),
        content: const Text('Are you sure you want to delete this annotation? This action cannot be undone.'),
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
        await ref.read(imageAnnotationsNotifierProvider(widget.selectedImage!.id).notifier).removeAnnotation(annotation.id);

        // Refresh the project images provider to update annotation status in the image list
        ref.invalidate(projectImagesProvider(widget.project.id));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annotation deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting annotation: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Shows delete all annotations confirmation dialog
  Future<void> _showDeleteAllAnnotationsDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Annotations'),
        content: const Text('Are you sure you want to delete all annotations for this image? This action cannot be undone.'),
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
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final annotations = ref.read(imageAnnotationsNotifierProvider(widget.selectedImage!.id)).value ?? [];
        for (final annotation in annotations) {
          await ref.read(imageAnnotationsNotifierProvider(widget.selectedImage!.id).notifier).removeAnnotation(annotation.id);
        }

        // Refresh the project images provider to update annotation status in the image list
        ref.invalidate(projectImagesProvider(widget.project.id));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All annotations deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting annotations: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Formats DateTime to readable string
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Cleans up corrupted annotations
  Future<void> _cleanupCorruptedAnnotations(BuildContext context) async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      final deletedCount = await annotationService.cleanupCorruptedAnnotations();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleaned up $deletedCount corrupted annotations')),
        );

        // Refresh annotations list
        ref.read(imageAnnotationsNotifierProvider(widget.selectedImage!.id).notifier).refresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cleaning up annotations: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
