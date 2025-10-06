// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Point _$PointFromJson(Map<String, dynamic> json) =>
    Point(x: (json['x'] as num).toDouble(), y: (json['y'] as num).toDouble());

Map<String, dynamic> _$PointToJson(Point instance) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
};

BoundingBoxAnnotation _$BoundingBoxAnnotationFromJson(
  Map<String, dynamic> json,
) => BoundingBoxAnnotation(
  id: json['id'] as String,
  labelId: json['labelId'] as String,
  imageId: json['imageId'] as String,
  projectId: json['projectId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  notes: json['notes'] as String?,
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  width: (json['width'] as num).toDouble(),
  height: (json['height'] as num).toDouble(),
);

Map<String, dynamic> _$BoundingBoxAnnotationToJson(
  BoundingBoxAnnotation instance,
) => <String, dynamic>{
  'id': instance.id,
  'labelId': instance.labelId,
  'imageId': instance.imageId,
  'projectId': instance.projectId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'notes': instance.notes,
  'x': instance.x,
  'y': instance.y,
  'width': instance.width,
  'height': instance.height,
};

PolygonAnnotation _$PolygonAnnotationFromJson(Map<String, dynamic> json) =>
    PolygonAnnotation(
      id: json['id'] as String,
      labelId: json['labelId'] as String,
      imageId: json['imageId'] as String,
      projectId: json['projectId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
      points: (json['points'] as List<dynamic>)
          .map((e) => Point.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PolygonAnnotationToJson(PolygonAnnotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labelId': instance.labelId,
      'imageId': instance.imageId,
      'projectId': instance.projectId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'notes': instance.notes,
      'points': instance.points,
    };

KeypointAnnotation _$KeypointAnnotationFromJson(Map<String, dynamic> json) =>
    KeypointAnnotation(
      id: json['id'] as String,
      labelId: json['labelId'] as String,
      imageId: json['imageId'] as String,
      projectId: json['projectId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      notes: json['notes'] as String?,
      keypoints: (json['keypoints'] as List<dynamic>)
          .map((e) => Keypoint.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$KeypointAnnotationToJson(KeypointAnnotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labelId': instance.labelId,
      'imageId': instance.imageId,
      'projectId': instance.projectId,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'notes': instance.notes,
      'keypoints': instance.keypoints,
    };

Keypoint _$KeypointFromJson(Map<String, dynamic> json) => Keypoint(
  name: json['name'] as String,
  point: Point.fromJson(json['point'] as Map<String, dynamic>),
  visibility: (json['visibility'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$KeypointToJson(Keypoint instance) => <String, dynamic>{
  'name': instance.name,
  'point': instance.point,
  'visibility': instance.visibility,
};
