import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline_uikit/service/year_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/yields/yield_kpi.dart';
import 'package:flareline/pages/yields/yields_table.dart';
import 'package:flareline/repositories/yield_repository.dart';
import 'package:flareline/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:flareline/services/lanugage_extension.dart';

class YieldsPage extends LayoutWidget {
  const YieldsPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return context.translate('Yields');
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final farmerId = userProvider.farmer?.id?.toString();

    return RepositoryProvider(
      create: (context) => YieldRepository(apiService: ApiService()),
      child: BlocProvider(
        create: (context) => YieldBloc(
          yieldRepository: RepositoryProvider.of<YieldRepository>(context),
        )..add(farmerId != null
            ? LoadYieldsByFarmer(int.parse(farmerId))
            : LoadYields()),
        child: Builder(
          builder: (context) {
            return _YieldsContent(
                farmerId: farmerId != null ? int.parse(farmerId) : null);
          },
        ),
      ),
    );
  }
}

class _YieldsContent extends StatefulWidget {
  final int? farmerId;

  const _YieldsContent({this.farmerId});

  @override
  State<_YieldsContent> createState() => _YieldsContentState();
}

class _YieldsContentState extends State<_YieldsContent> {
  int selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Consumer<YearPickerProvider>(
          builder: (context, yearProvider, child) {
            return YieldKpi(
              selectedYear: yearProvider.selectedYear,
              farmerId: widget.farmerId, // Pass the farmerId here
            );
          },
        ),
        const SizedBox(height: 16),
        YieldsWidget(),
        const SizedBox(height: 16),
      ],
    );
  }
}
