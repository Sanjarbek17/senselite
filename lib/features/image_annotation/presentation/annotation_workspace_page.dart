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
import 'package:file_picker/file_picker.dart';
import '../../../core/models/project.dart';
import '../../../core/models/image_item.dart';
import '../../../core/providers/project_providers.dart';
import 'widgets/image_list_panel.dart';
import 'widgets/annotation_canvas.dart';
import 'widgets/properties_panel.dart';

/// Main annotation workspace page where users annotate images
class AnnotationWorkspacePage extends ConsumerStatefulWidget {
  /// The project to work on
  final Project project;

  /// Creates a new AnnotationWorkspacePage widget
  const AnnotationWorkspacePage({
    super.key,
    required this.project,
  });

  @override
  ConsumerState<AnnotationWorkspacePage> createState() => _AnnotationWorkspacePageState();
}

class _AnnotationWorkspacePageState extends ConsumerState<AnnotationWorkspacePage> {
  ImageItem? _selectedImage;
  bool _isLeftPanelExpanded = true;
  bool _isRightPanelExpanded = true;

  @override
  void initState() {
    super.initState();
    // Set the current project in the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentProjectProvider.notifier).setProject(widget.project);
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectImages = ref.watch(projectImagesProvider(widget.project.id));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project.name} - Annotation Workspace'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Import images button
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: () => _importImages(context),
            tooltip: 'Import Images',
          ),
          const VerticalDivider(),
          // Toggle left panel
          IconButton(
            icon: Icon(_isLeftPanelExpanded ? Icons.first_page : Icons.last_page),
            onPressed: () {
              setState(() {
                _isLeftPanelExpanded = !_isLeftPanelExpanded;
              });
            },
            tooltip: _isLeftPanelExpanded ? 'Hide Image List' : 'Show Image List',
          ),
          // Toggle right panel
          IconButton(
            icon: Icon(_isRightPanelExpanded ? Icons.last_page : Icons.first_page),
            onPressed: () {
              setState(() {
                _isRightPanelExpanded = !_isRightPanelExpanded;
              });
            },
            tooltip: _isRightPanelExpanded ? 'Hide Properties' : 'Show Properties',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          // Left panel - Image list
          if (_isLeftPanelExpanded)
            SizedBox(
              width: 300,
              child: projectImages.when(
                data: (images) => ImageListPanel(
                  images: images,
                  selectedImage: _selectedImage,
                  onImageSelected: (image) {
                    setState(() {
                      _selectedImage = image;
                    });
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading images: $error'),
                    ],
                  ),
                ),
              ),
            ),

          // Main content - Annotation canvas
          Expanded(
            child: _selectedImage != null
                ? AnnotationCanvas(
                    imageItem: _selectedImage!,
                    project: widget.project,
                  )
                : _buildSelectImagePrompt(),
          ),

          // Right panel - Properties and tools
          if (_isRightPanelExpanded)
            SizedBox(
              width: 300,
              child: PropertiesPanel(
                project: widget.project,
                selectedImage: _selectedImage,
              ),
            ),
        ],
      ),
    );
  }

  /// Builds the prompt when no image is selected
  Widget _buildSelectImagePrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'Select an Image to Annotate',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an image from the list on the left to start annotating',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Imports images from a directory
  Future<void> _importImages(BuildContext context) async {
    try {
      final selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Images Directory',
      );

      if (selectedDirectory == null) {
        return; // User canceled
      }

      if (context.mounted) {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Importing images...'),
              ],
            ),
          ),
        );

        try {
          await ref.read(projectServiceProvider).importImages(widget.project.id, selectedDirectory);

          if (context.mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Images imported successfully!'),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error importing images: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting directory: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
