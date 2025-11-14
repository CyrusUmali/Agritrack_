part of 'farmer_bloc.dart';

abstract class FarmerEvent extends Equatable {
  const FarmerEvent();

  @override
  List<Object?> get props => [];
}

class LoadFarmers extends FarmerEvent {}

class AddFarmer extends FarmerEvent {
  final String name;
  final String? email;
  final String? phone;
  final String barangay;
  final String sector;
  final String? imageUrl;

  const AddFarmer({
    required this.name,
    this.email,
    this.phone,
    required this.barangay,
    required this.sector,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [name, email, phone, barangay, sector, imageUrl];
}

class DeleteFarmer extends FarmerEvent {
  final int id;

  const DeleteFarmer(this.id);

  @override
  List<Object> get props => [id];
}

class FilterFarmers extends FarmerEvent {
  final String? name;
  final String? association;
  final String? sector;
  final String? barangay;

  const FilterFarmers({
    this.association,
    this.name,
    this.sector,
    this.barangay,
  });

  @override
  List<Object?> get props => [association, name, sector, barangay];
}

class SearchFarmers extends FarmerEvent {
  final String query;

  const SearchFarmers(this.query);

  @override
  List<Object> get props => [query];
}

class GetFarmerById extends FarmerEvent {
  final int id;

  const GetFarmerById(this.id);

  @override
  List<Object> get props => [id];
}

class SortFarmers extends FarmerEvent {
  final String columnName;

  const SortFarmers(this.columnName);

  @override
  List<Object> get props => [columnName];
}

class UpdateFarmer extends FarmerEvent {
  final Farmer farmer;

  const UpdateFarmer(this.farmer);

  @override
  List<Object> get props => [farmer];
}
