// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/farmers/add_farmer_modal.dart';
import 'package:flareline/pages/farmers/grid_card.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/farmers/sector_farmers.dart';
import 'package:flareline/pages/sectors/year_filter_dropdown.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/repositories/farmer_repository.dart';
import 'package:flareline/services/api_service.dart';

class FarmersPage extends LayoutWidget {
  const FarmersPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Farmers';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return RepositoryProvider(
      create: (context) => FarmerRepository(apiService: ApiService()),
      child: BlocProvider(
        create: (context) => FarmerBloc(
          farmerRepository: RepositoryProvider.of<FarmerRepository>(context),
        )..add(LoadFarmers()),
        child: Builder(
          builder: (context) {
            return Column(
              children: [ 
                const FarmerKpi(),
                const SizedBox(height: 16),
                const FarmersPerSectorWidget(),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
