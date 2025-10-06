// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

/// Application constants
class AppConstants {
  // App Information
  static const String appName = 'SenseLite';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Offline Image Annotation Tool';

  // File Extensions
  static const List<String> supportedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'bmp',
    'gif',
    'webp',
    'tiff',
    'tga',
  ];

  // Export Formats
  static const List<String> exportFormats = [
    'JSON',
    'COCO',
    'Pascal VOC',
  ];

  // Database
  static const String databaseName = 'senselite.db';
  static const int databaseVersion = 1;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Annotation Constants
  static const double minBoundingBoxSize = 10.0;
  static const double minPolygonArea = 25.0;
  static const int maxPolygonPoints = 100;
  static const int maxKeypointsPerAnnotation = 50;

  // Performance Limits
  static const int maxImagesPerProject = 10000;
  static const int maxAnnotationsPerImage = 1000;
  static const int defaultImageThumbnailSize = 150;

  // Theme Colors
  static const int primaryColor = 0xFF2196F3; // Blue

  // Colors
  static const List<int> defaultLabelColors = [
    0xFFFF5722, // Red
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
    0xFF00BCD4, // Cyan
    0xFFFFEB3B, // Yellow
    0xFFE91E63, // Pink
    0xFF795548, // Brown
    0xFF607D8B, // Blue Grey
  ];

  // Keyboard Shortcuts
  static const Map<String, String> defaultShortcuts = {
    'new_project': 'Ctrl+N',
    'open_project': 'Ctrl+O',
    'save_project': 'Ctrl+S',
    'export': 'Ctrl+E',
    'undo': 'Ctrl+Z',
    'redo': 'Ctrl+Y',
    'delete': 'Delete',
    'next_image': 'Right Arrow',
    'previous_image': 'Left Arrow',
    'zoom_in': 'Ctrl++',
    'zoom_out': 'Ctrl+-',
    'fit_to_screen': 'Ctrl+0',
  };

  // Settings Keys
  static const String settingsThemeMode = 'theme_mode';
  static const String settingsAutoSave = 'auto_save';
  static const String settingsShowGrid = 'show_grid';
  static const String settingsShowRuler = 'show_ruler';
  static const String settingsDefaultExportFormat = 'default_export_format';
  static const String settingsRecentProjects = 'recent_projects';

  // Project File Names
  static const String projectFileName = 'project.json';
  static const String annotationsFileName = 'annotations.json';
  static const String settingsFileName = 'settings.json';

  // Validation
  static const int maxProjectNameLength = 100;
  static const int maxLabelNameLength = 50;
  static const int maxDescriptionLength = 500;
  static const int maxNotesLength = 1000;
}
