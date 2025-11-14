import 'package:equatable/equatable.dart';

class Association extends Equatable {
  final int id;
  final String name;
  final String? description;
  final String? totalMembers;
  final int? totalFarms;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? volume;
    final double? production;
  final double? hectare;
   final double? areaHarvested;
  final double? avgFarmSize;
  final String? imageUrl;
 
  const Association({
    required this.id,
    required this.name,
    this.volume,
    this.production,
    this.totalMembers,
    this.totalFarms,
    this.avgFarmSize,
    this.hectare,
    this.areaHarvested,
    this.imageUrl =
        'https://cdn2.iconfinder.com/data/icons/food-solid-icons-volume-2/128/054-512.png',
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory Association.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] as Map<String, dynamic>? ?? {};

    return Association(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Association',
      totalMembers:
          (stats['totalFarmers'] ?? 0).toString(), // Access from stats
      description: json['description'] as String?,
      totalFarms: (stats['totalFarms']) as int? ?? 0,
      volume: (stats['totalYieldVolume'] as num?)?.toDouble() ?? 0,

            production: (stats['metricTons'] as num?)?.toDouble() ?? 0,

      hectare: (stats['totalLandArea'] as num?)?.toDouble() ??
          0, // Access from stats

  areaHarvested: (stats['totalAreaHarvested'] as num?)?.toDouble() ??
          0, // Access from stats

      // hectare: (json['avgFarmSize'] as num?)?.toDouble() ?? 0,

      avgFarmSize: (stats['totalLandArea'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String? ??
          'https://cdn2.iconfinder.com/data/icons/food-solid-icons-volume-2/128/054-512.png',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Association copyWith({
    int? id,
    String? name,
    String? description,
    String? totalMembers,
    int? totalFarms,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? volume,
    double? production,
    double? hectare,

    double? areaHarvested,
    double? avgFarmSize,
    String? imageUrl,
  }) {
    return Association(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalMembers: totalMembers ?? this.totalMembers,
      totalFarms: totalFarms ?? this.totalFarms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      volume: volume ?? this.volume,
      areaHarvested: areaHarvested ?? this.areaHarvested,
      production: production ?? this.production,
      hectare: hectare ?? this.hectare,
      avgFarmSize: avgFarmSize ?? this.avgFarmSize,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalMembers': totalMembers,
      'totalFarms': totalFarms,
      'description': description,
      'volume': volume,
      'production': production,
      'avgFarmSize': avgFarmSize,
      'areaHarvested': areaHarvested,
      'hectare': hectare,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        hectare,
        totalMembers,
        totalFarms,
        avgFarmSize,
        volume,
        areaHarvested,
        production,
        imageUrl,
        createdAt,
        updatedAt,
      ];
}
