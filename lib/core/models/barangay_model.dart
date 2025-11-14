import 'package:equatable/equatable.dart';

class Barangay extends Equatable {
  final String id;
  final String name;

  const Barangay({
    required this.id,
    required this.name,
  });

  // Copy with method for immutable updates
  Barangay copyWith({
    String? id,
    String? name,
  }) {
    return Barangay(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory Barangay.fromJson(Map<String, dynamic> json) {
    return Barangay(
      id: json['id'].toString(), // Ensure id is converted to string
      name: json['name'] as String,
    );
  }

  // Sample data for development/demo purposes
  static List<Barangay> get sampleBarangays {
    return [
      Barangay(
        id: '1',
        name: 'San Juan',
      ),
      Barangay(
        id: '2',
        name: 'San Isidro',
      ),
      Barangay(
        id: '3',
        name: 'Santa Maria Magdalena',
      ),
      Barangay(
        id: '4',
        name: 'San Rafael',
      ),
    ];
  }

  @override
  List<Object?> get props => [id, name];
}
