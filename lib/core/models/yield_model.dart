import 'package:equatable/equatable.dart';

class Yield extends Equatable {
  final int id;
  final int farmerId;
  final int productId;
  final DateTime harvestDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int farmId;
  final double volume;
  final String? farmerName;
  final String? notes;
  final String? productName;
  final String? farmName;
  final String? productImage;
  final String? sector;
  final String? barangay;
  final int? sectorId;
  final double? value;
  final List<String?> images;
  final String? status;
  final String? lake;
  final double? hectare;
    final double? areaHarvested;



  const Yield(
      {required this.id,
      required this.farmerId,
      required this.productId,
      required this.harvestDate,
      this.createdAt,
      this.updatedAt,
      this.productImage,
      required this.farmId,
      required this.volume,
      this.notes,
      this.value,
      this.status,
      this.lake,
      this.barangay,
      this.images = const [],
      this.sector,
      this.sectorId,
      this.farmerName,
      this.hectare,
      this.productName,
      this.areaHarvested,
      this.farmName});

  factory Yield.fromJson(Map<String, dynamic> json) {
    // Helper function to log and validate types
    dynamic _parseField(String key, dynamic value,
        {bool expectString = false}) {
      // print('Parsing field "$key": value=$value (type: ${value?.runtimeType})');

      if (expectString && value != null && value is! String) {
        return value.toString(); // Convert to string if expected to be string
      }
      return value;
    }

    // Handle images conversion
    List<String?> parseImages(dynamic imagesData) {
      if (imagesData == null) return [];
      if (imagesData is String) return [imagesData];
      if (imagesData is List) {
        return imagesData.map((item) => item?.toString()).toList();
      }
      return [];
    }

    return Yield(
      id: json['id'] as int,
      farmerId: json['farmerId'] as int,
      productId: json['productId'] as int,
      harvestDate: DateTime.parse(json['harvestDate'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      farmId: json['farmId'] as int? ?? 0,
      volume: (json['volume'] as num).toDouble(),
      notes: _parseField('notes', json['notes'], expectString: true),
      barangay: _parseField('barangay', json['barangay'], expectString: true),
      sector: _parseField('sector', json['sector'], expectString: true),
      sectorId: json['sectorId'] as int? ?? 0,
      value: json['value'] != null ? (json['value'] as num).toDouble() : null,
      images: parseImages(json['images']),
      farmerName:
          _parseField('farmerName', json['farmerName'], expectString: true),
      farmName: _parseField('farmName', json['farmName'], expectString: true),
      productImage:
          _parseField('productImage', json['productImage'], expectString: true),
      productName:
          _parseField('productName', json['productName'], expectString: true),
      status: _parseField('status', json['status'], expectString: true),
            lake: _parseField('lake', json['lake'], expectString: true),
      hectare: json['farmArea'] != null
          ? (json['farmArea'] as num).toDouble()
          : null,
       areaHarvested: json['area_harvested'] != null
          ? (json['area_harvested'] as num).toDouble()
          : null,


          
    );
  }

  Yield copyWith({
    int? id,
    int? farmerId,
    int? productId,
    DateTime? harvestDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? farmId,
    double? volume,
    String? notes,
    String? farmerName,
    String? productName,
    String? productImage,
    String? farmName,
    String? sector,
    String? barangay,
    int? sectorId,
    double? value,
    List<String?>? images,
    String? status,
    String? lake , 
    double? hectare,
    double? areaHarvested,
  }) {
    return Yield(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      productId: productId ?? this.productId,
      harvestDate: harvestDate ?? this.harvestDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      farmId: farmId ?? this.farmId,
      volume: volume ?? this.volume,
      notes: notes ?? this.notes,
      farmerName: farmerName ?? this.farmerName,
      productImage: productImage ?? this.productImage,
      productName: productName ?? this.productName,
      farmName: farmName ?? this.farmName,
      sector: sector ?? this.sector,
      barangay: barangay ?? this.barangay,
      sectorId: sectorId ?? this.sectorId,
      value: value ?? this.value,
      images: images ?? this.images,
      status: status ?? this.status,
      lake: lake ?? this.lake,
      hectare: hectare ?? this.hectare,
      areaHarvested: areaHarvested ?? this.areaHarvested,
    );
  }

  // Convert to JSON (useful for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'product_id': productId,
      'harvest_date': harvestDate.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'farm_id': farmId,
      'volume': volume,
      'notes': notes,
      'value': value,
      'images': images,
      'hectare': hectare,
      'areaHarvested':areaHarvested,
      'barangay': barangay,
      'sector': sector,
      'sectorId': sectorId,
      'farmerName': farmerName,
      'farmName': farmName,
      'productName': productName,
      'productImage': productImage,
      'status': status ,
      'lake': lake ,
    };
  }

 
  @override
  List<Object?> get props => [
        id,
        farmerId,
        productId,
        areaHarvested,
        harvestDate,
        createdAt,
        updatedAt,
        farmId,
        volume,
        notes,
        value,
        images,
        farmerName,
        sector,
        sectorId,
        productName,
        productImage,
        farmName,
        hectare,
        status,
        lake , 
        barangay
      ];
}
