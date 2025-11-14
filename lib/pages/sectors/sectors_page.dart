import 'package:flareline/pages/sectors/sectorKPI.dart';
import 'package:flareline_uikit/service/year_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/sectors/sector_table.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/sectors/sector_line_Chart.dart';
import 'package:flareline/pages/sectors/sector_bar_Chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline/repositories/yield_repository.dart';
import 'package:flareline/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flareline/services/lanugage_extension.dart';

class SectorsPage extends LayoutWidget {
  const SectorsPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return context.translate('Sectors');
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => YieldRepository(apiService: ApiService()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => YieldBloc(
              yieldRepository: RepositoryProvider.of<YieldRepository>(context),
            )..add(LoadYields()),
          ),
          // You could add a SectorBloc here if needed
        ],
        child: Builder(
          builder: (context) {
            return const _SectorsContent();
          },
        ),
      ),
    );
  }
}

class _SectorsContent extends StatefulWidget {
  const _SectorsContent();

  @override
  State<_SectorsContent> createState() => _SectorsContentState();
}

class _SectorsContentState extends State<_SectorsContent> {
  @override
  Widget build(BuildContext context) {
    // You can access the SectorService anywhere in this widget tree using:
    // final sectorService = RepositoryProvider.of<SectorService>(context);

    return Column(
      children: [
        const SectorKpi(),
        const SizedBox(height: 16),
        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            return SectorTableWidget(
              key: ValueKey(yearProvider.selectedYear), // This forces rebuild
              selectedYear: yearProvider.selectedYear,
            );
          },
        ),
        const SizedBox(height: 16),
        SectorLineChart(),
        const SizedBox(height: 16),
        SectorBarChart(),
      ],
    );
  }
}
