// Copilot Instruction:
// - Follow Effective Dart guidelines.
// - Use feature-first folder structure (lib/features/<feature>/...).
// - Place UI in presentation/, data access in data/.
// - Write DartDoc comments for public classes and methods.
// - Prefer stateless widgets when possible.
// - Use provider for state management.
// - Write unit and widget tests for each feature.
// - Handle errors gracefully and validate inputs.

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/image_item.dart';
import '../../../../core/models/project.dart';
import '../../../../core/providers/label_providers.dart';
import '../../providers/annotation_providers.dart';

/// Represents a completed annotation on the canvas
class CanvasAnnotation {
  final String id;
  final AnnotationTool tool;
  final List<Offset> points;
  final bool isSelected;

  const CanvasAnnotation({
    required this.id,
    required this.tool,
    required this.points,
    this.isSelected = false,
  });

  CanvasAnnotation copyWith({
    String? id,
    AnnotationTool? tool,
    List<Offset>? points,
    bool? isSelected,
  }) {
    return CanvasAnnotation(
      id: id ?? this.id,
      tool: tool ?? this.tool,
      points: points ?? this.points,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Get the bounding rectangle for this annotation
  Rect get boundingRect {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final point in points) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

/// Widget for displaying and annotating images
class AnnotationCanvas extends ConsumerStatefulWidget {
  /// The image to display and annotate
  final ImageItem imageItem;

  /// The project this image belongs to
  final Project project;

  /// Creates a new AnnotationCanvas widget
  const AnnotationCanvas({
    super.key,
    required this.imageItem,
    required this.project,
  });

  @override
  ConsumerState<AnnotationCanvas> createState() => _AnnotationCanvasState();
}

class _AnnotationCanvasState extends ConsumerState<AnnotationCanvas> {
  /// Stores all completed annotations drawn on the canvas
  final List<CanvasAnnotation> _annotations = [];

  /// The currently selected annotation on the canvas, if any
  CanvasAnnotation? _selectedAnnotation;
  final GlobalKey _imageKey = GlobalKey();
  Size _imageSize = Size.zero;

  @override
  void initState() {
    super.initState();
    debugPrint('AnnotationCanvas initState for image: ${widget.imageItem.id}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingAnnotations();
    });
  }

  @override
  void didUpdateWidget(AnnotationCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if the image has changed
    if (oldWidget.imageItem.id != widget.imageItem.id) {
      debugPrint('AnnotationCanvas image changed from ${oldWidget.imageItem.id} to ${widget.imageItem.id}');
      // Reset the canvas state for the new image
      _resetCanvasForNewImage();

      // Load annotations for the new image
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadExistingAnnotations();
      });
    }
  }

