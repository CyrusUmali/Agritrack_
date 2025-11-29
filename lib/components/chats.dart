import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/flutter_gen/app_localizations.dart';
import 'package:flareline/pages/dashboard/yield_service.dart';
import 'package:flareline/pages/farmers/farmer_profile.dart';
import 'package:flareline/pages/widget/network_error.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TopContributorsWidget extends StatelessWidget {
  const TopContributorsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: context.read<YieldService>(),
      child: CommonCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Contributors',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Expanded(
                child: _TopContributorsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopContributorsList extends StatefulWidget {
  const _TopContributorsList();

  @override
  State<_TopContributorsList> createState() => _TopContributorsListState();
}

class _TopContributorsListState extends State<_TopContributorsList> {
  late Future<List<Map<String, dynamic>>> _contributorsFuture;

  @override
  void initState() {
    super.initState();
    _loadContributors();
  }

  void _loadContributors() {
    final yieldService = context.read<YieldService>();
    _contributorsFuture = yieldService.getTopContributors();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _contributorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(   child: CircularProgressIndicator());
        }


        if (snapshot.hasError) {
          return NetworkErrorWidget(
            error: snapshot.error.toString(),
            onRetry: () {
              setState(() {
                _loadContributors();
              });
            },
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No contributors found'));
        }

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => _ContributorItem(
            contributor: snapshot.data![index],
            index: index,
          ),
        );
      },
    );
  }
}

class _ContributorItem extends StatelessWidget {
  final Map<String, dynamic> contributor;
  final int index;

  const _ContributorItem({
    required this.contributor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColors = [
      GlobalColors.danger,
      GlobalColors.success,
      GlobalColors.warn,
      GlobalColors.primary,
      Colors.yellowAccent,
      Colors.pink,
    ];
    final badgeColor = badgeColors[index % badgeColors.length];

    // Safe parsing of farmerId
    final farmerId = contributor['farmerId']?.toString();
    final int? parsedFarmerID =
        farmerId != null ? int.tryParse(farmerId) : null;

   

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: badgeColor.withOpacity(0.2),
                  radius: 22,
                  child: Text(
                    contributor['farmerName']
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Badge(
                    backgroundColor: badgeColor,
                    // label: Text(contributor['yieldCount'].toString()),
                    child: const SizedBox(width: 16, height: 16),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(contributor['farmerName'].toString()),
                const SizedBox(height: 4),
                Text(
                  '${contributor['yieldCount']} entries ',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              // Only navigate if we have a valid farmerId
              if (parsedFarmerID != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmersProfile(
                      farmerID: parsedFarmerID,
                    ),
                  ),
                );
              } else {
                // Optional: Show a snackbar or log message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid farmer ID'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              height: 30,
              width: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey, width: 1),
              ),
              child: const Icon(
                Icons.more_horiz,
                color: Colors.grey,
                size: 16,
              ),
            ),
          )
        ],
      ),
    );
  }
}
