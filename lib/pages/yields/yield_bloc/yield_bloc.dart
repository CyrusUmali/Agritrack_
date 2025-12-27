import 'dart:async'; 
import 'package:flareline/repositories/yield_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flareline/core/models/yield_model.dart';

part 'yield_event.dart';
part 'yield_state.dart';

class YieldBloc extends Bloc<YieldEvent, YieldState> {
  final YieldRepository yieldRepository;
  int? _currentFarmerId; 


  Timer? _searchDebounceTimer;


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

  bool _isFarmerSpecific = false; 
   bool get isFarmerSpecific => _isFarmerSpecific;
 
   bool get isFarmSpecific => _isFarmerSpecific;

     bool _isFarmSpecific = false; 



Future<void> _onLoadYields(
    LoadYields event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());
    
    try {
      if (event.farmerId != null) {
        // Load yields for specific farmer
        _currentFarmerId = event.farmerId;
        _isFarmerSpecific = true;
        _yields = await yieldRepository.fetchYieldsByFarmer(event.farmerId!);
      } else {
        // Load all yields
        _currentFarmerId = null;
        _isFarmerSpecific = false;
        _yields = await yieldRepository.fetchYields();
      }
      
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      emit(YieldsError(e.toString()));
    }
  }


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

    // Use the indicator to determine what to refresh
    if (event.isFarmerSpecific) {
      // Load yields only for this farmer
      _currentFarmerId = event.farmerId;
      _isFarmerSpecific = true;
      _yields = await yieldRepository.getYieldByFarmId(event.farmId);
          _yields = await yieldRepository.fetchYieldsByFarmer(event.farmerId);
    }else if (event.isFarmSpecific){
 
      _isFarmSpecific = true;
      _yields = await yieldRepository.getYieldByFarmId(event.farmId);

    }
    
     else {
      // Load all yields
      _currentFarmerId = null;
      _isFarmerSpecific = false;
      _yields = await yieldRepository.fetchYields();
    }

    emit(YieldsLoaded(_applyFilters(),
        message: 'Yield record added successfully!'));
  } catch (e) {
    emit(YieldsError('Failed to add yield record: ${e.toString()}'));
  }
}

  // Update other methods to maintain consistency
  Future<void> _onDeleteYield(
    DeleteYield event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading()); 
    try {
      await yieldRepository.deleteYield(event.id);
      
  



    if (event.isFarmerSpecific) {
      // Load yields only for this farmer
      _currentFarmerId = event.farmerId;
      _isFarmerSpecific = true;
      _yields = await yieldRepository.getYieldByFarmId(event.farmId);
          _yields = await yieldRepository.fetchYieldsByFarmer(event.farmerId);
    }else if (event.isFarmSpecific){
 
      _isFarmSpecific = true;
      _yields = await yieldRepository.getYieldByFarmId(event.farmId);

    } 

 else {
      // Load all yields
      _currentFarmerId = null;
      _isFarmerSpecific = false;
      _yields = await yieldRepository.fetchYields();
    }
      
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
      if (kDebugMode) {
        print('Error in _onUpdateYield: $e');
      }
      if (e is Error) {
      }

      // Emit error state with user-friendly message
      emit(YieldsError('Failed to update yield record: ${e.toString()}'));
    }
  }


  Future<void> _onGetYieldByFarmId(
    GetYieldByFarmId event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());

    try {
      _yields =
          (await yieldRepository.getYieldByFarmId(event.farmId));

      // emit(YieldsLoaded(yieldRecord as List<Yield>));
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      emit(YieldsError(e.toString()));
    }
  }

  Future<void> _onGetYieldBybarangay(
    GetYieldByBarangay event,
    Emitter<YieldState> emit,
  ) async {
    emit(YieldsLoading());

    try {
      _yields = (await yieldRepository.getYieldByBarangay(event.barangay));

      // emit(YieldsLoaded(yieldRecord as List<Yield>));
      emit(YieldsLoaded(_applyFilters()));
    } catch (e) {
      emit(YieldsError(e.toString()));
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
      emit(YieldsError(e.toString()));
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
  _searchDebounceTimer?.cancel();
  
  // If query is empty, process immediately
  if (event.query.trim().isEmpty) {
    _searchQuery = '';
    emit(YieldsLoaded(_applyFilters()));
    return;
  }
  
  // Use a Completer to make the timer awaitable
  final completer = Completer<void>();
  
  _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
    if (!isClosed) {
      _searchQuery = event.query.trim().toLowerCase();
      emit(YieldsLoaded(_applyFilters()));
    }
    completer.complete();
  });
  
  // Wait for the timer to complete
  await completer.future;
}



  @override
  Future<void> close() {
    _searchDebounceTimer?.cancel();
    return super.close();
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
          (yield.farmerId.toString() == _farmerFilter);

      if (!matchesFarmer) return false;

      // Year filter
      final matchesYear = _yearFilter == "All" ||
          _yearFilter.isEmpty ||
          (yield.harvestDate.year.toString() == _yearFilter);

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


        if (kDebugMode) {
      print('Search query: $_searchQuery');
      print('Yield productName: ${yield.productName}');
      print('Yield farmerName: ${yield.farmerName}');
    }

      final matchesSearch =
          (yield.notes?.toLowerCase().contains(_searchQuery) ?? false) ||
              (yield.farmerName?.toLowerCase().contains(_searchQuery) ??
                  false) ||
              (yield.sector?.toLowerCase().contains(_searchQuery) ?? false) ||
              (yield.barangay?.toLowerCase().contains(_searchQuery) ?? false) ||
              (yield.status?.toLowerCase().contains(_searchQuery) ?? false) ||
              (yield.harvestDate.toString().contains(_searchQuery)) ||
              (yield.hectare?.toString().contains(_searchQuery) ?? false) ||
              (yield.id.toString().contains(_searchQuery)) ||
              (yield.volume.toString().contains(_searchQuery)) ||
              (yield.value?.toString().contains(_searchQuery) ?? false);
              (yield.productName?.toLowerCase().contains(_searchQuery) ?? false);

               if (kDebugMode) {
      print('Matches search: $matchesSearch');
    }

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
