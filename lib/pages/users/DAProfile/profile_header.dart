import 'package:flutter/material.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:provider/provider.dart';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isMobile;

  const ProfileHeader({super.key, required this.user, this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isCurrentUser = userProvider.user?.id == user['id'];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          SizedBox(
            height: isMobile ? 150 : 180,
            width: double.infinity,
            child: Image.asset(
              'assets/cover/cover-01.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: isMobile ? 40 : 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircleAvatar(
                radius: isMobile ? 48 : 60,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                child: ClipOval(
                  child: Image.asset(
                    'assets/user/user-01.png',
                    width: isMobile ? 80 : 100,
                    height: isMobile ? 80 : 100,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Text(
                    user['name'] ?? 'DA Officer',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          // fontWeight: FontWeight.bold,
                          color: Colors.white,   
                        ), 
                  ),
                  // Text(
                  //   user['position'] ?? 'Agricultural Officer',
                  //   style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  //         color: Theme.of(context)
                  //             .colorScheme
                  //             .onSurface
                  //             .withOpacity(0.8),
                  //       ),
                  // ),
                ],
              ),
            ),
          ),
          // if (isCurrentUser)
          //   Positioned(
          //     top: 16,
          //     right: 16,
          //     child: FilledButton.tonalIcon(
          //       onPressed: () {},
          //       icon: const Icon(Icons.edit),
          //       label: const Text('Edit Profile'),
          //     ),
          //   ),
        ],
      ),
    );
  }
}
