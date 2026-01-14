import 'dart:async';
import 'package:flareline/repositories/farmer_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flareline/core/models/farmer_model.dart';

part 'farmer_event.dart';
part 'farmer_state.dart';

class FarmerBloc extends Bloc<FarmerEvent, FarmerState> {
  final FarmerRepository farmerRepository;

  FarmerBloc({required this.farmerRepository}) : super(FarmerInitial()) {
    on<LoadFarmers>(_onLoadFarmers);
    on<AddFarmer>(_onAddFarmer);
    on<DeleteFarmer>(_onDeleteFarmer);
    on<FilterFarmers>(_onFilterFarmers);
    on<SearchFarmers>(_onSearchFarmers);
    on<SortFarmers>(_onSortFarmers);
    on<GetFarmerById>(_onGetFarmerById); // Add this line
    on<UpdateFarmer>(_onUpdateFarmer); // Add this line
  }

  List<Farmer> _farmers = [];
  String _searchQuery = '';
  String _sectorFilter = "All";
  String _associationFilter = "All";
   String _statusFilter = "All";
  String? _sortColumn;
  bool _sortAscending = true;
  String _barangayFilter = "All"; // Add this alongside other filter fields
  String get associationFilter => _associationFilter;
  String get barangayFilter => _barangayFilter; // Add this getter
  List<Farmer> get allFarmers => _farmers;
  String get sectorFilter => _sectorFilter;
   String get statusFilter => _statusFilter;
  String get searchQuery => _searchQuery;
  String? get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  Future<void> _onUpdateFarmer(
    UpdateFarmer event,
    Emitter<FarmerState> emit,
  ) async {
    emit(FarmersLoading());

    try {
      // print('Updating farmer: ${event.farmer.toJson()}'); // Log incoming data

      final updatedFarmer = await farmerRepository.updateFarmer(event.farmer);

      final index = _farmers.indexWhere((f) => f.id == updatedFarmer.id);
      if (index != -1) {
        _farmers[index] = updatedFarmer;
        // print('Farmer updated in local list at index $index');
      }

      emit(FarmerUpdated(updatedFarmer));

      emit(FarmerLoaded(updatedFarmer));
    } catch (e) {
      
      emit(FarmersError(e.toString()));
      // On error, try to reload the current farmer if we have an ID
      // Or fall back to the list view
    }
  }

  Future<void> _onGetFarmerById(
    GetFarmerById event,
    Emitter<FarmerState> emit,
  ) async {
    emit(FarmersLoading());

    try {
      final farmer = await farmerRepository.getFarmerById(event.id);
      emit(FarmerLoaded(farmer));
    } catch (e) {
      emit(FarmersError(e.toString()));
    }
  }

  Future<void> _onLoadFarmers(
    LoadFarmers event,
    Emitter<FarmerState> emit,
  ) async {
    emit(FarmersLoading());

    try {
      _farmers = await farmerRepository.fetchFarmers();
      emit(FarmersLoaded(_applyFilters()));
    } catch (e) {
      emit(FarmersError(e.toString()));
    }
  }

