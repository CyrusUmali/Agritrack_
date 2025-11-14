import 'package:flareline/pages/farms/farm_bloc/farm_bloc.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/farms/farms_kpi.dart';
import 'package:flareline/pages/farms/farms_table.dart';
import 'package:flareline/repositories/farm_repository.dart';
import 'package:flareline/services/api_service.dart';
import 'package:provider/provider.dart'; // Add this import
import 'package:flareline/services/lanugage_extension.dart';

class FarmsPage extends LayoutWidget {
  const FarmsPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return context.translate('Farms');
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return MultiProvider(
      // Wrap with MultiProvider if you have other providers
      providers: [
        RepositoryProvider(
          create: (context) => FarmRepository(apiService: ApiService()),
        ),
        // If UserProvider is already in the widget tree above, you don't need to add it here
      ],
      child: Builder(
        builder: (context) {
          // Get the UserProvider
          final userProvider =
              Provider.of<UserProvider>(context, listen: false);

          return BlocProvider(
            create: (context) {
              final farmBloc = FarmBloc(
                farmRepository: RepositoryProvider.of<FarmRepository>(context),
              );

              // Load farms with farmerId if user is a farmer
              int? farmerId;
              if (userProvider.isFarmer && userProvider.farmer != null) {
                farmerId =
                    userProvider.farmer!.id; // Make sure farmer.id is int
              }

              // Dispatch LoadFarms event with farmerId
              farmBloc.add(LoadFarms(farmerId: farmerId));

              return farmBloc;
            },
            child: Column(
              children: [
                if (!userProvider.isFarmer) const FarmKpi(),
                const SizedBox(height: 16),
                const FarmsTableWidget(),
              ],
            ),
          );
        },
      ),
    );
  }
}
