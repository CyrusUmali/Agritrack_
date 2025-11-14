part of 'yield_bloc.dart';

abstract class YieldEvent extends Equatable {
  const YieldEvent();

  @override
  List<Object?> get props => [];
}

class LoadYields extends YieldEvent {}

class LoadYieldsByFarmer extends YieldEvent {
  final int farmerId;

  const LoadYieldsByFarmer(this.farmerId);

  @override
  List<Object> get props => [farmerId];
}

class LoadYieldsByProduct extends YieldEvent {
  final int productId;

  const LoadYieldsByProduct(this.productId);

  @override
  List<Object> get props => [productId];
}

class AddYield extends YieldEvent {
  final int farmerId;
  final int productId;
  final DateTime harvestDate;
  final double? areaHarvested;
  final int farmId;
  final double volume;
  final String? notes;
  final double? value;
  final List<String?> images;

  const AddYield({
    required this.farmerId,
    required this.productId,
    required this.harvestDate,
    required this.farmId,
    required this.volume,
    this.areaHarvested,
    this.notes,
    this.value,
    this.images = const [],
  });

  @override
  List<Object?> get props => [
        farmerId,
        productId,
        harvestDate,
        areaHarvested,
        farmId,
        volume,
        notes,
        value,
        images,
      ];
}

class DeleteYield extends YieldEvent {
  final int id;

  const DeleteYield(this.id);

  @override
  List<Object> get props => [id];
}

class FilterYields extends YieldEvent {
  final String? sector;
  final String? productName;
  final String? farmer;
  final String? year;
  final String? barangay;
  final String? status;
  final int? farmId;

  const FilterYields(
      {this.sector,
      this.productName,
      this.farmer,
      this.year,
      this.barangay,
      this.status,
      this.farmId});

  @override
  List<Object?> get props =>
      [sector, productName, farmer, year, barangay, status, farmId];
}

class SearchYields extends YieldEvent {
  final String query;

  const SearchYields(this.query);

  @override
  List<Object> get props => [query];
}

class GetYieldByBarangay extends YieldEvent {
  final String barangay;

  const GetYieldByBarangay(this.barangay);

  @override
  List<Object> get props => [barangay];
}

class GetYieldByLake extends YieldEvent {
  final String lake;

  const GetYieldByLake(this.lake);

  @override
  List<Object> get props => [lake];
}

class GetYieldByFarmId extends YieldEvent {
  final int farmId;

  const GetYieldByFarmId(this.farmId);

  @override
  List<Object> get props => [farmId];
}

class SortYields extends YieldEvent {
  final String columnName;

  const SortYields(this.columnName);

  @override
  List<Object> get props => [columnName];
}

class UpdateYield extends YieldEvent {
  final Yield yieldRecord;

  const UpdateYield(this.yieldRecord);

  @override
  List<Object> get props => [yieldRecord];
}
