part of 'product_bloc.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductEvent {}

class AddProduct extends ProductEvent {
  final String name;
  final String description;
  final String category;
  final String? imageUrl;

  const AddProduct({
    required this.name,
    required this.description,
    required this.category,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [name, description, category, imageUrl];
}

class DeleteProduct extends ProductEvent {
  final int id;

  const DeleteProduct(this.id);

  @override
  List<Object> get props => [id];
}

class FilterProducts extends ProductEvent {
  final String sector;

  const FilterProducts(this.sector);

  @override
  List<Object> get props => [sector];
}

class SearchProducts extends ProductEvent {
  final String query;

  const SearchProducts(this.query);

  @override
  List<Object> get props => [query];
}

class EditProduct extends ProductEvent {
  final int id;
  final String name;
  final String category;
  final String? description;
  final String? imageUrl;

  const EditProduct({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, name, category, description, imageUrl];
}

class SortProducts extends ProductEvent {
  final String columnName;

  const SortProducts(this.columnName);

  @override
  List<Object> get props => [columnName];
}
