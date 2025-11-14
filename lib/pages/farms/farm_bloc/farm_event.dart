part of 'farm_bloc.dart';

abstract class FarmEvent extends Equatable {
  const FarmEvent();

  @override
  List<Object?> get props => [];
}

class LoadFarms extends FarmEvent {
  final int? farmerId;
  
  const LoadFarms({this.farmerId});
}

class AddFarm extends FarmEvent {
  final String name;
  final String? owner;
  final String? description;
  final String? barangay;
  final double? hectare;

  const AddFarm({
    required this.name,
    this.owner,
    this.description,
    this.barangay,
    this.hectare,
  });

  @override
  List<Object?> get props => [name, owner, description, barangay, hectare];
}

class DeleteFarm extends FarmEvent {
  final int id;

  const DeleteFarm(this.id);

  @override
  List<Object> get props => [id];
}

class FilterFarms extends FarmEvent {
  final String? barangay;

  final String? name;
  final String? sector;
  final String? status;

  const FilterFarms({this.barangay, this.name, this.sector, this.status});

  @override
  List<Object?> get props => [name, sector, barangay, status];
}

class SearchFarms extends FarmEvent {
  final String query;

  const SearchFarms(this.query);

  @override
  List<Object> get props => [query];
}

class GetFarmById extends FarmEvent {
  final int id;

  const GetFarmById(
    this.id,
  );

  @override
  List<Object> get props => [id];
}

class GetFarmsByProduct extends FarmEvent {
  final int productId;

  const GetFarmsByProduct(
    this.productId,
  );

  @override
  List<Object> get props => [];
}

class SortFarms extends FarmEvent {
  final String columnName;

  const SortFarms(this.columnName);

  @override
  List<Object> get props => [columnName];
}

class UpdateFarm extends FarmEvent {
  final Farm farm;

  const UpdateFarm(this.farm);

  @override
  List<Object> get props => [farm];
}
