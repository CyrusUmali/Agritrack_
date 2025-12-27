import 'package:flareline/breaktab.dart';
import 'package:flareline/core/models/assocs_model.dart';
import 'package:flareline/pages/assoc/assoc_bloc/assocs_bloc.dart';
import 'package:flareline/pages/assoc/assoc_profile/assoc_kpi.dart';
import 'package:flareline/pages/assoc/assoc_profile/assoc_overview.dart';
import 'package:flareline/pages/assoc/assoc_profile/assoc_yield_data.dart';
import 'package:flareline/pages/assoc/assoc_profile/sector_header.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/services/lanugage_extension.dart'; 
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class AssocProfile extends LayoutWidget {
  final Association association;

  const AssocProfile({super.key, required this.association});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Association Profile';
  }

  @override
  List<BreadcrumbItem> breakTabBreadcrumbs(BuildContext context) {
    return [
      BreadcrumbItem(context.translate('Associations'), '/assocs'),
    ];
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return _AssocProfileContent(association: association, isMobile: false);
  }

  @override
  Widget contentMobileWidget(BuildContext context) {
    return _AssocProfileContent(association: association, isMobile: true);
  }
}

class _AssocProfileContent extends StatefulWidget {
  final Association association;
  final bool isMobile;

  const _AssocProfileContent({
    required this.association,
    required this.isMobile,
  });

  @override
  State<_AssocProfileContent> createState() => _AssocProfileContentState();
}

class _AssocProfileContentState extends State<_AssocProfileContent> {
  late Association _currentAssociation;
  late SectorService sectorService;

  @override
  void initState() {
    super.initState();
    _currentAssociation = widget.association; 
    sectorService = Provider.of<SectorService>(context, listen: false);
  }

  Widget _buildContent() {
    return BlocListener<AssocsBloc, AssocsState>(
      listener: (context, state) {
        if (state is AssocOperationSuccess) {
          setState(() {
            _currentAssociation = state.updatedAssoc;
          });
        }
      },
      child: SingleChildScrollView(
        child: Column(
          children: [
            AssociationHeader(
                association: _currentAssociation, isMobile: widget.isMobile),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AssocKpiCards(
                      association: _currentAssociation,
                      isMobile: widget.isMobile),
                  const SizedBox(height: 24),

                  // Overview Panel
                  AssociationOverviewPanel(
                    association: _currentAssociation,
                    isMobile: widget.isMobile,
                    onUpdateSuccess: () {},
                  ),

                  const SizedBox(height: 24),

                  // Yield Data Table
                  AssociationYieldDataTable(
                    associationId: _currentAssociation.id.toString(),
                    associationName: _currentAssociation.name,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }
}
