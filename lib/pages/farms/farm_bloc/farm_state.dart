part of 'farm_bloc.dart';

abstract class FarmState extends Equatable {
  const FarmState();

  @override
  List<Object> get props => [];
}

class FarmInitial extends FarmState {}

class FarmsLoading extends FarmState {}

class FarmsLoaded extends FarmState {
  final List<Farm> farms;
  final String? message;

  const FarmsLoaded(this.farms, {this.message});

  @override
  List<Object> get props => [farms, if (message != null) message!];
}

class FarmLoaded extends FarmState {
  final Farm farm;

  const FarmLoaded(this.farm);

  @override
  List<Object> get props => [farm];
}

class FarmsError extends FarmState {
  final String message;

  const FarmsError(this.message);

  @override
  List<Object> get props => [message];
}

class FarmUpdated extends FarmState {
  final Farm farm;
  final String message;

  const FarmUpdated(this.farm, {this.message = "Farm updated successfully"});

  @override
  List<Object> get props => [farm, message];
}
