// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hack_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HackModel _$HackModelFromJson(Map<String, dynamic> json) => _HackModel(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  category: json['category'] as String,
);

Map<String, dynamic> _$HackModelToJson(_HackModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'category': instance.category,
    };
