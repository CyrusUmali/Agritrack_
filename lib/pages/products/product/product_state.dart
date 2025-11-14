part of 'product_bloc.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object> get props => [];
}

class ProductInitial extends ProductState {}

class ProductsLoading extends ProductState {}

class ProductsLoaded extends ProductState {
  final List<Product> products;
  final String? message; // Add optional message

  const ProductsLoaded(this.products, {this.message});

  @override
  List<Object> get props => [products, if (message != null) message!];
}

class ProductsError extends ProductState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object> get props => [message];
}