  Future<void> _onAddFarmer(
    AddFarmer event,
    Emitter<FarmerState> emit,
  ) async {
    emit(FarmersLoading());
    try {
      final newFarmer = Farmer(
        id: 4, // Let server assign ID (or generate UUID if needed)
        name: event.name,
        email: event.email ?? "---",
        phone: event.phone ?? "---", // Fallback to empty string if null
        barangay: event.barangay,
        sector: event.sector,
        imageUrl: event.imageUrl,
        // Add any other required fields here
      );

      await farmerRepository.addFarmer(newFarmer);
      _farmers = await farmerRepository.fetchFarmers(); // Refresh list
      emit(FarmersLoaded([..._applyFilters()],
          message: 'Farmer added successfully!'));
    } catch (e) {
      emit(FarmersError('Failed to add farmer: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteFarmer(
    DeleteFarmer event,
    Emitter<FarmerState> emit,
  ) async {
    emit(FarmersLoading());
    try {
      await farmerRepository.deleteFarmer(event.id);
      _farmers = _farmers.where((farmer) => farmer.id != event.id).toList();
      emit(FarmersLoaded(_applyFilters(),
          message: 'Farmer deleted successfully!'));
    } catch (e) {
      emit(FarmersError('Failed to delete farmer: ${e.toString()}'));
    }
  }

  Future<void> _onFilterFarmers(
      FilterFarmers event, Emitter<FarmerState> emit) async {
    // Handle sector filter
    _sectorFilter =
        (event.sector == null || event.sector!.isEmpty) ? "All" : event.sector!;

    // Handle barangay filter
    _barangayFilter = (event.barangay == null || event.barangay!.isEmpty)
        ? "All"
        : event.barangay!;

    // Handle association filter
    _associationFilter =
        (event.association == null || event.association!.isEmpty)
            ? "All"
            : event.association!;


          _statusFilter =
        (event.status == null || event.status!.isEmpty)
            ? "All"
            : event.status!;


    emit(FarmersLoaded(_applyFilters()));
  }

  Future<void> _onSearchFarmers(
      SearchFarmers event, Emitter<FarmerState> emit) async {
    _searchQuery = event.query.trim().toLowerCase();
    emit(FarmersLoaded(_applyFilters()));
  }

  Future<void> _onSortFarmers(
      SortFarmers event, Emitter<FarmerState> emit) async {
    if (_sortColumn == event.columnName) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = event.columnName;
      _sortAscending = true;
    }

    final filteredFarmers = _applyFilters();
    for (var i = 0;
        i < (filteredFarmers.length > 3 ? 3 : filteredFarmers.length);
        i++) {}

    emit(FarmersLoaded(filteredFarmers));
  }



List<Farmer> _applyFilters() {
  List<Farmer> filteredFarmers = _farmers.where((farmer) {
    // Debug information for each farmer
    bool debug = false; // Set to true for specific farmers you want to debug
    
    // Sector filter
    final matchesSector = _sectorFilter == "All" ||
        _sectorFilter.isEmpty ||
        (farmer.sector == _sectorFilter);

    if (!matchesSector) {
      if (debug) print('❌ Filtered out by sector');
      return false;
    }

    // Barangay filter
    final matchesBarangay = _barangayFilter == "All" ||
        _barangayFilter.isEmpty ||
        (farmer.barangay != null &&
            farmer.barangay!.toLowerCase() == _barangayFilter.toLowerCase());

    if (!matchesBarangay) {
      if (debug) print('❌ Filtered out by barangay');
      return false;
    }

    // Association filter
    final matchesAssociation = _associationFilter == "All" ||
        _associationFilter.isEmpty ||
        (farmer.association != null &&
            farmer.association!.toLowerCase() ==
                _associationFilter.toLowerCase());

    if (!matchesAssociation) {
      if (debug) print('❌ Filtered out by association');
      return false;
    }

    // Status filter - ADDED DEBUGGING
    final matchesStatus = _statusFilter == "All" ||
        _statusFilter.isEmpty ||
        (farmer.accountStatus != null &&
            farmer.accountStatus!.toLowerCase() ==
                _statusFilter.toLowerCase());

    if (!matchesStatus) {
      if (debug) {
        print('❌ Filtered out by status filter');
        print('   Farmer status: "${farmer.accountStatus}"');
        print('   Filter status: "$_statusFilter"');
        print('   Compare result: ${farmer.accountStatus?.toLowerCase() == _statusFilter.toLowerCase()}');
      }
      return false;
    }

    // Search filter - FIXED THE SYNTAX ERROR
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      final matchesSearch = 
          farmer.name.toLowerCase().contains(searchLower) ||
          (farmer.email?.toLowerCase().contains(searchLower) ?? false) ||
          (farmer.phone?.toLowerCase().contains(searchLower) ?? false) ||
          (farmer.barangay?.toLowerCase().contains(searchLower) ?? false) ||
          (farmer.sector.toLowerCase().contains(searchLower)) ||
          (farmer.association?.toLowerCase().contains(searchLower) ?? false) ||
          (farmer.accountStatus?.toLowerCase().contains(searchLower) ?? false); // FIXED: Removed extra semicolon

      if (!matchesSearch) {
        if (debug) print('❌ Filtered out by search query');
        return false;
      }
    }

    if (debug) print('✅ All filters passed');
    return true;
  }).toList();

  // Log filter results
  // print('Filter Results:');
  // print('  Total farmers: ${_farmers.length}');
  // print('  Filtered farmers: ${filteredFarmers.length}');
  // print('  Active filters:');
  // print('    - Sector: "$_sectorFilter"');
  // print('    - Barangay: "$_barangayFilter"');
  // print('    - Association: "$_associationFilter"');
  // print('    - Status: "$_statusFilter"');
  // print('    - Search query: "$_searchQuery"');

  // // Debug: Show status values of filtered farmers
  // print('  Status distribution in filtered results:');
  final statusCounts = <String, int>{};
  for (final farmer in filteredFarmers) {
    final status = farmer.accountStatus ?? 'null';
    statusCounts[status] = (statusCounts[status] ?? 0) + 1;
  }
  statusCounts.forEach((status, count) {
    // print('    - "$status": $count farmers');
  });

  // Sorting logic
  if (_sortColumn != null) {
    filteredFarmers.sort((a, b) {
      int compareResult;
      switch (_sortColumn) {
        case 'Name':
          compareResult = (a.name).compareTo(b.name);
          break;
        case 'Sector':
          compareResult = (a.sector).compareTo(b.sector);
          break;
        case 'Barangay':
          compareResult = (a.barangay ?? '').compareTo(b.barangay ?? '');
          break;
        case 'Status':
          compareResult = (a.accountStatus ?? '').compareTo(b.accountStatus ?? '');
          break;
        case 'Association':
          compareResult =
              (a.association ?? '').compareTo(b.association ?? '');
          break;
        default:
          compareResult = 0;
      }
      return _sortAscending ? compareResult : -compareResult;
    });
  }

  return filteredFarmers;
}


}
