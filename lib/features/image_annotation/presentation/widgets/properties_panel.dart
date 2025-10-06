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
import '../../../../core/models/image_item.dart';
import '../../../../core/models/project.dart';

/// Widget for displaying properties and annotation tools
class PropertiesPanel extends StatelessWidget {
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
            child: selectedImage != null ? _buildImageProperties(context) : _buildNoSelectionState(context),
          ),
        ],
      ),
    );
  }

  /// Builds the properties display for selected image
  Widget _buildImageProperties(BuildContext context) {
    final image = selectedImage!;

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

        // Labels section (placeholder)
        _buildSection(
          context,
          'Labels',
          [
            const Center(
              child: Text(
                'Labels management coming soon',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
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

  /// Formats file size in human readable format
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
