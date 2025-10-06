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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/image_item.dart';
import '../../../../core/models/project.dart';

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
  DrawingState _drawingState = const DrawingState();
  final GlobalKey _imageKey = GlobalKey();
  final Size _imageSize = Size.zero;
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
                  onPressed: _drawingState.tool != AnnotationTool.none ? () => _selectTool(AnnotationTool.none) : null,
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

  /// Builds a tool button with selection state
  Widget _buildToolButton({
    required IconData icon,
    required AnnotationTool tool,
    required String tooltip,
  }) {
    final isSelected = _drawingState.tool == tool;

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
        onPressed: () => _selectTool(tool),
        tooltip: tooltip,
      ),
    );
  }

  /// Selects an annotation tool
  void _selectTool(AnnotationTool tool) {
    setState(() {
      if (_drawingState.tool == tool) {
        // Deselect if same tool is clicked
        _drawingState = const DrawingState();
      } else {
        // Select new tool
        _drawingState = _drawingState.copyWith(
          tool: tool,
          points: [],
          isDrawing: false,
        );
      }
    });
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
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorState('Error loading image', error.toString());
                  },
                ),
              ),
            ),
            // Drawing overlay
            if (_drawingState.tool != AnnotationTool.none)
              Positioned.fill(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: CustomPaint(
                      painter: DrawingPainter(
                        drawingState: _drawingState,
                        imageSize: _imageSize,
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
    if (_drawingState.tool == AnnotationTool.none) return;

    setState(() {
      _drawingState = _drawingState.copyWith(
        points: [details.localPosition],
        isDrawing: true,
      );
    });
  }

  /// Handles pan update for drawing
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_drawingState.isDrawing) return;

    setState(() {
      switch (_drawingState.tool) {
        case AnnotationTool.boundingBox:
          // For bounding box, only keep start and current point
          _drawingState = _drawingState.copyWith(
            points: [_drawingState.points.first, details.localPosition],
          );
          break;
        case AnnotationTool.polygon:
        case AnnotationTool.keypoint:
          // For polygon and keypoint, add all points
          _drawingState = _drawingState.copyWith(
            points: [..._drawingState.points, details.localPosition],
          );
          break;
        case AnnotationTool.none:
          break;
      }
    });
  }

  /// Handles pan end for drawing
  void _onPanEnd(DragEndDetails details) {
    if (!_drawingState.isDrawing || _drawingState.points.length < 2) {
      setState(() {
        _drawingState = _drawingState.copyWith(
          points: [],
          isDrawing: false,
        );
      });
      return;
    }

    // Create annotation from drawing
    _createAnnotationFromDrawing();

    setState(() {
      _drawingState = _drawingState.copyWith(
        points: [],
        isDrawing: false,
      );
    });
  }

  /// Creates an annotation from the current drawing state
  void _createAnnotationFromDrawing() {
    // TODO: Implement annotation creation
    // This will convert screen coordinates to normalized coordinates
    // and save the annotation to the database
    print('Creating annotation: ${_drawingState.tool} with ${_drawingState.points.length} points');

    // Show a temporary success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_drawingState.tool.name} annotation created!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Custom painter for drawing annotations
class DrawingPainter extends CustomPainter {
  final DrawingState drawingState;
  final Size imageSize;

  DrawingPainter({
    required this.drawingState,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (drawingState.points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    switch (drawingState.tool) {
      case AnnotationTool.boundingBox:
        _drawBoundingBox(canvas, paint);
        break;
      case AnnotationTool.polygon:
        _drawPolygon(canvas, paint);
        break;
      case AnnotationTool.keypoint:
        _drawKeypoints(canvas, paint);
        break;
      case AnnotationTool.none:
        break;
    }
  }

  void _drawBoundingBox(Canvas canvas, Paint paint) {
    if (drawingState.points.length < 2) return;

    final start = drawingState.points.first;
    final end = drawingState.points.last;

    final rect = Rect.fromPoints(start, end);
    canvas.drawRect(rect, paint);

    // Draw corner handles
    final handlePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    const handleSize = 6.0;
    canvas.drawCircle(rect.topLeft, handleSize, handlePaint);
    canvas.drawCircle(rect.topRight, handleSize, handlePaint);
    canvas.drawCircle(rect.bottomLeft, handleSize, handlePaint);
    canvas.drawCircle(rect.bottomRight, handleSize, handlePaint);
  }

  void _drawPolygon(Canvas canvas, Paint paint) {
    if (drawingState.points.length < 2) return;

    final path = Path();
    path.moveTo(drawingState.points.first.dx, drawingState.points.first.dy);

    for (int i = 1; i < drawingState.points.length; i++) {
      path.lineTo(drawingState.points[i].dx, drawingState.points[i].dy);
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (final point in drawingState.points) {
      canvas.drawCircle(point, 4.0, pointPaint);
    }
  }

  void _drawKeypoints(Canvas canvas, Paint paint) {
    final pointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final point in drawingState.points) {
      canvas.drawCircle(point, 6.0, pointPaint);
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return oldDelegate.drawingState != drawingState || oldDelegate.imageSize != imageSize;
  }
}
