// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

/// Enum representing the current state of the update process
enum UpdateStatus {
  /// No update check has been performed yet
  idle,

  /// Currently checking for available updates
  checking,

  /// An update is available for download
  available,

  /// Currently downloading the update
  downloading,

  /// Update has been downloaded and is ready to install
  downloaded,

  /// Currently installing the update
  installing,

  /// Update installation completed successfully
  installed,

  /// An error occurred during the update process
  error,

  /// No updates are available
  upToDate,
}

/// Extension methods for UpdateStatus enum
extension UpdateStatusExtension on UpdateStatus {
  /// Returns a human-readable description of the update status
  String get description {
    switch (this) {
      case UpdateStatus.idle:
        return 'Ready';
      case UpdateStatus.checking:
        return 'Checking for updates...';
      case UpdateStatus.available:
        return 'Update available';
      case UpdateStatus.downloading:
        return 'Downloading update...';
      case UpdateStatus.downloaded:
        return 'Update ready to install';
      case UpdateStatus.installing:
        return 'Installing update...';
      case UpdateStatus.installed:
        return 'Update installed successfully';
      case UpdateStatus.error:
        return 'Update failed';
      case UpdateStatus.upToDate:
        return 'Up to date';
    }
  }

  /// Returns true if the update process is currently active
  bool get isActive {
    return this == UpdateStatus.checking || this == UpdateStatus.downloading || this == UpdateStatus.installing;
  }

  /// Returns true if an error has occurred
  bool get hasError {
    return this == UpdateStatus.error;
  }

  /// Returns true if an update is available to download
  bool get canDownload {
    return this == UpdateStatus.available;
  }

  /// Returns true if an update is ready to install
  bool get canInstall {
    return this == UpdateStatus.downloaded;
  }
}
