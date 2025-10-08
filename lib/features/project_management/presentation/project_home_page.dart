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
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/project_providers.dart';
import '../../../core/models/project.dart';
import '../../image_annotation/presentation/annotation_workspace_page.dart';
import '../../settings/presentation/settings_page.dart';
import 'widgets/project_card.dart';
import 'widgets/new_project_dialog.dart';

/// Home page for project management
class ProjectHomePage extends ConsumerStatefulWidget {
  const ProjectHomePage({super.key});

  @override
  ConsumerState<ProjectHomePage> createState() => _ProjectHomePageState();
}

class _ProjectHomePageState extends ConsumerState<ProjectHomePage> {
  @override
  void initState() {
    super.initState();
    // Load recent projects on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectListProvider.notifier).loadProjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectListProvider);
    final isLoading = ref.watch(projectListProvider.notifier).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showNewProjectDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'New Project',
          ),
          IconButton(
            onPressed: () => _openProject(context),
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open Project',
          ),
          IconButton(
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to ${AppConstants.appName}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.appDescription,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Projects section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : projects.isEmpty
                ? _buildEmptyState(context)
                : _buildProjectsList(context, projects),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewProjectDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
    );
  }

  /// Builds the empty state when no projects exist
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            'No Projects Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first annotation project to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showNewProjectDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('New Project'),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: () => _openProject(context),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open Project'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the projects list
  Widget _buildProjectsList(BuildContext context, List<dynamic> projects) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Projects',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _openProject(context),
                icon: const Icon(Icons.folder_open),
                label: const Text('Open'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return ProjectCard(
                  project: project,
                  onTap: () => _openProject(context, project),
                  onDelete: () => _deleteProject(context, project),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Shows the new project dialog
  Future<void> _showNewProjectDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const NewProjectDialog(),
    );

    if (result == true) {
      // Refresh projects list
      ref.read(projectListProvider.notifier).loadProjects();
    }
  }

  /// Opens an existing project
  Future<void> _openProject(BuildContext context, [Project? project]) async {
    try {
      Project? projectToOpen = project;

      // If no project is provided, use file picker to select project directory
      if (projectToOpen == null) {
        final selectedDirectory = await FilePicker.platform.getDirectoryPath(
          dialogTitle: 'Select Project Directory',
        );

        if (selectedDirectory == null) {
          return; // User canceled
        }

        // Try to load project from directory
        projectToOpen = await ref.read(projectServiceProvider).getProjectFromDirectory(selectedDirectory);

        if (projectToOpen == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('No valid project found in selected directory'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
      }

      // Set the current project
      ref.read(currentProjectProvider.notifier).setProject(projectToOpen);

      // Import images if the project has images in the directory but not in database
      try {
        final existingImages = await ref.read(projectServiceProvider).getProjectImages(projectToOpen.id);
        if (existingImages.isEmpty) {
          // Try to import images from the images directory
          await ref.read(projectServiceProvider).importImages(projectToOpen.id, projectToOpen.imagesPath);
        }
      } catch (e) {
        print('Note: Could not auto-import images: $e');
        // Continue anyway - user can manually import later
      }

      if (context.mounted) {
        // Navigate to annotation workspace
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnnotationWorkspacePage(project: projectToOpen!),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Opens the settings page
  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }

  /// Deletes a project
  Future<void> _deleteProject(BuildContext context, dynamic project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text(
          'Are you sure you want to delete this project? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(projectServiceProvider).deleteProject(project.id);
        ref.read(projectListProvider.notifier).loadProjects();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project deleted successfully'),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting project: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
