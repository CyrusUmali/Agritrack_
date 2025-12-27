import 'package:flareline/breaktab.dart';
import 'package:flareline/pages/recommendation/chatbot/chatbot_content.dart';
import 'package:flutter/material.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flareline/pages/yields/yield_bloc/yield_bloc.dart';
import 'package:flareline/repositories/yield_repository.dart';
import 'package:flareline/services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class ChatbotPage extends LayoutWidget {
  const ChatbotPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    // Use the special title to hide both back button and breadcrumbs
    return BreakTab.hideAllTitle;
  }
  @override
  bool get showTitle => false;
  @override
  Widget contentDesktopWidget(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final farmerId = userProvider.farmer?.id.toString();

    return RepositoryProvider(
      create: (context) => YieldRepository(apiService: ApiService()),
      child: BlocProvider(
        create: (context) {
          final bloc = YieldBloc(
            yieldRepository: RepositoryProvider.of<YieldRepository>(context),
          );
          
          // Only add LoadYieldsByFarmer event if farmerId is available
          if (farmerId != null && farmerId.isNotEmpty) {
            bloc.add(LoadYieldsByFarmer(int.parse(farmerId)));
          } else {
            // Otherwise load all yields
            bloc.add(LoadYields());
          }
          
          return bloc;
        },
        child: const ChatbotWidget(),
      ),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final farmerId = userProvider.farmer?.id.toString();

    return RepositoryProvider(
      create: (context) => YieldRepository(apiService: ApiService()),
      child: BlocProvider(
        create: (context) {
          final bloc = YieldBloc(
            yieldRepository: RepositoryProvider.of<YieldRepository>(context),
          );
          
          // Only add LoadYieldsByFarmer event if farmerId is available
          if (farmerId != null && farmerId.isNotEmpty) {
            bloc.add(LoadYieldsByFarmer(int.parse(farmerId)));
          } else {
            // Otherwise load all yields
            bloc.add(LoadYields());
          }
          
          return bloc;
        },
        child: const ChatbotWidget(),
      ),
    );
  }

  @override 
  EdgeInsetsGeometry? get customPadding => const EdgeInsets.only(top: 0);
}