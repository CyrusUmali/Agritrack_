import 'dart:async';
import 'dart:math';
import 'package:flareline/repositories/yield_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flareline/core/models/yield_model.dart';

part 'yield_event.dart';
part 'yield_state.dart';

class YieldBloc extends Bloc<YieldEvent, YieldState> {
  final YieldRepository yieldRepository;
  int? _currentFarmerId;

  YieldBloc({required this.yieldRepository}) : super(YieldInitial()) {
    on<LoadYields>(_onLoadYields);
    on<AddYield>(_onAddYield);
    on<DeleteYield>(_onDeleteYield);
    on<FilterYields>(_onFilterYields);
    on<SearchYields>(_onSearchYields);
    on<SortYields>(_onSortYields);
    on<GetYieldByFarmId>(_onGetYieldByFarmId);
    on<GetYieldByBarangay>(_onGetYieldBybarangay);
    on<GetYieldByLake>(_onGetYieldByLake);
    on<UpdateYield>(_onUpdateYield);
    on<LoadYieldsByFarmer>(_onLoadYieldsByFarmer);
    on<LoadYieldsByProduct>(_onLoadYieldsByProduct);
  }

  List<Yield> _yields = [];
  String _searchQuery = '';
  String _sectorFilter = "All";
  String _productFilter = "All";
  String _farmerFilter = "All";
  String _yearFilter = "All";
  String _barangayFilter = "All";
  String _statusFilter = "All";
  String? _sortColumn;
  bool _sortAscending = true;

  // Getters for all filter values
  List<Yield> get allYields => _yields;
  String get sectorFilter => _sectorFilter;
  String get productFilter => _productFilter;
  String get farmerFilter => _farmerFilter;
  String get yearFilter => _yearFilter;
  String get barangayFilter => _barangayFilter;
  String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  String? get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  Future<void> _onAddYield(
    AddYield event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());
    try {
      final newYield = Yield(
        id: 0, // Will be assigned by server
        farmerId: event.farmerId,
        productId: event.productId,
        harvestDate: event.harvestDate,
        areaHarvested: event.areaHarvested,
        farmId: event.farmId,
        volume: event.volume,
        notes: event.notes,
        value: event.value,
        images: event.images,
      );

      await yieldRepository.addYield(newYield);

      // Refresh based on current context
      if (_currentFarmerId != null) {
        _yields = await yieldRepository.fetchYieldsByFarmer(_currentFarmerId!);
      } else {
        _yields = await yieldRepository.fetchYields();
      }

      emit(YieldsLoaded(_applyFilters(),
          message: 'Yield record added successfully!'));
    } catch (e) {
      emit(YieldsError('Failed to add yield record: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteYield(
    DeleteYield event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());
    try {
      await yieldRepository.deleteYield(event.id);
      _yields = _yields.where((y) => y.id != event.id).toList();
      emit(YieldsLoaded(_applyFilters(),
          message: 'Yield record deleted successfully!'));
    } catch (e) {
      emit(YieldsError('Failed to delete yield record: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateYield(
    UpdateYield event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());

    try {
      final updatedYield = await yieldRepository.updateYield(event.yieldRecord);

      final index = _yields.indexWhere((y) => y.id == updatedYield.id);
      if (index != -1) {
        _yields[index] = updatedYield;
      }

      emit(YieldUpdated(updatedYield));
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      // Print the full error stack trace for debugging
      print('Error in _onUpdateYield: $e');
      if (e is Error) {
        print(e.stackTrace);
      }

      // Emit error state with user-friendly message
      emit(YieldsError('Failed to update yield record: ${e.toString()}'));
    }
  }

  Future<void> _onLoadYields(
    LoadYields event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());

    try {
      _yields = await yieldRepository.fetchYields();
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      emit(YieldsError(e.toString()));
    }
  }

  Future<void> _onGetYieldByFarmId(
    GetYieldByFarmId event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());

    try {
      _yields =
          (await yieldRepository.getYieldByFarmId(event.farmId)) as List<Yield>;

      // emit(YieldsLoaded(yieldRecord as List<Yield>));
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      print('[_onGetYieldByFarmId] Error occurred: $e');
      emit(YieldsError(e.toString()));
      print('[_onGetYieldByFarmId] Emitted YieldsError state');
    }
  }

  Future<void> _onGetYieldBybarangay(
    GetYieldByBarangay event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());

    try {
      _yields = (await yieldRepository.getYieldByBarangay(event.barangay))
          as List<Yield>;

      // emit(YieldsLoaded(yieldRecord as List<Yield>));
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      print('[__onGetYieldBybarangay] Error occurred: $e');
      emit(YieldsError(e.toString()));
      print('[_onGetYieldBybarangay] Emitted YieldsError state');
    }
  }

  Future<void> _onGetYieldByLake(
    GetYieldByLake event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());

    try {
      _yields = await yieldRepository.getYieldByLake(event.lake);
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      print('[_onGetYieldByLake] Error occurred: $e');
      emit(YieldsError(e.toString()));
      print('[_onGetYieldByLake] Emitted YieldsError state');
    }
  }

