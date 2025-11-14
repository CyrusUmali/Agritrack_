import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/flutter_gen/app_localizations.dart';
import 'package:flareline_uikit/components/badge/anim_badge.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:provider/provider.dart';
import 'package:flareline/pages/farmers/farmer_profile.dart';

class FarmWorkersCard extends StatelessWidget {
  final Map<String, dynamic> farm;
  final bool isMobile;

  const FarmWorkersCard({
    super.key,
    required this.farm,
    this.isMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Farm Workers',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Removed Expanded and added a SizedBox with fixed height
            SizedBox(
              height: 300, // Set a reasonable height or use MediaQuery
              child: ChangeNotifierProvider(
                create: (context) => _FarmWorkersDataProvider(farm: farm),
                builder: (ctx, child) => _buildWidget(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidget(BuildContext context) {
    return FutureBuilder<List<Worker>>(
      future: context.read<_FarmWorkersDataProvider>().loadData(),
      builder: ((context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No workers assigned',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (c, index) {
            return itemBuilder(c, index, snapshot.data!.elementAt(index));
          },
          itemCount: snapshot.data!.length,
        );
      }),
    );
  }

  Widget itemBuilder(BuildContext context, int index, Worker worker) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FarmersProfile(farmerID: 1),
          ),
        );
      },
      child: Container(
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
                    backgroundColor: Colors.black,
                    child: Text(
                      worker.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    radius: 22,
                  ),
                  if (worker.isActive)
                    Align(
                      alignment: Alignment.bottomRight,
                      child: AnimBadge(
                        glowColor: GlobalColors.success,
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
                  Text(
                    worker.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    worker.role,
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class Worker {
  Worker({
    required this.name,
    required this.role,
    required this.isActive,
  });

  final String name;
  final String role;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
    };
  }
}

class _FarmWorkersDataProvider extends ChangeNotifier {
  final Map<String, dynamic> farm;
  List<Worker> workers = <Worker>[];

  _FarmWorkersDataProvider({required this.farm});

  Future<List<Worker>> loadData() async {
    await Future.delayed(const Duration(seconds: 1));

    final rawWorkers = farm['workers'] as List<dynamic>? ?? [];
    workers = rawWorkers.map((worker) {
      return Worker(
        name: worker['name'] ?? 'Unknown',
        role: worker['role'] ?? 'Worker',
        isActive: worker['isActive'] ?? false,
      );
    }).toList();

    return workers;
  }
}
