// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Label _$LabelFromJson(Map<String, dynamic> json) => Label(
  id: json['id'] as String,
  name: json['name'] as String,
  color: const ColorConverter().fromJson((json['color'] as num).toInt()),
  projectId: json['projectId'] as String,
  description: json['description'] as String?,
  shortcut: json['shortcut'] as String?,
  annotationCount: (json['annotationCount'] as num?)?.toInt() ?? 0,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$LabelToJson(Label instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'color': const ColorConverter().toJson(instance.color),
  'projectId': instance.projectId,
  'description': instance.description,
  'shortcut': instance.shortcut,
  'annotationCount': instance.annotationCount,
  'createdAt': instance.createdAt.toIso8601String(),
};
