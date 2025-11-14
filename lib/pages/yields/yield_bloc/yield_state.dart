part of 'yield_bloc.dart';

abstract class YieldState extends Equatable {
  const YieldState();

  @override
  List<Object> get props => [];
}

class YieldInitial extends YieldState {}

class YieldsLoading extends YieldState {}

class YieldsLoaded extends YieldState {
  final List<Yield> yields;

  final String? message;

  const YieldsLoaded(this.yields, {this.message});

  @override
  List<Object> get props => [yields, if (message != null) message!];
}

class YieldLoaded extends YieldState {
  final List<Yield> yields;
  final String? message;

  const YieldLoaded(this.yields, {this.message});

  @override
  List<Object> get props => [yields, if (message != null) message!];
}

class YieldsError extends YieldState {
  final String message;

  const YieldsError(this.message);

  @override
  List<Object> get props => [message];
}

class YieldUpdated extends YieldState {
  final Yield yield;
  final String message;

  const YieldUpdated(this.yield,
      {this.message = "Yield record updated successfully"});

  @override
  List<Object> get props => [yield, message];
}
