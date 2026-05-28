// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyboard_layouts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeyboardLayoutsModel _$KeyboardLayoutsModelFromJson(Map<String, dynamic> json) => KeyboardLayoutsModel(
      version: (json['version'] as num?)?.toInt(),
      full: (json['full'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) =>
                    (e as List<dynamic>).map((e) => KeyboardKeyModel.fromJson(e as Map<String, dynamic>)).toList())
                .toList()),
      ),
      numeric: (json['numeric'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => KeyboardKeyModel.fromJson(e as Map<String, dynamic>)).toList())
          .toList(),
    );

Map<String, dynamic> _$KeyboardLayoutsModelToJson(KeyboardLayoutsModel instance) => <String, dynamic>{
      'version': instance.version,
      'full': instance.full.map((k, e) => MapEntry(k, e.map((e) => e.map((e) => e.toJson()).toList()).toList())),
      'numeric': instance.numeric.map((e) => e.map((e) => e.toJson()).toList()).toList(),
    };

KeyboardKeyModel _$KeyboardKeyModelFromJson(Map<String, dynamic> json) => KeyboardKeyModel(
      type: json['type'] as String? ?? 'empty',
      units: (json['units'] as num?)?.toDouble() ?? 1.0,
      label: json['label'] as String?,
      text: json['text'] as String?,
      long: json['long'] as String?,
      logical: json['logical'] as String?,
      to: (json['to'] as num?)?.toInt(),
    );

Map<String, dynamic> _$KeyboardKeyModelToJson(KeyboardKeyModel instance) => <String, dynamic>{
      'type': instance.type,
      'units': instance.units,
      'label': instance.label,
      'text': instance.text,
      'long': instance.long,
      'logical': instance.logical,
      'to': instance.to,
    };
