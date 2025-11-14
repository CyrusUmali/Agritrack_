part of 'farmer_bloc.dart';

abstract class FarmerState extends Equatable {
  const FarmerState();

  @override
  List<Object> get props => [];
}

class FarmerInitial extends FarmerState {}

class FarmersLoading extends FarmerState {}

class FarmersLoaded extends FarmerState {
  final List<Farmer> farmers;
  final String? message;

  const FarmersLoaded(this.farmers, {this.message});

  @override
  List<Object> get props => [farmers, if (message != null) message!];
}

class FarmerLoaded extends FarmerState {
  final Farmer farmer;

  const FarmerLoaded(this.farmer);

  @override
  List<Object> get props => [farmer];
}

class FarmersError extends FarmerState {
  final String message;

  const FarmersError(this.message);

  @override
  List<Object> get props => [message];
}

class FarmerUpdated extends FarmerState {
  final Farmer farmer;
  final String message;

  const FarmerUpdated(this.farmer,
      {this.message = "Farmer updated successfully"});

  @override
  List<Object> get props => [farmer, message];
}