  @override
  void dispose() {
    debugPrint('AnnotationCanvas dispose for image: ${widget.imageItem.id}');
    // Clear any pending operations and state
    _annotations.clear();
    _selectedAnnotation = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        border: Border.symmetric(
          vertical: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.imageItem.filename,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                // Selected label indicator
                _buildSelectedLabelIndicator(),
                const Spacer(),
                // Annotation tools
                _buildToolButton(
                  icon: Icons.crop_free,
                  tool: AnnotationTool.boundingBox,
                  tooltip: 'Bounding Box',
                ),
                _buildToolButton(
                  icon: Icons.timeline,
                  tool: AnnotationTool.polygon,
                  tooltip: 'Polygon',
                ),
                _buildToolButton(
                  icon: Icons.scatter_plot,
                  tool: AnnotationTool.keypoint,
                  tooltip: 'Keypoints',
                ),
                const VerticalDivider(),
                // Clear tool
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    final drawingState = ref.read(drawingStateNotifierProvider);
                    if (drawingState.tool != AnnotationTool.none) {
                      ref.read(drawingStateNotifierProvider.notifier).selectTool(AnnotationTool.none);
                      // Clear selected annotation when clearing tool
                      setState(() {
                        _selectedAnnotation = null;
                      });
                    }
                  },
                  tooltip: 'Clear Tool',
                ),
              ],
            ),
          ),

          // Canvas area
          Expanded(
            child: Center(
              child: _buildInteractiveImageDisplay(),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the selected label indicator
  Widget _buildSelectedLabelIndicator() {
    final selectedLabel = ref.watch(selectedLabelProvider);

    if (selectedLabel == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 4),
            Text(
              'No Label Selected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selectedLabel.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedLabel.color.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: selectedLabel.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            selectedLabel.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (selectedLabel.shortcut != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${selectedLabel.shortcut})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a tool button with selection state
  Widget _buildToolButton({
    required IconData icon,
    required AnnotationTool tool,
    required String tooltip,
  }) {
    final drawingState = ref.watch(drawingStateNotifierProvider);
    final isSelected = drawingState.tool == tool;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : null,
        ),
        onPressed: () {
          ref.read(drawingStateNotifierProvider.notifier).selectTool(tool);
          // Clear selected annotation when switching tools
          setState(() {
            _selectedAnnotation = null;
          });
        },
        tooltip: tooltip,
      ),
    );
  }

  /// Builds the interactive image display with drawing capabilities
  Widget _buildInteractiveImageDisplay() {
    final imageFile = File(widget.imageItem.filePath);

    if (!imageFile.existsSync()) {
      return _buildErrorState('Image not found', 'The image file could not be found at:\n${widget.imageItem.filePath}');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Image
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  key: _imageKey,
                  fit: BoxFit.contain,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (frame != null) {
                      _updateImageSize();
                    }
                    return child;
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorState('Error loading image', error.toString());
                  },
                ),
              ),
            ),
            // Annotation overlay - always visible for existing annotations
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(16),
                child: GestureDetector(
                  onPanStart: _onPanStart,
                  onPanUpdate: _onPanUpdate,
                  onPanEnd: _onPanEnd,
                  child: CustomPaint(
                    painter: DrawingPainter(
                      drawingState: ref.watch(drawingStateNotifierProvider),
                      annotations: _annotations,
                      selectedAnnotation: _selectedAnnotation,
                      imageSize: _imageSize,
                      isToolSelected: ref.watch(drawingStateNotifierProvider).tool != AnnotationTool.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Builds error state widget
  Widget _buildErrorState(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Handles pan start for drawing
  void _onPanStart(DragStartDetails details) {
    // Check if clicking on an existing annotation for selection
    final clickedAnnotation = _getAnnotationAtPoint(details.localPosition);

    if (clickedAnnotation != null) {
      // Select the annotation
      setState(() {
        _selectedAnnotation = clickedAnnotation;
      });
      // Clear any current drawing
      ref.read(drawingStateNotifierProvider.notifier).clearDrawing();
      return;
    }

    // Clear selection if clicking elsewhere
    if (_selectedAnnotation != null) {
      setState(() {
        _selectedAnnotation = null;
      });
    }

    // Start drawing only if a tool is selected
    final drawingState = ref.read(drawingStateNotifierProvider);
    if (drawingState.tool == AnnotationTool.none) return;

    ref.read(drawingStateNotifierProvider.notifier).startDrawing(details.localPosition);
  }

  /// Handles pan update for drawing
  void _onPanUpdate(DragUpdateDetails details) {
    ref.read(drawingStateNotifierProvider.notifier).updateDrawing(details.localPosition);
  }

  /// Handles pan end for drawing
  void _onPanEnd(DragEndDetails details) {
    final drawingState = ref.read(drawingStateNotifierProvider);

    if (!drawingState.isDrawing || drawingState.tool == AnnotationTool.none || drawingState.points.length < 2) {
      ref.read(drawingStateNotifierProvider.notifier).endDrawing();
      return;
    }

    // Create annotation from drawing
    _createAnnotationFromDrawing();

    ref.read(drawingStateNotifierProvider.notifier).endDrawing();
  }

  /// Creates an annotation from the current drawing state
  void _createAnnotationFromDrawing() {
    final drawingState = ref.read(drawingStateNotifierProvider);

    if (drawingState.points.length < 2) return;

    // Check if a label is selected
    final selectedLabel = ref.read(selectedLabelProvider);
    if (selectedLabel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a label before creating annotations'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Select Label',
            textColor: Colors.white,
            onPressed: () {
              // Focus could be brought to properties panel here
            },
          ),
        ),
      );
      return;
    }

    // Create a new annotation
    final annotation = CanvasAnnotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tool: drawingState.tool,
      points: List.from(drawingState.points),
    );

    setState(() {
      _annotations.add(annotation);
      _selectedAnnotation = annotation;
    });

    // Show success message with label information
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${drawingState.tool.name} annotation created with label "${selectedLabel.name}"!'),
        duration: const Duration(seconds: 2),
        backgroundColor: selectedLabel.color.withOpacity(0.8),
      ),
    );

    // Save annotation to database with selected label
    _saveAnnotationToDatabase(annotation, selectedLabel);
  }

  /// Finds annotation at the given point
  CanvasAnnotation? _getAnnotationAtPoint(Offset point) {
    for (final annotation in _annotations.reversed) {
      if (_isPointInAnnotation(point, annotation)) {
        return annotation;
      }
    }
    return null;
  }

  /// Checks if a point is inside an annotation
  bool _isPointInAnnotation(Offset point, CanvasAnnotation annotation) {
    switch (annotation.tool) {
      case AnnotationTool.boundingBox:
        if (annotation.points.length >= 2) {
          final rect = Rect.fromPoints(annotation.points[0], annotation.points[1]);
          return rect.contains(point);
        }
        break;
      case AnnotationTool.polygon:
        // Simple polygon point-in-polygon test
        return _pointInPolygon(point, annotation.points);
      case AnnotationTool.keypoint:
        // Check if point is near any keypoint
        for (final kp in annotation.points) {
          if ((kp - point).distance < 10) return true;
        }
        break;
      case AnnotationTool.none:
        break;
    }
    return false;
  }

  /// Point-in-polygon test using ray casting algorithm
  bool _pointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i].dx;
      final yi = polygon[i].dy;
      final xj = polygon[j].dx;
      final yj = polygon[j].dy;

      if (((yi > point.dy) != (yj > point.dy)) && (point.dx < (xj - xi) * (point.dy - yi) / (yj - yi) + xi)) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// Resets the canvas state when switching to a new image
  void _resetCanvasForNewImage() {
    // Reset drawing state using provider
    ref.read(drawingStateNotifierProvider.notifier).reset();

    setState(() {
      // Clear existing annotations from the previous image
      _annotations.clear();

      // Clear selected annotation
      _selectedAnnotation = null;

      // Reset image size (will be recalculated for new image)
      _imageSize = Size.zero;
    });

    // Show a subtle indication that the canvas has been reset for the new image
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Loaded image: ${widget.imageItem.filename}'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        ),
      );
    }
  }

  /// Loads existing annotations from the database for this image
  Future<void> _loadExistingAnnotations() async {
    try {
      final annotationService = ref.read(annotationServiceProvider);
      final annotations = await annotationService.getAnnotationsForImage(widget.imageItem.id);

      if (mounted) {
        setState(() {
          _annotations.clear();
          for (final annotation in annotations) {
            // Convert database annotation to canvas annotation
            final canvasAnnotation = annotationService.convertToCanvasAnnotation(annotation, _imageSize);
            _annotations.add(canvasAnnotation);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading annotations: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Saves a canvas annotation to the database
  Future<void> _saveAnnotationToDatabase(CanvasAnnotation canvasAnnotation, selectedLabel) async {
    try {
      final annotationService = ref.read(annotationServiceProvider);

      if (_imageSize == Size.zero) {
        // Try to get image size from the widget
        final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          _imageSize = renderBox.size;
        } else {
          // Fallback to image item dimensions
          _imageSize = Size(widget.imageItem.width.toDouble(), widget.imageItem.height.toDouble());
        }
      }

      await annotationService.createAnnotation(
        imageId: widget.imageItem.id,
        projectId: widget.project.id,
        label: selectedLabel,
        tool: canvasAnnotation.tool,
        canvasPoints: canvasAnnotation.points,
        imageSize: _imageSize,
      );

      // Refresh the annotations notifier if being used
      if (ref.exists(imageAnnotationsNotifierProvider(widget.imageItem.id))) {
        ref.read(imageAnnotationsNotifierProvider(widget.imageItem.id).notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving annotation: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Updates the image size when the image is loaded
  void _updateImageSize() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.size != Size.zero && _imageSize != renderBox.size) {
        setState(() {
          _imageSize = renderBox.size;
        });
        // Reload annotations with correct size
        _loadExistingAnnotations();
      }
    });
  }
}

/// Custom painter for drawing annotations
class DrawingPainter extends CustomPainter {
  final DrawingState drawingState;
  final List<CanvasAnnotation> annotations;
  final CanvasAnnotation? selectedAnnotation;
  final Size imageSize;
  final bool isToolSelected;

  DrawingPainter({
    required this.drawingState,
    required this.annotations,
    required this.selectedAnnotation,
    required this.imageSize,
    required this.isToolSelected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all persistent annotations first
    for (final annotation in annotations) {
      final isSelected = annotation == selectedAnnotation;
      _drawAnnotation(canvas, annotation, isSelected);
    }

    // Draw current drawing state on top only if a tool is selected
    if (isToolSelected && drawingState.points.isNotEmpty) {
      _drawCurrentDrawing(canvas);
    }
  }

  void _drawAnnotation(Canvas canvas, CanvasAnnotation annotation, bool isSelected) {
    final paint = Paint()
      ..color = isSelected ? Colors.orange : Colors.blue
      ..strokeWidth = isSelected ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    switch (annotation.tool) {
      case AnnotationTool.boundingBox:
        _drawBoundingBoxAnnotation(canvas, annotation.points, paint, isSelected);
        break;
      case AnnotationTool.polygon:
        _drawPolygonAnnotation(canvas, annotation.points, paint);
        break;
      case AnnotationTool.keypoint:
        _drawKeypointsAnnotation(canvas, annotation.points, paint);
        break;
      case AnnotationTool.none:
        break;
    }
  }

  void _drawCurrentDrawing(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    switch (drawingState.tool) {
      case AnnotationTool.boundingBox:
        _drawBoundingBoxAnnotation(canvas, drawingState.points, paint, false);
        break;
      case AnnotationTool.polygon:
        _drawPolygonAnnotation(canvas, drawingState.points, paint);
        break;
      case AnnotationTool.keypoint:
        _drawKeypointsAnnotation(canvas, drawingState.points, paint);
        break;
      case AnnotationTool.none:
        break;
    }
  }

  void _drawBoundingBoxAnnotation(Canvas canvas, List<Offset> points, Paint paint, bool showHandles) {
    if (points.length < 2) return;

    final start = points.first;
    final end = points.last;

    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);

    // Draw corner handles only for selected annotations
    if (showHandles) {
      final handlePaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;

      const handleSize = 6.0;
      canvas.drawCircle(rect.topLeft, handleSize, handlePaint);
      canvas.drawCircle(rect.topRight, handleSize, handlePaint);
      canvas.drawCircle(rect.bottomLeft, handleSize, handlePaint);
      canvas.drawCircle(rect.bottomRight, handleSize, handlePaint);
    }
  }

  void _drawPolygonAnnotation(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 4.0, pointPaint);
    }
  }

  void _drawKeypointsAnnotation(Canvas canvas, List<Offset> points, Paint paint) {
    final pointPaint = Paint()
      ..color = paint.color == Colors.blue ? Colors.red : paint.color
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, 6.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.drawingState != drawingState || oldDelegate.annotations != annotations || oldDelegate.selectedAnnotation != selectedAnnotation || oldDelegate.imageSize != imageSize || oldDelegate.isToolSelected != isToolSelected;
  }
}
