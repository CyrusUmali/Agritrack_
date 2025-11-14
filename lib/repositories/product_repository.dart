import 'package:dio/dio.dart';
import 'package:flareline/core/models/product_model.dart'; 
import 'package:flareline/repositories/base_repository.dart'; // Import the base repository

class ProductRepository extends BaseRepository {
  ProductRepository({required super.apiService});

  Future<List<Product>> fetchProducts() async {
    try {
      checkAuthentication(); // Use inherited method

      final response = await apiService.get('/products/products');
      return _validateAndParseProductsResponse(response);
    } catch (e) {
      handleError(e, operation: 'load products'); // Use inherited method
    }
  }

  Future<Product> addProduct(Product product) async {
    try {
      checkAuthentication(); // Use inherited method
      _validateProductRequiredFields(product);

      final response = await apiService.post(
        '/products/products',
        data: _buildProductData(product),
      );

      return _validateAndParseProductResponse(response);
    } catch (e) {
      handleError(e, operation: 'add product'); // Use inherited method
    }
  }

  Future<Product> updateProduct(Product product) async {
    try {
      checkAuthentication(); // Use inherited method
      _validateProductRequiredFields(product);

      final response = await apiService.put(
        '/products/products/${product.id}',
        data: _buildProductData(product),
      );

      return _validateAndParseProductResponse(response);
    } catch (e) {
      handleError(e, operation: 'update product'); // Use inherited method
    }
  }

  // Helper method for product validation
  void _validateProductRequiredFields(Product product) {
    if (product.name == null || product.name!.isEmpty) {
      throw Exception('Product name is required');
    }
    if (product.sector == null || product.sector!.isEmpty) {
      throw Exception('Sector is required');
    }
  }

  // Helper method to build product data
  Map<String, dynamic> _buildProductData(Product product) {
    return {
      'name': product.name,
      'description': product.description,
      'sector_id': getSectorId(product.sector!), // Use inherited method
      'imageUrl': product.imageUrl,
    };
  }

  Future<void> deleteProduct(int productId) async {
    try {
      checkAuthentication(); // Use inherited method
      await apiService.delete('/products/products/$productId');
    } catch (e) {
      handleError(e, operation: 'delete product'); // Use inherited method
    }
  }

  // Helper method for response validation
  Product _validateAndParseProductResponse(Response response) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }
    
    if (response.data['product'] == null) {
      throw Exception('Invalid product data format received from server');
    }

    return Product.fromJson(response.data['product']);
  }

  // Helper method for products list validation
  List<Product> _validateAndParseProductsResponse(Response response) {
    if (response.data == null) {
      throw Exception('Server returned empty response');
    }
    
    if (response.data['products'] == null) {
      throw Exception('Invalid products data format received from server');
    }

    final productsData = response.data['products'] as List;
    return productsData.map((json) => Product.fromJson(json)).toList();
  }
}