// Update the LoadYieldsByFarmer handler to store the farmer ID
  Future<void> _onLoadYieldsByFarmer(
    LoadYieldsByFarmer event,
    Emitter<YieldState> emit,
  ) async {
    _currentFarmerId = event.farmerId; // Store the farmer ID
    emit(YieldsLoading());
    try {
      _yields = await yieldRepository.fetchYieldsByFarmer(event.farmerId);
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      emit(YieldsError('Failed to load yields: ${e.toString()}'));
    }
  }

  Future<void> _onLoadYieldsByProduct(
    LoadYieldsByProduct event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());

    try {
      _yields = await yieldRepository.fetchYieldsByProduct(event.productId);
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      emit(YieldsError(e.toString()));
    }
  }

  Future<void> _onFilterYields(
    FilterYields event,
    Emitter<YieldState> emit,
  ) async {
    _sectorFilter = event.sector ?? "All";
    _productFilter = event.productName ?? "All";
    _farmerFilter = event.farmer ?? "All";
    _yearFilter = event.year ?? "All";
    _barangayFilter = event.barangay ?? "All";
    _statusFilter = event.status ?? "All";

    emit(YieldsLoaded(_applyFilters()));
  }

  Future<void> _onSearchYields(
    SearchYields event,
    Emitter<YieldState> emit,
  ) async {
    _searchQuery = event.query.trim().toLowerCase();
    emit(YieldsLoaded(_applyFilters()));
  }

  Future<void> _onSortYields(
    SortYields event,
    Emitter<YieldState> emit,
  ) async {
    if (_sortColumn == event.columnName) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = event.columnName;
      _sortAscending = true;
    }

    final filteredYields = _applyFilters();
    for (var i = 0;
        i < (filteredYields.length > 3 ? 3 : filteredYields.length);
        i++) {}

    emit(YieldsLoaded(filteredYields));
  }

  List<Yield> _applyFilters() {
    List<Yield> filteredYields = _yields.where((yield) {
      // Sector filter
      final matchesSector = _sectorFilter == "All" ||
          _sectorFilter.isEmpty ||
          (yield.sector != null && yield.sector == _sectorFilter);

      if (!matchesSector) return false;

      // Product filter
      final matchesProduct = _productFilter == "All" ||
          _productFilter.isEmpty ||
          (yield.productName != null && yield.productName == _productFilter);

      if (!matchesProduct) return false;

      // Farmer filter
      final matchesFarmer = _farmerFilter == "All" ||
          _farmerFilter.isEmpty ||
          (yield.farmerId != null &&
              yield.farmerId.toString() == _farmerFilter);

      if (!matchesFarmer) return false;

      // Year filter
      final matchesYear = _yearFilter == "All" ||
          _yearFilter.isEmpty ||
          (yield.harvestDate != null &&
              yield.harvestDate.year.toString() == _yearFilter);

      if (!matchesYear) return false;

      // Barangay filter
      final matchesBarangay = _barangayFilter == "All" ||
          _barangayFilter.isEmpty ||
          (yield.barangay != null &&
              yield.barangay!.toLowerCase() == _barangayFilter.toLowerCase());

      if (!matchesBarangay) return false;

      // Status filter
      final matchesStatus = _statusFilter == "All" ||
          _statusFilter.isEmpty ||
          (yield.status != null &&
              yield.status!.toLowerCase() == _statusFilter.toLowerCase());

      if (!matchesStatus) return false;

      // Search filter
      if (_searchQuery.isEmpty) return true;

      final matchesSearch =
          (yield.notes?.toLowerCase().contains(_searchQuery) ?? false) ||
              (yield.farmerName?.toLowerCase().contains(_searchQuery) ??
                  false) ||
              (yield.sector?.toLowerCase().contains(_searchQuery) ?? false) ||
              (yield.barangay?.toLowerCase().contains(_searchQuery) ?? false) ||
              (yield.status?.toLowerCase().contains(_searchQuery) ?? false) ||
              (yield.harvestDate?.toString().contains(_searchQuery) ?? false) ||
              (yield.hectare?.toString().contains(_searchQuery) ?? false) ||
              (yield.id?.toString().contains(_searchQuery) ?? false) ||
              (yield.volume?.toString().contains(_searchQuery) ?? false) ||
              (yield.value?.toString().contains(_searchQuery) ?? false);

      return matchesSearch;
    }).toList();

    // Sorting logic
    if (_sortColumn != null) {
      filteredYields.sort((a, b) {
        int compareResult;
        switch (_sortColumn) {
          case 'Record Id':
            compareResult = a.id.compareTo(b.id);
            break;

          case 'Farmer Name':
            compareResult = (a.farmerName ?? '').compareTo(b.farmerName ?? '');
            break;

          case 'Product':
            compareResult =
                (a.productName ?? '').compareTo(b.productName ?? '');
            break;

          case 'Reported Yield':
            compareResult = a.harvestDate.compareTo(b.harvestDate);
            break;
          case 'Volume':
            compareResult = a.volume.compareTo(b.volume);
            break;
          case 'Value':
            compareResult = (a.value ?? 0).compareTo(b.value ?? 0);
            break;
          case 'Sector':
            compareResult = (a.sector ?? '').compareTo(b.sector ?? '');
            break;
          case 'Barangay':
            compareResult = (a.barangay ?? '').compareTo(b.barangay ?? '');
            break;
          case 'Status':
            compareResult = (a.status ?? '').compareTo(b.status ?? '');
            break;
          default:
            compareResult = 0;
        }
        return _sortAscending ? compareResult : -compareResult;
      });
    }

    return filteredYields;
  }
}
