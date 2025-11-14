// ignore_for_file: unnecessary_question_mark

library flareline_uikit;

import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:flutter/material.dart' show Color, IconData;

part 'table_data_entity.g.dart';

@JsonSerializable()
class TableDataEntity {
  List<dynamic>? headers;
  List<List<TableDataRowsTableDataRows>>? rows;

  TableDataEntity();

  factory TableDataEntity.fromJson(Map<String, dynamic> json) =>
      _$TableDataEntityFromJson(json);

  Map<String, dynamic> toJson() => _$TableDataEntityToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}

@JsonSerializable()
class TableDataRowsTableDataRows {
  String? text;
  String? dataType;
  String? tagType;
  String? id;
  String? imageUrl;
  String? columnName;
  String? align;
  dynamic data;

  // For icons, we need to use custom serialization
  // since IconData and Color are not directly serializable
  String? iconName; // Store the icon name/code
  String? iconColorHex; // Store color as hex string
  String? iconTooltip;

  TableDataRowsTableDataRows();

  // Helper getter for IconData
  IconData? get iconData {
    // You would need to implement a mapping from string to IconData
    // For example, using a map of icon names to IconData objects
    // This is a simplified example
    return null; // Replace with actual implementation
  }

  // Helper getter for Color
  Color? get iconColor {
    if (iconColorHex == null) return null;
    // Convert hex string to Color
    try {
      return Color(int.parse(iconColorHex!.replaceFirst('#', '0xFF')));
    } catch (e) {
      return null;
    }
  }

  // Helper setter for iconColor
  set iconColor(Color? color) {
    if (color == null) {
      iconColorHex = null;
    } else {
      // Convert Color to hex string
      iconColorHex =
          '#${color.value.toRadixString(16).substring(2).padLeft(6, '0')}';
    }
  }

  factory TableDataRowsTableDataRows.fromJson(Map<String, dynamic> json) =>
      _$TableDataRowsTableDataRowsFromJson(json);

  Map<String, dynamic> toJson() => _$TableDataRowsTableDataRowsToJson(this);

  @override
  String toString() {
    return jsonEncode(this);
  }
}
