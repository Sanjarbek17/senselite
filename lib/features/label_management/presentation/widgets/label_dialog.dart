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
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/label.dart';
import '../../../../core/providers/label_providers.dart';
import '../../../../core/constants/app_constants.dart';

/// Dialog for creating or editing a label
class LabelDialog extends ConsumerStatefulWidget {
  /// The project ID
  final String projectId;

  /// The label to edit (null for creating new label)
  final Label? existingLabel;

  /// Creates a new LabelDialog
  const LabelDialog({
    super.key,
    required this.projectId,
    this.existingLabel,
  });

  @override
  ConsumerState<LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends ConsumerState<LabelDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _shortcutController = TextEditingController();

  Color _selectedColor = Color(AppConstants.defaultLabelColors[0]);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingLabel != null) {
      _nameController.text = widget.existingLabel!.name;
      _descriptionController.text = widget.existingLabel!.description ?? '';
      _shortcutController.text = widget.existingLabel!.shortcut ?? '';
      _selectedColor = widget.existingLabel!.color;
    } else {
      _loadNextAvailableShortcut();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _shortcutController.dispose();
    super.dispose();
  }

  Future<void> _loadNextAvailableShortcut() async {
    if (widget.existingLabel != null) return;

    try {
      final notifier = ref.read(projectLabelsNotifierProvider(widget.projectId).notifier);
      final shortcut = await notifier.getNextAvailableShortcut();
      if (shortcut != null && mounted) {
        _shortcutController.text = shortcut;
      }
    } catch (e) {
      // Ignore error
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingLabel != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Label' : 'New Label'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  hintText: 'e.g., Person, Car, Building',
                  border: OutlineInputBorder(),
                ),
                maxLength: AppConstants.maxLabelNameLength,
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                  border: OutlineInputBorder(),
                ),
                maxLength: AppConstants.maxDescriptionLength,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

              // Shortcut field
              TextFormField(
                controller: _shortcutController,
                decoration: const InputDecoration(
                  labelText: 'Keyboard Shortcut',
                  hintText: '1-9 or letter',
                  border: OutlineInputBorder(),
                ),
                maxLength: 1,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9a-zA-Z]')),
                ],
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!RegExp(r'^[0-9a-zA-Z]$').hasMatch(value)) {
                      return 'Use numbers 0-9 or letters a-z';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Color selection
              Text(
                'Color',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildColorSelector(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveLabel,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.defaultLabelColors.map((colorValue) {
        final color = Color(colorValue);
        final isSelected = _selectedColor.value == color.value;

        return GestureDetector(
          onTap: () => setState(() => _selectedColor = color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                width: 3,
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
    );
  }

  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Future<void> _saveLabel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(projectLabelsNotifierProvider(widget.projectId).notifier);
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final shortcut = _shortcutController.text.trim();

      if (widget.existingLabel != null) {
        // Update existing label
        final updatedLabel = widget.existingLabel!.copyWith(
          name: name,
          description: description.isEmpty ? null : description,
          shortcut: shortcut.isEmpty ? null : shortcut,
          color: _selectedColor,
        );
        await notifier.updateLabel(updatedLabel);
      } else {
        // Create new label
        await notifier.addLabel(
          name: name,
          color: _selectedColor,
          description: description.isEmpty ? null : description,
          shortcut: shortcut.isEmpty ? null : shortcut,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
