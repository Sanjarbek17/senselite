// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Project _$ProjectFromJson(Map<String, dynamic> json) => Project(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  projectPath: json['projectPath'] as String,
  imagesPath: json['imagesPath'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  totalImages: (json['totalImages'] as num?)?.toInt() ?? 0,
  annotatedImages: (json['annotatedImages'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ProjectToJson(Project instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'projectPath': instance.projectPath,
  'imagesPath': instance.imagesPath,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'totalImages': instance.totalImages,
  'annotatedImages': instance.annotatedImages,
};
