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
      state = AsyncValue.data(annotations);
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
