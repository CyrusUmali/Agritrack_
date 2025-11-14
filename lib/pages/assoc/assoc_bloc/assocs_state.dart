part of 'assocs_bloc.dart';

abstract class AssocsState extends Equatable {
  const AssocsState();

  @override
  List<Object> get props => [];
}

class AssocsInitial extends AssocsState {}

class AssocsLoading extends AssocsState {}

class AssocsLoaded extends AssocsState {
  final List<Association> associations;
  final String? message;

  const AssocsLoaded(this.associations, {this.message});

  @override
  List<Object> get props => [associations, if (message != null) message!];
}

class AssocLoaded extends AssocsState {
  final Association association;

  const AssocLoaded(this.association);

  @override
  List<Object> get props => [association];
}



class AssocsError extends AssocsState {
  final String message;

  const AssocsError(this.message);

  @override
  List<Object> get props => [message];
}

class AssocOperationSuccess extends AssocsState {
  // final Association association;
    final Association updatedAssoc;
  final String message;

  const AssocOperationSuccess( this.updatedAssoc,this.message);

  @override
  List<Object> get props => [message];
}
