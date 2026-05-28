import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';

part 'keyboard_layouts.g.dart';

@JsonSerializable(explicitToJson: true)
class KeyboardLayoutsModel {
  final int? version;

  final Map<String, List<List<KeyboardKeyModel>>> full;
  final List<List<KeyboardKeyModel>> numeric;

  const KeyboardLayoutsModel({this.version, required this.full, required this.numeric});

  static const String assetPath = 'assets/twrp_keyboard_layouts.json';

  static Future<KeyboardLayoutsModel> loadFromAsset([String path = assetPath]) async {
    final raw = await rootBundle.loadString(path);
    return KeyboardLayoutsModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  factory KeyboardLayoutsModel.fromJson(Map<String, dynamic> json) => _$KeyboardLayoutsModelFromJson(json);

  Map<String, dynamic> toJson() => _$KeyboardLayoutsModelToJson(this);
}

@JsonSerializable()
class KeyboardKeyModel {
  @JsonKey(defaultValue: 'empty')
  final String type;

  @JsonKey(defaultValue: 1.0)
  final double units;
  final String? label;
  final String? text;
  final String? long;
  final String? logical;
  final int? to;

  const KeyboardKeyModel({
    required this.type,
    required this.units,
    this.label,
    this.text,
    this.long,
    this.logical,
    this.to,
  });

  factory KeyboardKeyModel.fromJson(Map<String, dynamic> json) => _$KeyboardKeyModelFromJson(json);

  Map<String, dynamic> toJson() => _$KeyboardKeyModelToJson(this);
}
