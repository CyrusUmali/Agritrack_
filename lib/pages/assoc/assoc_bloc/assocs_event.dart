part of 'assocs_bloc.dart';

abstract class AssocsEvent extends Equatable {
  const AssocsEvent();

  @override
  List<Object?> get props => [];
}

// class LoadAssocs extends AssocsEvent {}



class LoadAssocs extends AssocsEvent {
  final int? year; // Add year parameter
  const LoadAssocs({this.year});
}
class CreateAssoc extends AssocsEvent {
  final String name;
  final String description;

  const CreateAssoc({required this.name, required this.description});

  @override
  List<Object> get props => [name, description];
}

// Add these new events:
class SearchAssocs extends AssocsEvent {
  final String query;

  const SearchAssocs(this.query);

  @override
  List<Object> get props => [query];
}

class FilterAssocs extends AssocsEvent {
  final String region;

  const FilterAssocs(this.region);

  @override
  List<Object> get props => [region];
}

class DeleteAssoc extends AssocsEvent {
  final int associationId;

  const DeleteAssoc(this.associationId);

  @override
  List<Object> get props => [associationId];
}

class GetAssocById extends AssocsEvent {
  final int associationId;

  const GetAssocById(this.associationId);

  @override
  List<Object> get props => [associationId];
}

class UpdateAssoc extends AssocsEvent {
  final Association association;

  const UpdateAssoc(this.association);

  @override
  List<Object> get props => [association];
}
