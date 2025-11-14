import 'dart:async';
import 'package:flareline/repositories/product_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flareline/core/models/product_model.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository productRepository;

  ProductBloc({required this.productRepository}) : super(ProductInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<EditProduct>(_onEditProduct);
    on<AddProduct>(_onAddProduct);
    on<DeleteProduct>(_onDeleteProduct);
    on<FilterProducts>(_onFilterProducts);
    on<SearchProducts>(_onSearchProducts);
    on<SortProducts>(_onSortProducts);
  }

  List<Product> _products = [];
  String _searchQuery = '';
  String _sectorFilter = "All";
  String? _sortColumn;
  bool _sortAscending = true;

  List<Product> get allProducts => _products;
  String get sectorFilter => _sectorFilter;
  String get searchQuery => _searchQuery;
  String? get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  Future<void> _onEditProduct(
    EditProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      final updatedProduct = Product(
        id: event.id,
        name: event.name,
        sector: event.category,
        description: event.description,
        imageUrl: event.imageUrl,
        createdAt: DateTime.now(), // or keep original creation date
      );

      await productRepository.updateProduct(updatedProduct);

      // Refresh the list from server or update locally
      _products = await productRepository.fetchProducts();

      emit(ProductsLoaded(_applyFilters(),
          message: 'Product updated successfully!'));
    } catch (e) {
      emit(ProductsError('Failed to update product: ${e.toString()}'));
    }
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      _products = await productRepository.fetchProducts();
      emit(ProductsLoaded(_applyFilters()));
    } catch (e) {
      emit(ProductsError(e.toString()));
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<ProductState> emit,
  ) async {
    // print('_onAddProduct: Emitting ProductsLoading');
    emit(ProductsLoading());
    try {
      final newProduct = Product(
        id: 0, // Let server assign ID
        name: event.name,
        sector: event.category,
        description: event.description,
        imageUrl: event.imageUrl,
        createdAt: DateTime.now(),
      );

      // print(newProduct);

      await productRepository.addProduct(newProduct);

      _products = await productRepository.fetchProducts(); // Refresh list

      emit(ProductsLoaded([..._applyFilters()],
          message: 'Product added successfully!')); // Include success message
    } catch (e) {
      // print('_onAddProduct: Error occurred - ${e.toString()}');
      emit(ProductsError('Failed to add product: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductsLoading());
    try {
      await productRepository.deleteProduct(event.id);

      _products = _products.where((product) => product.id != event.id).toList();

      emit(ProductsLoaded(_applyFilters(),
          message: 'Product deleted successfully!'));
    } catch (e) {
      emit(ProductsError('Failed to delete product: ${e.toString()}'));
    }
  }

  // The rest of the methods remain the same as before
  Future<void> _onFilterProducts(
      FilterProducts event, Emitter<ProductState> emit) async {
    _sectorFilter = event.sector;
    emit(ProductsLoaded(_applyFilters()));
  }

  Future<void> _onSearchProducts(
      SearchProducts event, Emitter<ProductState> emit) async {
    _searchQuery = event.query;
    emit(ProductsLoaded(_applyFilters()));
  }

  Future<void> _onSortProducts(
      SortProducts event, Emitter<ProductState> emit) async {
    if (_sortColumn == event.columnName) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = event.columnName;
      _sortAscending = true;
    }

    final filteredProducts = _applyFilters();
    for (var i = 0;
        i < (filteredProducts.length > 3 ? 3 : filteredProducts.length);
        i++) {}

    emit(ProductsLoaded(filteredProducts));
  }

  List<Product> _applyFilters() {
    List<Product> filteredProducts = _products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSector =
          _sectorFilter == "All" || product.sector == _sectorFilter;
      return matchesSearch && matchesSector;
    }).toList();

    if (_sortColumn != null) {
      filteredProducts.sort((a, b) {
        int compareResult;
        switch (_sortColumn) {
          case 'Product':
            compareResult = a.name.compareTo(b.name);

            break;
          case 'Sector':
            compareResult = a.sector.compareTo(b.sector);

            break;
          case 'Description':
            compareResult =
                (a.description ?? '').compareTo(b.description ?? '');

            break;
          default:
            compareResult = 0;
        }
        return _sortAscending ? compareResult : -compareResult;
      });
    }

    return filteredProducts;
  }
}
