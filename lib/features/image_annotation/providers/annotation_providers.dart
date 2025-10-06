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
import '../../../core/models/annotation.dart';
import '../data/annotation_service.dart';

/// Provider for AnnotationService
final annotationServiceProvider = Provider<AnnotationService>((ref) {
  return AnnotationService();
});

/// Provider for image annotations
final imageAnnotationsProvider = FutureProvider.family<List<Annotation>, String>((ref, imageId) async {
  final annotationService = ref.watch(annotationServiceProvider);
  return await annotationService.getAnnotationsForImage(imageId);
});

/// Provider for project annotations
final projectAnnotationsProvider = FutureProvider.family<List<Annotation>, String>((ref, projectId) async {
  final annotationService = ref.watch(annotationServiceProvider);
  return await annotationService.getAnnotationsForProject(projectId);
});

/// State notifier for managing image annotations
class ImageAnnotationsNotifier extends StateNotifier<AsyncValue<List<Annotation>>> {
  final AnnotationService _annotationService;
  final String _imageId;

  ImageAnnotationsNotifier(this._annotationService, this._imageId) : super(const AsyncValue.loading()) {
    _loadAnnotations();
  }

  /// Load annotations for the image
  Future<void> _loadAnnotations() async {
    try {
      final annotations = await _annotationService.getAnnotationsForImage(_imageId);
      // Filter out any null or invalid annotations
      final validAnnotations = annotations.where((annotation) => annotation.id.isNotEmpty && annotation.labelId.isNotEmpty && annotation.imageId.isNotEmpty && annotation.projectId.isNotEmpty).toList();
      state = AsyncValue.data(validAnnotations);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Add a new annotation
  Future<void> addAnnotation(Annotation annotation) async {
    if (state.value == null) return;

    final currentAnnotations = state.value!;
    state = AsyncValue.data([...currentAnnotations, annotation]);
  }

  /// Update an existing annotation
  Future<void> updateAnnotation(Annotation annotation) async {
    if (state.value == null) return;

    final currentAnnotations = state.value!;
    final index = currentAnnotations.indexWhere((a) => a.id == annotation.id);
    if (index != -1) {
      final updatedAnnotations = [...currentAnnotations];
      updatedAnnotations[index] = annotation;
      state = AsyncValue.data(updatedAnnotations);

      await _annotationService.updateAnnotation(annotation);
    }
  }

  /// Remove an annotation
  Future<void> removeAnnotation(String annotationId) async {
    if (state.value == null) return;

    final currentAnnotations = state.value!;
    final updatedAnnotations = currentAnnotations.where((a) => a.id != annotationId).toList();
    state = AsyncValue.data(updatedAnnotations);

    await _annotationService.deleteAnnotation(annotationId, _imageId);
  }

  /// Refresh annotations from the database
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadAnnotations();
  }
}

/// Provider for image annotations notifier
final imageAnnotationsNotifierProvider = StateNotifierProvider.family<ImageAnnotationsNotifier, AsyncValue<List<Annotation>>, String>((ref, imageId) {
  final annotationService = ref.watch(annotationServiceProvider);
  return ImageAnnotationsNotifier(annotationService, imageId);
});

/// Available annotation tools
enum AnnotationTool {
  none,
  boundingBox,
  polygon,
  keypoint,
}

/// Represents a drawing state for annotations
class DrawingState {
  final AnnotationTool tool;
  final List<Offset> points;
  final bool isDrawing;

  const DrawingState({
    this.tool = AnnotationTool.none,
    this.points = const [],
    this.isDrawing = false,
  });

  DrawingState copyWith({
    AnnotationTool? tool,
    List<Offset>? points,
    bool? isDrawing,
  }) {
    return DrawingState(
      tool: tool ?? this.tool,
      points: points ?? this.points,
      isDrawing: isDrawing ?? this.isDrawing,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DrawingState && other.tool == tool && _listEquals(other.points, points) && other.isDrawing == isDrawing;
  }

  @override
  int get hashCode => tool.hashCode ^ points.hashCode ^ isDrawing.hashCode;

  /// Helper method to compare lists
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }
}

/// State notifier for managing drawing state
class DrawingStateNotifier extends StateNotifier<DrawingState> {
  DrawingStateNotifier() : super(const DrawingState());

  /// Select a tool
  void selectTool(AnnotationTool tool) {
    if (state.tool == tool) {
      // Deselect if same tool is clicked
      state = const DrawingState();
    } else {
      // Select new tool and clear any partial drawing
      state = state.copyWith(
        tool: tool,
        points: [],
        isDrawing: false,
      );
    }
  }

  /// Start drawing
  void startDrawing(Offset point) {
    if (state.tool == AnnotationTool.none) return;

    state = state.copyWith(
      points: [point],
      isDrawing: true,
    );
  }

  /// Update drawing
  void updateDrawing(Offset point) {
    if (!state.isDrawing || state.tool == AnnotationTool.none) return;

    switch (state.tool) {
      case AnnotationTool.boundingBox:
        // For bounding box, only keep start and current point
        state = state.copyWith(
          points: [state.points.first, point],
        );
        break;
      case AnnotationTool.polygon:
      case AnnotationTool.keypoint:
        // For polygon and keypoint, add all points
        state = state.copyWith(
          points: [...state.points, point],
        );
        break;
      case AnnotationTool.none:
        break;
    }
  }

  /// End drawing
  void endDrawing() {
    state = state.copyWith(
      points: [],
      isDrawing: false,
    );
  }

  /// Clear drawing state
  void clearDrawing() {
    state = state.copyWith(
      points: [],
      isDrawing: false,
    );
  }

  /// Reset all drawing state
  void reset() {
    state = const DrawingState();
  }
}

/// Provider for drawing state notifier
final drawingStateNotifierProvider = StateNotifierProvider<DrawingStateNotifier, DrawingState>((ref) {
  return DrawingStateNotifier();
});
