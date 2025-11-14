import 'package:flareline/pages/assoc/assoc_bar_chart.dart';
import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/pages/assoc/assocs_kpi.dart';
import 'package:flareline/pages/assoc/assocs_table.dart';
import 'package:flareline/repositories/assocs_repository.dart';
import 'package:flareline_uikit/service/year_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/services/api_service.dart';
import 'package:provider/provider.dart';

import 'package:flareline/services/lanugage_extension.dart';

class AssocsPage extends LayoutWidget {
  const AssocsPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return context.translate('Associations');
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return RepositoryProvider(
      create: (context) => AssociationRepository(apiService: ApiService()),
      child: Consumer<YearPickerProvider>(
        builder: (context, yearProvider, child) {
          return BlocProvider(
            create: (context) => AssocsBloc(
              associationRepository:
                  RepositoryProvider.of<AssociationRepository>(context),
            )..add(LoadAssocs(
                year: yearProvider.selectedYear)), // Use provider's year
            child: const _AssocsContent(),
          );
        },
      ),
    );
  }
}

class _AssocsContent extends StatelessWidget {
  const _AssocsContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AssocKpi(),
        const SizedBox(height: 16),
        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            // Listen to year changes and trigger Bloc event
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context
                  .read<AssocsBloc>()
                  .add(LoadAssocs(year: yearProvider.selectedYear));
            });
            return AssocsWidget(
              key: ValueKey(yearProvider.selectedYear),
              selectedYear: yearProvider.selectedYear,
            );
          },
        ),
        const SizedBox(height: 16),
        AssocsBarChart(),
        const SizedBox(height: 16),
      ],
    );
  }
}
