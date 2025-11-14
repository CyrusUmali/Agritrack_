import 'dart:convert';

import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/models/product_model.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flutter/services.dart';
import 'package:flareline/pages/test/map_widget/polygon_manager.dart';
import 'package:flareline/services/lanugage_extension.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'farm_info_card_components.dart';

class FarmInfoCard {
  static List<String> _barangays = [];

  static List<String> _lakes = [
    'Sampaloc Lake',
    'Bunot Lake',
    'Kalibato Lake',
    'Pandin Lake',
    'Yambo Lake',
    'Mojicap Lake',
    'Palakpakin Lake'
  ];

  static Future<void> loadBarangays() async {
    try {
      final jsonString = await rootBundle.loadString('assets/barangays.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      _barangays = List<String>.from(jsonData['barangays'] ?? []);
    } catch (e) {
      debugPrint('Error loading barangays: $e');
      _barangays = [];
    }
  }

  static Widget build({
    required BuildContext context,
    required PolygonData polygon,
    required ThemeData theme,
    required List<Product> products,
    required List<Farmer> farmers,
    required Function(String) onBarangayChanged,
    required Function(String) onLakeChanged,
    required Function(String) onFarmOwnerChanged,
    required Function(String) onFarmNameChanged,
    required Function(PolygonData) onFarmUpdated,
    required TextEditingController farmNameController,
  }) {
    final colorScheme = theme.colorScheme;

    final farmName = polygon.name ?? 'Unnamed Farm';
    final farmOwner = polygon.owner ?? 'Select owner';
    final description = polygon.description;
    final location = polygon.center != null
        ? 'Lat: ${polygon.center!.latitude.toStringAsFixed(4)}, Lng: ${polygon.center!.longitude.toStringAsFixed(4)}'
        : 'Location not set';
    final barangay = polygon.parentBarangay ?? 'Select barangay';
    final lake = polygon.lake ?? 'Select lake';
    final products = polygon.products ?? [];

    print('selected sector: ${polygon.pinStyle}');
    print('pinStyle type: ${polygon.pinStyle.runtimeType}');
    print('pinStyle toString: ${polygon.pinStyle.toString()}');
    print('Comparison result: ${polygon.pinStyle.toString() == 'Fishery'}');

    // Get farm owner names from the passed farmers list
    final farmOwnerNames = farmers.map((farmer) => farmer.name).toList();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.translate('Farm Information'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Divider(color: colorScheme.outlineVariant, height: 1),
            const SizedBox(height: 12),
            FarmInfoCardComponents.buildEditableFarmNameRow(
              context: context,
              controller: farmNameController,
              onNameChanged: onFarmNameChanged,
              theme: theme,
            ),

            // FarmInfoCardComponents.buildEditableFarmOwnerRow(
            //   context: context,
            //   currentOwner: farmOwner,
            //   ownerOptions: farmers,
            //   onOwnerChanged: onFarmOwnerChanged,
            //   theme: theme,
            //     isLoading: isLoadingFarmers, // Pass loading state
            // ),

            BlocBuilder<FarmerBloc, FarmerState>(
              builder: (context, farmerState) {
                bool isLoadingFarmers = farmerState is FarmersLoading;
                List<Farmer> farmers = [];

                if (farmerState is FarmersLoaded) {
                  farmers = farmerState.farmers;
                } else if (farmerState is FarmersError) {
                  // Handle error state - maybe show retry button
                  farmers = []; // or keep previous farmers if available
                }

                return FarmInfoCardComponents.buildEditableFarmOwnerRow(
                  context: context,
                  currentOwner: farmOwner,
                  ownerOptions: farmers,
                  onOwnerChanged: onFarmOwnerChanged,
                  theme: theme,
                  isLoading: isLoadingFarmers, // Pass loading state
                );
              },
            ),

            FarmInfoCardComponents.buildEditableBarangayRow(
              context: context,
              currentBarangay: barangay,
              barangayOptions: _barangays,
              onBarangayChanged: onBarangayChanged,
              theme: theme,
            ),
            // Conditionally render lake section based on pinStyle
            if (polygon.pinStyle?.toString() == 'PinStyle.Fishery')
              FarmInfoCardComponents.buildEditableLakeRow(
                context: context,
                currentLake: lake,
                lakeOptions: _lakes,
                onLakeChanged: onLakeChanged,
                theme: theme,
              ),
            FarmInfoCardComponents.buildInfoRow(
              icon: Icons.area_chart,
              label: 'Area',
              value: polygon.area != null ? '${polygon.area} Ha' : 'N/A',
              theme: theme,
            ),
            FarmInfoCardComponents.buildInfoRow(
              icon: Icons.location_on,
              label: 'Location',
              value: location,
              theme: theme,
            ),
            if (description != null && description.isNotEmpty)
              FarmInfoCardComponents.buildInfoRow(
                icon: Icons.description,
                label: 'Description',
                value: description,
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}
