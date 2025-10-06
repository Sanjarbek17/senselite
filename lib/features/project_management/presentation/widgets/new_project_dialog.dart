// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/../).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/project_providers.dart';
import '../../../../core/providers/label_providers.dart';
import '../../../../core/models/label.dart';

/// Data class for holding label information during project creation
class _LabelData {
  final String name;
  final Color color;
  final String? shortcut;

  _LabelData({
    required this.name,
    required this.color,
    this.shortcut,
  });
}

/// Dialog for creating a new project
class NewProjectDialog extends ConsumerStatefulWidget {
  const NewProjectDialog({super.key});

  @override
  ConsumerState<NewProjectDialog> createState() => _NewProjectDialogState();
}

class _NewProjectDialogState extends ConsumerState<NewProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectPathController = TextEditingController();
  final _imagesPathController = TextEditingController();

  // Labels management
  final List<_LabelData> _labels = [];
  final _labelNameController = TextEditingController();
  Color _selectedLabelColor = Color(AppConstants.defaultLabelColors[0]);
  int? _selectedLabelIndex; // Track which label is selected

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _projectPathController.dispose();
    _imagesPathController.dispose();
    _labelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.create_new_folder,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Create New Project',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Project Name *',
                          hintText: 'Enter project name',
                          prefixIcon: Icon(Icons.label),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Project name is required';
                          }
                          if (value.trim().length > AppConstants.maxProjectNameLength) {
                            return 'Project name is too long';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter project description (optional)',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value != null && value.length > AppConstants.maxDescriptionLength) {
                            return 'Description is too long';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Project directory
                      TextFormField(
                        controller: _projectPathController,
                        decoration: InputDecoration(
                          labelText: 'Project Directory *',
                          hintText: 'Select project directory',
                          prefixIcon: const Icon(Icons.folder),
                          suffixIcon: IconButton(
                            onPressed: _selectProjectDirectory,
                            icon: const Icon(Icons.folder_open),
                          ),
                        ),
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Project directory is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Images directory
                      TextFormField(
                        controller: _imagesPathController,
                        decoration: InputDecoration(
                          labelText: 'Images Directory *',
                          hintText: 'Select images directory',
                          prefixIcon: const Icon(Icons.photo_library),
                          suffixIcon: IconButton(
                            onPressed: _selectImagesDirectory,
                            icon: const Icon(Icons.folder_open),
                          ),
                        ),
                        readOnly: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Images directory is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Labels section
                      _buildLabelsSection(),
                      const SizedBox(height: 24),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'A project file will be created in the project directory to store annotations and settings.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isLoading ? null : _createProject,
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create Project'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Selects the project directory
  Future<void> _selectProjectDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Project Directory',
      );

      if (result != null) {
        _projectPathController.text = result;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting directory: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Selects the images directory
  Future<void> _selectImagesDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select Images Directory',
      );

      if (result != null) {
        _imagesPathController.text = result;

        // If project directory is not set, suggest a subdirectory
        if (_projectPathController.text.isEmpty) {
          final suggestedProjectPath = Directory(result).parent.path;
          _projectPathController.text = suggestedProjectPath;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting directory: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Creates the project
  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create the project first
      final project = await ref
          .read(projectServiceProvider)
          .createProject(
            name: _nameController.text.trim(),
            projectPath: _projectPathController.text.trim(),
            imagesPath: _imagesPathController.text.trim(),
            description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
          );

      // Create the labels for the project
      if (_labels.isNotEmpty) {
        final labelService = ref.read(labelServiceProvider);
        Label? selectedLabel;

        for (int i = 0; i < _labels.length; i++) {
          final labelData = _labels[i];
          final label = await labelService.createLabel(
            name: labelData.name,
            color: labelData.color,
            projectId: project.id,
            shortcut: labelData.shortcut,
          );

          // Store the selected label to set as default
          if (_selectedLabelIndex == i) {
            selectedLabel = label;
          }

          // If no label was explicitly selected, use the first one
          if (selectedLabel == null && i == 0) {
            selectedLabel = label;
          }
        }

        // Select the chosen label as default
        if (selectedLabel != null) {
          ref.read(selectedLabelProvider.notifier).selectLabel(selectedLabel);
        }
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project created successfully!'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating project: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Builds the labels section
  Widget _buildLabelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(
              Icons.label_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Initial Labels',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _addLabel,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Label'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Description
        Text(
          'Add labels that you\'ll use to categorize your annotations. Click on a label to select it as the default for annotation. You can always add more labels later.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Labels list
        if (_labels.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No labels added yet. Add at least one label to get started with annotation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: _labels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              return _buildLabelItem(label, index);
            }).toList(),
          ),
      ],
    );
  }

  /// Builds a single label item
  Widget _buildLabelItem(_LabelData label, int index) {
    final isSelected = _selectedLabelIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLabelIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3) : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            if (isSelected) ...[
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
            ],

            // Color indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: label.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),

            // Label info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              label.name,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Selected',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (label.shortcut != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Shortcut: ${label.shortcut}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              onPressed: () => _removeLabel(index),
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Remove Label',
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the add label dialog
  void _addLabel() {
    _labelNameController.clear();
    _selectedLabelColor = Color(AppConstants.defaultLabelColors[_labels.length % AppConstants.defaultLabelColors.length]);

    showDialog<bool>(
      context: context,
      builder: (context) => _AddLabelDialog(
        nameController: _labelNameController,
        selectedColor: _selectedLabelColor,
        onColorChanged: (color) => _selectedLabelColor = color,
        existingLabels: _labels,
      ),
    ).then((result) {
      if (result == true) {
        final name = _labelNameController.text.trim();
        if (name.isNotEmpty) {
          setState(() {
            _labels.add(
              _LabelData(
                name: name,
                color: _selectedLabelColor,
                shortcut: (_labels.length + 1).toString(),
              ),
            );
            // Automatically select the newly created label
            _selectedLabelIndex = _labels.length - 1;
          });
        }
      }
    });
  }

  /// Removes a label at the given index
  void _removeLabel(int index) {
    setState(() {
      _labels.removeAt(index);

      // Update selection
      if (_selectedLabelIndex == index) {
        // If we removed the selected label, select the first remaining label
        _selectedLabelIndex = _labels.isNotEmpty ? 0 : null;
      } else if (_selectedLabelIndex != null && _selectedLabelIndex! > index) {
        // Adjust selection index if a label before the selected one was removed
        _selectedLabelIndex = _selectedLabelIndex! - 1;
      }

      // Update shortcuts for remaining labels
      for (int i = 0; i < _labels.length; i++) {
        final oldLabel = _labels[i];
        _labels[i] = _LabelData(
          name: oldLabel.name,
          color: oldLabel.color,
          shortcut: (i + 1).toString(),
        );
      }
    });
  }
}

/// Dialog for adding a new label during project creation
class _AddLabelDialog extends StatefulWidget {
  final TextEditingController nameController;
  final Color selectedColor;
  final Function(Color) onColorChanged;
  final List<_LabelData> existingLabels;

  const _AddLabelDialog({
    required this.nameController,
    required this.selectedColor,
    required this.onColorChanged,
    required this.existingLabels,
  });

  @override
  State<_AddLabelDialog> createState() => _AddLabelDialogState();
}

class _AddLabelDialogState extends State<_AddLabelDialog> {
  final _formKey = GlobalKey<FormState>();
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Label'),
      content: SizedBox(
        width: 300,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: widget.nameController,
                decoration: const InputDecoration(
                  labelText: 'Label Name *',
                  hintText: 'e.g., Person, Car, Object',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Label name is required';
                  }
                  if (value.trim().length > AppConstants.maxLabelNameLength) {
                    return 'Label name is too long';
                  }
                  // Check for duplicate names
                  final existingNames = widget.existingLabels.map((l) => l.name.toLowerCase()).toList();
                  if (existingNames.contains(value.trim().toLowerCase())) {
                    return 'A label with this name already exists';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: 16),

              // Color selection
              Text(
                'Color',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AppConstants.defaultLabelColors.map((colorValue) {
                  final color = Color(colorValue);
                  final isSelected = _currentColor.value == color.value;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _currentColor = color;
                      });
                      widget.onColorChanged(color);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 3,
                              )
                            : Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check,
                              color: _getContrastColor(color),
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Add Label'),
        ),
      ],
    );
  }

  /// Gets contrasting color for text on the given background
  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
