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
import 'widgets/update_settings_card.dart';

/// Settings page for application configuration
class SettingsPage extends StatelessWidget {
  /// Creates a SettingsPage widget
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // Update Settings Section
            UpdateSettingsCard(),

            SizedBox(height: 16),

            // Future: Add more settings sections here
            // ApplicationSettingsCard(),
            // ThemeSettingsCard(),
            // etc.
          ],
        ),
      ),
    );
  }
}
