// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/update_info.dart';
import '../models/update_status.dart';
import '../services/update_service.dart';

/// State class for managing update-related information
class UpdateState {
  /// Current status of the update process
  final UpdateStatus status;

  /// Information about the available update, if any
  final UpdateInfo? updateInfo;

  /// Current download progress (0.0 to 1.0)
  final double downloadProgress;

  /// Error message if an error occurred
  final String? errorMessage;

  /// Path to the downloaded update file
  final String? downloadedFilePath;

  /// Whether auto-update checking is enabled
  final bool autoCheckEnabled;

  /// Update check interval in hours
  final int checkIntervalHours;

  /// Timestamp of the last update check
  final DateTime? lastCheckTime;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.updateInfo,
    this.downloadProgress = 0.0,
    this.errorMessage,
    this.downloadedFilePath,
    this.autoCheckEnabled = true,
    this.checkIntervalHours = 24,
    this.lastCheckTime,
  });

  /// Creates a copy of this state with the specified fields replaced
  UpdateState copyWith({
    UpdateStatus? status,
    UpdateInfo? updateInfo,
    double? downloadProgress,
    String? errorMessage,
    String? downloadedFilePath,
    bool? autoCheckEnabled,
    int? checkIntervalHours,
    DateTime? lastCheckTime,
  }) {
    return UpdateState(
      status: status ?? this.status,
      updateInfo: updateInfo ?? this.updateInfo,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedFilePath: downloadedFilePath ?? this.downloadedFilePath,
      autoCheckEnabled: autoCheckEnabled ?? this.autoCheckEnabled,
      checkIntervalHours: checkIntervalHours ?? this.checkIntervalHours,
      lastCheckTime: lastCheckTime ?? this.lastCheckTime,
    );
  }

  /// Clears error state
  UpdateState clearError() {
    return copyWith(
      status: UpdateStatus.idle,
      errorMessage: null,
    );
  }

  /// Sets error state
  UpdateState setError(String message) {
    return copyWith(
      status: UpdateStatus.error,
      errorMessage: message,
    );
  }

  @override
  String toString() {
    return 'UpdateState(status: $status, updateInfo: $updateInfo, '
        'downloadProgress: $downloadProgress, errorMessage: $errorMessage)';
  }
}

/// Provider for the UpdateService instance
final updateServiceProvider = Provider<UpdateService>((ref) {
  final service = UpdateService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// StateNotifier for managing update state and operations
class UpdateNotifier extends StateNotifier<UpdateState> {
  final UpdateService _updateService;

  UpdateNotifier(this._updateService) : super(const UpdateState()) {
    _loadConfiguration();
  }

  /// Loads the current update configuration from preferences
  Future<void> _loadConfiguration() async {
    try {
      final config = await _updateService.getAutoUpdateConfig();
      state = state.copyWith(
        autoCheckEnabled: config['enabled'] as bool,
        checkIntervalHours: config['intervalHours'] as int,
        lastCheckTime: config['lastCheck'] != null ? DateTime.fromMillisecondsSinceEpoch(config['lastCheck'] as int) : null,
      );
    } catch (e) {
      // Ignore configuration loading errors
    }
  }

  /// Checks for available updates
  Future<void> checkForUpdates({bool forceCheck = false}) async {
    if (state.status.isActive) return;

    state = state.copyWith(
      status: UpdateStatus.checking,
      errorMessage: null,
    );

    try {
      final updateInfo = await _updateService.checkForUpdates(
        forceCheck: forceCheck,
      );

      if (updateInfo != null) {
        state = state.copyWith(
          status: UpdateStatus.available,
          updateInfo: updateInfo,
          lastCheckTime: DateTime.now(),
        );
      } else {
        state = state.copyWith(
          status: UpdateStatus.upToDate,
          lastCheckTime: DateTime.now(),
        );
      }
    } catch (e) {
      state = state.setError('Failed to check for updates: $e');
    }
  }

  /// Downloads the available update
  Future<void> downloadUpdate() async {
    if (state.updateInfo == null || state.status != UpdateStatus.available) {
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.downloading,
      downloadProgress: 0.0,
      errorMessage: null,
    );

    try {
      final filePath = await _updateService.downloadUpdate(
        state.updateInfo!,
        onProgress: (progress) {
          state = state.copyWith(downloadProgress: progress);
        },
      );

      state = state.copyWith(
        status: UpdateStatus.downloaded,
        downloadedFilePath: filePath,
        downloadProgress: 1.0,
      );
    } catch (e) {
      state = state.setError('Failed to download update: $e');
    }
  }

  /// Installs the downloaded update
  Future<void> installUpdate({bool closeCurrentApp = true}) async {
    if (state.downloadedFilePath == null || state.status != UpdateStatus.downloaded) {
      return;
    }

    state = state.copyWith(
      status: UpdateStatus.installing,
      errorMessage: null,
    );

    try {
      final success = await _updateService.installUpdate(
        state.downloadedFilePath!,
        closeCurrentApp: closeCurrentApp,
      );

      if (success) {
        state = state.copyWith(status: UpdateStatus.installed);
      } else {
        state = state.setError('Failed to launch installer');
      }
    } catch (e) {
      state = state.setError('Failed to install update: $e');
    }
  }

  /// Configures automatic update settings
  Future<void> setAutoUpdateConfig({
    required bool enabled,
    int? checkIntervalHours,
    String? updateUrl,
  }) async {
    try {
      await _updateService.setAutoUpdateConfig(
        enabled: enabled,
        checkIntervalHours: checkIntervalHours ?? state.checkIntervalHours,
        updateUrl: updateUrl,
      );

      state = state.copyWith(
        autoCheckEnabled: enabled,
        checkIntervalHours: checkIntervalHours ?? state.checkIntervalHours,
      );
    } catch (e) {
      state = state.setError('Failed to update configuration: $e');
    }
  }

  /// Skips the current update (user dismissed it)
  void skipUpdate() {
    state = state.copyWith(
      status: UpdateStatus.idle,
      updateInfo: null,
      downloadProgress: 0.0,
      downloadedFilePath: null,
      errorMessage: null,
    );
  }

  /// Clears the current error state
  void clearError() {
    state = state.clearError();
  }

  /// Cleans up old update files
  Future<void> cleanupOldUpdates() async {
    try {
      await _updateService.cleanupOldUpdates();
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Performs automatic update check if conditions are met
  Future<void> performAutoUpdateCheck() async {
    if (state.autoCheckEnabled && !state.status.isActive) {
      await checkForUpdates();
    }
  }
}

/// Provider for the UpdateNotifier
final updateNotifierProvider = StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  final updateService = ref.watch(updateServiceProvider);
  return UpdateNotifier(updateService);
});
