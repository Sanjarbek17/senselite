// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'image_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImageItem _$ImageItemFromJson(Map<String, dynamic> json) => ImageItem(
  id: json['id'] as String,
  filename: json['filename'] as String,
  filePath: json['filePath'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  fileSize: (json['fileSize'] as num).toInt(),
  projectId: json['projectId'] as String,
  isAnnotated: json['isAnnotated'] as bool? ?? false,
  annotationCount: (json['annotationCount'] as num?)?.toInt() ?? 0,
  addedAt: DateTime.parse(json['addedAt'] as String),
);

Map<String, dynamic> _$ImageItemToJson(ImageItem instance) => <String, dynamic>{
  'id': instance.id,
  'filename': instance.filename,
  'filePath': instance.filePath,
  'width': instance.width,
  'height': instance.height,
  'fileSize': instance.fileSize,
  'projectId': instance.projectId,
  'isAnnotated': instance.isAnnotated,
  'annotationCount': instance.annotationCount,
  'addedAt': instance.addedAt.toIso8601String(),
};
