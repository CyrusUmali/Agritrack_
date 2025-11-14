import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flareline/core/models/assocs_model.dart';
import 'package:flareline/repositories/assocs_repository.dart';

part 'assocs_event.dart';
part 'assocs_state.dart';

class AssocsBloc extends Bloc<AssocsEvent, AssocsState> {
  final AssociationRepository associationRepository;
  List<Association> _associations = [];
  String _searchQuery = '';

  AssocsBloc({required this.associationRepository}) : super(AssocsInitial()) {
    on<LoadAssocs>(_onLoadAssocs);
    on<CreateAssoc>(_onCreateAssoc);
    on<DeleteAssoc>(_onDeleteAssoc);
    on<GetAssocById>(_onGetAssocById);
    on<UpdateAssoc>(_onUpdateAssoc);
    on<SearchAssocs>(_onSearchAssocs);
    on<FilterAssocs>(_onFilterAssocs);
  }

  List<Association> get _filteredAssociations {
    return _associations.where((assoc) {
      final matchesSearch = _searchQuery.isEmpty ||
          assoc.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  Future<void> _onLoadAssocs(
    LoadAssocs event,
    Emitter<AssocsState> emit,
  ) async {
    emit(AssocsLoading());
    try {
      // print('here2');

      // print('Loading associations for year: ${event.year}');
      // Fetch associations for the selected year
      // print(event.year);

      _associations = await associationRepository.fetchAssociations(event.year);
      emit(AssocsLoaded(_filteredAssociations));
    } catch (e) {
      emit(AssocsError(e.toString()));
    }
  }

  Future<void> _onCreateAssoc(
    CreateAssoc event,
    Emitter<AssocsState> emit,
  ) async {
    emit(AssocsLoading());
    try {
      final newAssoc = await associationRepository.createAssociation(
        name: event.name,
        description: event.description,
      );

      _associations.add(newAssoc);
      emit(AssocsLoaded(
        _filteredAssociations,
        message: 'Association created successfully!',
      ));
    } catch (e) {
      emit(AssocsError('Failed to create association: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteAssoc(
    DeleteAssoc event,
    Emitter<AssocsState> emit,
  ) async {
    emit(AssocsLoading());
    try {
      await associationRepository.deleteAssociation(event.associationId);
      _associations.removeWhere((a) => a.id == event.associationId);
      emit(AssocsLoaded(_filteredAssociations,
          message: 'Association deleted successfully!'));
    } catch (e) {
      emit(AssocsError('Failed to delete association: ${e.toString()}'));
    }
  }

  Future<void> _onGetAssocById(
    GetAssocById event,
    Emitter<AssocsState> emit,
  ) async {
    emit(AssocsLoading());
    try {
      final association =
          await associationRepository.getAssociationById(event.associationId);
      emit(AssocLoaded(association));
    } catch (e) {
      emit(AssocsError(e.toString()));
    }
  }

  Future<void> _onUpdateAssoc(
    UpdateAssoc event,
    Emitter<AssocsState> emit,
  ) async {
    emit(AssocsLoading());
    try {
      final updatedAssoc =
          await associationRepository.updateAssociation(event.association);
      final index = _associations.indexWhere((a) => a.id == updatedAssoc.id);
      if (index != -1) {
        _associations[index] = updatedAssoc;
      }
      // emit(AssocOperationSuccess());
      emit(AssocOperationSuccess(updatedAssoc, 'Updated successfully!'));
    } catch (e) {
      emit(AssocsError('Failed to update association: ${e.toString()}'));
    }
  }

  Future<void> _onSearchAssocs(
    SearchAssocs event,
    Emitter<AssocsState> emit,
  ) async {
    _searchQuery = event.query;
    emit(AssocsLoaded(_filteredAssociations));
  }

  Future<void> _onFilterAssocs(
    FilterAssocs event,
    Emitter<AssocsState> emit,
  ) async {
    emit(AssocsLoaded(_filteredAssociations));
  }
}
