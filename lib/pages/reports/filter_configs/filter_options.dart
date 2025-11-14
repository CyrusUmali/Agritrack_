import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/farmers/farmer_data.dart';
import 'package:flareline/pages/farms/farm_bloc/farm_bloc.dart';
import 'package:flareline/pages/products/product/product_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class FilterOptions {
  static List<String> getFarms(BuildContext context, int? _farmerId) {
    final farmsState = context.read<FarmBloc>().state;

    if (farmsState is FarmsLoaded) {
      return farmsState.farms
          .where((farm) => _farmerId == null || farm.farmerId == _farmerId)
          .map((farm) => '${farm.id}: ${farm.name}')
          .toList();
    }

    // Fallback to empty list if farms aren't loaded yet
    return ['error'];
  }

  static List<String> getAssocs(BuildContext context) {
    final assocsState = context.read<AssocsBloc>().state;
    // debugPrint('Current AssocsBloc state: ${assocsState.runtimeType}');

    // Handle different states
    if (assocsState is AssocsInitial) {
      // debugPrint('Showing initial state');
      return ['Loading...'];
    }

    if (assocsState is AssocsLoading) {
      // debugPrint('Showing loading state');
      return ['Loading...'];
    }

    if (assocsState is AssocsLoaded) {
      // debugPrint(
      //     'Associations loaded, count: ${assocsState.associations.length}');
      return assocsState.associations
          .map((assoc) => '${assoc.id}: ${assoc.name}')
          .toList();
    }

    if (assocsState is AssocLoaded) {
      // Note: This is the single-association state
      final assoc = assocsState.association;
      // debugPrint('Single association loaded - ID: ${assoc.id}');
      return ['${assoc.id}: ${assoc.name}'];
    }

    if (assocsState is AssocsError) {
      // debugPrint('Error: ${assocsState.message}');
      return ['Error: ${assocsState.message}'];
    }

    // debugPrint('Unknown state: ${assocsState.runtimeType}');
    return ['No data available'];
  }

  static const Map<String, String> reportTypes = {
    'farmers': 'Farmers List',
    'farmer': 'Farmer Record',
    'products': 'Products & Yield',
    'barangay': 'Barangay Data',
    'sectors': 'Sector Performance',
  };

// Add this new method to get filtered report types
  static Map<String, String> getFilteredReportTypes(bool isFarmer) {
    if (isFarmer) {
      return {
        'farmer': 'Farmer Record',
      };
    } else {
      return reportTypes; // Show all reports for admin/non-farmers
    }
  }

  static List<String> get products {
    throw FlutterError('Use getProducts(context) instead of products');
  }

  // Add this new method
  static List<String> getProducts(BuildContext context) {
    final productState = context.read<ProductBloc>().state;

    if (productState is ProductsLoaded) {
      return productState.products
          .map((product) => '${product.id}: ${product.name}')
          .toList();
    }

    // Fallback to empty list if products aren't loaded yet
    return ['error'];
  }

  static List<String> getFarmers(BuildContext context) {
    final farmersState = context.read<FarmerBloc>().state;

    if (farmersState is FarmersLoaded) {
      return farmersState
          .farmers // Note: changed from 'farmer' to 'farmers' (assuming this is a list)
          .map((farmer) => '${farmer.id}: ${farmer.name}')
          .toList();
    }

    // Fallback to empty list if products aren't loaded yet
    return ['error'];
  }

  static List<String> get barangays => FarmerData.barangays;
  // static List<Map<String, dynamic>> get farmers => FarmerData.farmers;

  static const List<String> sectors = [
    '1:Rice',
    '2:Corn',
    '3:HVC',
    '4:Livestock',
    '5:Fishery',
    '6:Organic'
  ];

  static const List<String> Count = [
    '10',
    '50',
    '100',
    '200',
    '300',
    '400',
    '500',
  ];

  static const List<String> viewBy = [
    'Individual entries',
    'Monthly',
    'Yearly',
  ];

  // static const List<String> farms = ['Farm A', 'Farm B', 'Farm C', 'Farm D'];
}
