import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final int id;
  final String name;
  final String sector;
  final String? description;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sector,
    required this.description,
    this.imageUrl =
        'https://cdn2.iconfinder.com/data/icons/food-solid-icons-volume-2/128/054-512.png',
    this.createdAt,
    this.updatedAt,
  });

  // Copy with method for immutable updates
  Product copyWith({
    int? id,
    String? name,
    String? sector,
    String? description,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Factory method for creating from JSON (useful for API responses)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      sector: json['sector'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String? ??
          'https://res.cloudinary.com/dk41ykxsq/image/upload/v1757557833/OIP-removebg-preview_r0qvt1.png',
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  // Convert to JSON (useful for API requests)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sector': sector,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Sample data for development/demo purposes
  static List<Product> get sampleProducts {
    return const [
      Product(
        id: 1,
        name: 'Organic Rice',
        sector: 'Rice',
        description: 'Premium quality organic rice',
        imageUrl: 'https://example.com/rice.jpg',
      ),
      Product(
        id: 2,
        name: 'Free Range Eggs',
        sector: 'Livestock',
        description: 'Eggs from free-range chickens',
        imageUrl: 'https://example.com/eggs.jpg',
      ),
      Product(
        id: 3,
        name: 'Fresh Tilapia',
        sector: 'Fishery',
        description: 'Freshwater tilapia fish',
        imageUrl: 'https://example.com/tilapia.jpg',
      ),
      Product(
        id: 4,
        name: 'Yellow Corn',
        sector: 'Corn',
        description: 'High-quality yellow corn',
        imageUrl: 'https://example.com/corn.jpg',
      ),
      Product(
        id: 5,
        name: 'Organic Mangoes',
        sector: 'High Value Crop',
        description: 'Sweet organic mangoes',
        imageUrl: 'https://example.com/mangoes.jpg',
      ),
    ];
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sector,
        description,
        imageUrl,
        createdAt,
        updatedAt,
      ];
}
