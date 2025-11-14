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
  String? _sortColumn;
  bool _sortAscending = true;
  String _barangayFilter = "All"; // Add this alongside other filter fields
  String get associationFilter => _associationFilter;
  String get barangayFilter => _barangayFilter; // Add this getter
  List<Farmer> get allFarmers => _farmers;
  String get sectorFilter => _sectorFilter;
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
      print('error her');
      print('Error updating farmer: $e');
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
      // Sector filter
      final matchesSector = _sectorFilter == "All" ||
          _sectorFilter.isEmpty ||
          (farmer.sector != null && farmer.sector == _sectorFilter);

      if (!matchesSector) {
        return false;
      }

      // Barangay filter
      final matchesBarangay = _barangayFilter == "All" ||
          _barangayFilter.isEmpty ||
          (farmer.barangay != null &&
              farmer.barangay!.toLowerCase() == _barangayFilter.toLowerCase());

      if (!matchesBarangay) {
        return false;
      }

      // Association filter
      final matchesAssociation = _associationFilter == "All" ||
          _associationFilter.isEmpty ||
          (farmer.association != null &&
              farmer.association!.toLowerCase() ==
                  _associationFilter.toLowerCase());

      if (!matchesAssociation) {
        return false;
      }

      // Search filter
      if (_searchQuery.isEmpty) {
        return true;
      }

      final matchesSearch = farmer.name.toLowerCase().contains(_searchQuery) ||
          (farmer.email?.toLowerCase().contains(_searchQuery) ?? false) ||
          (farmer.phone?.toLowerCase().contains(_searchQuery) ?? false) ||
          (farmer.barangay?.toLowerCase().contains(_searchQuery) ?? false) ||
          (farmer.sector?.toLowerCase().contains(_searchQuery) ?? false) ||
          (farmer.association?.toLowerCase().contains(_searchQuery) ?? false);

      return matchesSearch;
    }).toList();

    // Log filter results
    // print('Filter Results:');
    // print('  Total farmers: ${_farmers.length}');
    // print('  Filtered farmers: ${filteredFarmers.length}');
    // print('  Active filters:');
    // print('    - Sector: $_sectorFilter');
    // print('    - Barangay: $_barangayFilter');
    // print('    - Association: $_associationFilter');
    // print('    - Search query: "$_searchQuery"');
    // print('    - Sort column: $_sortColumn');
    // print('    - Sort ascending: $_sortAscending');

    // Sorting logic
    if (_sortColumn != null) {
      filteredFarmers.sort((a, b) {
        int compareResult;
        switch (_sortColumn) {
          case 'Farmer Name':
            compareResult = (a.name ?? '').compareTo(b.name ?? '');
            break;
          case 'Sector':
            compareResult = (a.sector ?? '').compareTo(b.sector ?? '');
            break;
          case 'Barangay':
            compareResult = (a.barangay ?? '').compareTo(b.barangay ?? '');
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

      // print(
      //     '  Sorting applied: $_sortColumn (${_sortAscending ? 'ascending' : 'descending'})');
    }

    return filteredFarmers;
  }
}
