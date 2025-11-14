// ignore_for_file: avoid_print

import 'package:flareline/pages/users/user_bloc/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flareline/pages/users/user_kpi.dart';
import 'package:flareline/pages/layout.dart';
import 'package:flareline/pages/users/users.dart';
import 'package:flareline/repositories/user_repository.dart';
import 'package:flareline/services/api_service.dart';

class UsersPage extends LayoutWidget {
  const UsersPage({super.key});

  @override
  String breakTabTitle(BuildContext context) {
    return 'Users';
  }

  @override
  Widget contentDesktopWidget(BuildContext context) {
    return RepositoryProvider(
      create: (context) => UserRepository(apiService: ApiService()),
      child: BlocProvider(
        create: (context) => UserBloc(
          userRepository: RepositoryProvider.of<UserRepository>(context),
        )..add(LoadUsers()),
        child: Builder(
          builder: (context) {
            return Column(
              children: [
             
                const UserKpi(),
                const SizedBox(height: 16),
                const Users(),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
