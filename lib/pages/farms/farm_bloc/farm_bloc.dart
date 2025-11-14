import 'dart:async';
import 'package:flareline/core/models/farms_model.dart';
import 'package:flareline/repositories/farm_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'farm_event.dart';
part 'farm_state.dart';

class FarmBloc extends Bloc<FarmEvent, FarmState> {
  final FarmRepository farmRepository;

  FarmBloc({required this.farmRepository}) : super(FarmInitial()) {
    on<LoadFarms>(_onLoadFarms);
    on<DeleteFarm>(_onDeleteFarm);
    on<FilterFarms>(_onFilterFarms);
    on<SearchFarms>(_onSearchFarms);
    on<SortFarms>(_onSortFarms);
    on<GetFarmById>(_onGetFarmById);
    on<UpdateFarm>(_onUpdateFarm);
    on<GetFarmsByProduct>(_onGetFarmsByProduct);
  }

  List<Farm> _farms = [];
  String _searchQuery = '';
  String _sectorFilter = "All";
  String _barangayFilter = "All";
  String _statusFilter = "All";
  String? _sortColumn;
  bool _sortAscending = true;

  String get barangayFilter => _barangayFilter;
  String get statusFilter => _statusFilter;
  String get sectorFilter => _sectorFilter;
  List<Farm> get allFarms => _farms;
  String get searchQuery => _searchQuery;
  String? get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  Future<void> _onGetFarmsByProduct(
    GetFarmsByProduct event,
    Emitter<FarmState> emit,
  ) async {
    emit(FarmsLoading());
    try {
      final farms = await farmRepository.getFarmsByProductId(event.productId);

      emit(FarmsLoaded(farms));
    } catch (e) {
      emit(FarmsError(e.toString()));
    }
  }

  Future<void> _onUpdateFarm(
    UpdateFarm event,
    Emitter<FarmState> emit,
  ) async {
    emit(FarmsLoading());

    try {
      final updatedFarm = await farmRepository.updateFarm(event.farm);

      final index = _farms.indexWhere((f) => f.id == updatedFarm.id);
      if (index != -1) {
        _farms[index] = updatedFarm;
      }

      // emit(FarmUpdated(updatedFarm));
      emit(FarmLoaded(updatedFarm));
    } catch (e) {
      emit(FarmsError('Failed to update farm: ${e.toString()}'));
    }
  }

  Future<void> _onGetFarmById(
    GetFarmById event,
    Emitter<FarmState> emit,
  ) async {
    emit(FarmsLoading());

    try {
      final farm = await farmRepository.getFarmById(event.id);
      emit(FarmLoaded(farm));
    } catch (e) {
      emit(FarmsError(e.toString()));
    }
  }

  Future<void> _onLoadFarms(
    LoadFarms event,
    Emitter<FarmState> emit,
  ) async {
    emit(FarmsLoading());

    try {
      final farms = await farmRepository.fetchFarms(farmerId: event.farmerId);
      _farms = farms; // Store the fetched farms
      emit(FarmsLoaded(_applyFilters())); // Apply filters to the stored farms
    } catch (e) {
      emit(FarmsError(e.toString()));
    }
  }

  Future<void> _onDeleteFarm(
    DeleteFarm event,
    Emitter<FarmState> emit,
  ) async {
    emit(FarmsLoading());
    try {
      await farmRepository.deleteFarm(event.id);
      _farms = _farms.where((farm) => farm.id != event.id).toList();
      emit(FarmsLoaded(_applyFilters(), message: 'Farm deleted successfully!'));
    } catch (e) {
      emit(FarmsError('Failed to delete farm: ${e.toString()}'));
    }
  }

  Future<void> _onFilterFarms(
    FilterFarms event,
    Emitter<FarmState> emit,
  ) async {
    // Handle sector filter
    _sectorFilter =
        (event.sector == null || event.sector!.isEmpty) ? "All" : event.sector!;

    // Handle barangay filter
    _barangayFilter = (event.barangay == null || event.barangay!.isEmpty)
        ? "All"
        : event.barangay!;

    // Handle status filter
    _statusFilter =
        (event.status == null || event.status!.isEmpty) ? "All" : event.status!;

    emit(FarmsLoaded(_applyFilters()));
  }

  Future<void> _onSearchFarms(
    SearchFarms event,
    Emitter<FarmState> emit,
  ) async {
    _searchQuery = event.query.trim().toLowerCase();
    emit(FarmsLoaded(_applyFilters()));
  }

  Future<void> _onSortFarms(
    SortFarms event,
    Emitter<FarmState> emit,
  ) async {
    if (_sortColumn == event.columnName) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = event.columnName;
      _sortAscending = true;
    }

    final filteredFarms = _applyFilters();
    for (var i = 0;
        i < (filteredFarms.length > 3 ? 3 : filteredFarms.length);
        i++) {}

    emit(FarmsLoaded(filteredFarms));
  }

  List<Farm> _applyFilters() {
    List<Farm> filteredFarms = _farms.where((farm) {
      // Sector filter
      final matchesSector = _sectorFilter == "All" ||
          _sectorFilter.isEmpty ||
          (farm.sector != null && farm.sector == _sectorFilter);

      if (!matchesSector) {
        return false;
      }

      // Barangay filter
      final matchesBarangay = _barangayFilter == "All" ||
          _barangayFilter.isEmpty ||
          (farm.barangay != null &&
              farm.barangay!.toLowerCase() == _barangayFilter.toLowerCase());

      if (!matchesBarangay) {
        return false;
      }

// Status filter
      final matchesStatus = _statusFilter == "All" ||
          _statusFilter.isEmpty ||
          (farm.status != null &&
              farm.status!.toLowerCase() == _statusFilter.toLowerCase());

      if (!matchesStatus) {
        return false;
      }

      // Search filter
      if (_searchQuery.isEmpty) {
        return true;
      }

      final matchesSearch = farm.name.toLowerCase().contains(_searchQuery) ||
          (farm.owner?.toLowerCase().contains(_searchQuery) ?? false) ||
          (farm.description?.toLowerCase().contains(_searchQuery) ?? false) ||
          (farm.barangay?.toLowerCase().contains(_searchQuery) ?? false) ||
          (farm.status?.toLowerCase().contains(_searchQuery) ?? false);
      (farm.sector?.toLowerCase().contains(_searchQuery) ?? false);

      return matchesSearch;
    }).toList();

    // Sorting logic
    if (_sortColumn != null) {
      filteredFarms.sort((a, b) {
        int compareResult;
        switch (_sortColumn) {
          case 'Name':
            compareResult = a.name.compareTo(b.name);
            break;
          case 'Owner':
            compareResult = (a.owner ?? '').compareTo(b.owner ?? '');
            break;
          case 'Barangay':
            compareResult = (a.barangay ?? '').compareTo(b.barangay ?? '');
            break;
          case 'Sector':
            compareResult = (a.sector ?? '').compareTo(b.sector ?? '');
            break;
          case 'Hectare':
            compareResult = (a.hectare ?? 0).compareTo(b.hectare ?? 0);
            break;
          case 'Status':
            // Handle null values by putting them at the end
            if (a.status == null && b.status == null) {
              compareResult = 0;
            } else if (a.status == null) {
              compareResult = 1; // nulls last
            } else if (b.status == null) {
              compareResult = -1; // nulls last
            } else {
              // Compare case-insensitively for consistency
              compareResult =
                  a.status!.toLowerCase().compareTo(b.status!.toLowerCase());
            }
            break;
          default:
            compareResult = 0;
        }
        return _sortAscending ? compareResult : -compareResult;
      });
    }

    return filteredFarms;
  }
}
