import 'dart:async';

import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/core/theme/global_colors.dart'; 
import 'package:flareline/pages/farmers/add_farmer_modal_2.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/pages/users/add_user_modal.dart';
import 'package:flareline/pages/users/account_creation_modal.dart';
import 'package:flareline/pages/users/auth_service.dart';
import 'package:flareline/pages/users/da_personel_profile.dart';
import 'package:flareline/pages/users/farmer_option_modal.dart';
import 'package:flareline/pages/users/farmer_registration.dart';
import 'package:flareline/pages/users/user_bloc/user_bloc.dart';
import 'package:flareline/pages/widget/combo_box.dart';
import 'package:flareline/pages/widget/network_error.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/components/tables/table_widget.dart';
import 'package:flareline_uikit/entity/table_data_entity.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:flareline/pages/farmers/farmer_profile.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/core/theme/flareline_colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';

class Users extends StatefulWidget {
  const Users({super.key});

  @override
  State<Users> createState() => _UsersState();
}

class _UsersState extends State<Users> {
  String selectedRole = '';
  String selectedStatus = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<FarmerBloc>().add(LoadFarmers());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserBloc, UserState>(
      listener: (context, state) {
        if (state is UsersLoaded && state.message != null) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.flat,
            title: Text(state.message!),
            alignment: Alignment.topRight,
            showProgressBar: false,
            autoCloseDuration: const Duration(seconds: 3),
          );
        } else if (state is UsersError) {
          ToastHelper.showErrorToast(state.message, context, maxLines: 3);
        }
      },
      child: _channels(),
    );
  }

  _channels() {
    return ScreenTypeLayout.builder(
      desktop: _channelsWeb,
      mobile: _channelMobile,
      tablet: _channelMobile,
    );
  }

  Widget _channelsWeb(BuildContext context) {



 final screenHeight = MediaQuery.of(context).size.height;
   
 double height;
 

if (screenHeight < 400) {
  height = screenHeight * 0.6;  
} else if (screenHeight < 600) {
  height = screenHeight * 0.50;  
} else if (screenHeight < 800) {
  height = screenHeight * 0.56;  
} else if (screenHeight < 1500) {
  height = screenHeight * 0.63;  
}  else {
  height = screenHeight * 0.3;  
}




    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 800,
        // You can also set minHeight if needed
        // minHeight: 200,
      ),
      child: SizedBox(
        height: height,
        // height: MediaQuery.of(context).size.height * 0.70,
        child: Column(
          children: [
            _buildSearchBarDesktop(),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  if (state is UsersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is UsersError) {
                    return NetworkErrorWidget(
                      error: state.message,
                      onRetry: () {
                        context.read<UserBloc>().add(LoadUsers());
                      },
                    );
                  } else if (state is UsersLoaded) {
                    if (state.users.isEmpty) {
                      return _buildNoResultsWidget();
                    }
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DataTableWidget(
                            key: ValueKey(
                                'users_table_${state.users.length}_${context.read<UserBloc>().sortColumn}_${context.read<UserBloc>().sortAscending}'),
                            users: state.users
                                .map((user) => user.toJson())
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  }
                  return _buildNoResultsWidget();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelMobile(BuildContext context) {
    return Column(
      children: [
        _buildSearchBarMobile(),
        const SizedBox(height: 16),
        SizedBox(
          height: 500,
          child: BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UsersLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is UsersError) {
                return NetworkErrorWidget(
                  error: state.message,
                  onRetry: () {
                    context.read<UserBloc>().add(LoadUsers());
                  },
                );
              } else if (state is UsersLoaded) {
                if (state.users.isEmpty) {
                  return _buildNoResultsWidget();
                }
                return DataTableWidget(
                  key: ValueKey(
                      'users_table_${state.users.length}_${context.read<UserBloc>().sortColumn}_${context.read<UserBloc>().sortAscending}'),
                  users: state.users.map((user) => user.toJson()).toList(),
                );
              }
              return _buildNoResultsWidget();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.disabled_by_default,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Users found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filter criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBarMobile() {
    return SizedBox(
      height: 50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          direction: Axis.horizontal,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8, // Vertical spacing between lines when wrapping
          children: [
            // Role ComboBox
            buildComboBox(
              context: context,
              hint: 'User Role',
              options: const ['All', 'Admin', 'Officer', 'Farmer'],
              selectedValue: selectedRole,
              onSelected: (value) {
                setState(() => selectedRole = value);
                context.read<UserBloc>().add(FilterUsers(
                      role: (value == 'All' || value.isEmpty) ? null : value,
                      status: selectedStatus,
                      query: _searchQuery,
                    ));
              },
              width: 150,
            ),

            // Status ComboBox
            buildComboBox(
              context: context,
              hint: 'Status',
              options: const ['All', 'Active', 'Pending', 'Inactive'],
              selectedValue: selectedStatus,
              onSelected: (value) {
                setState(() => selectedStatus = value);
                context.read<UserBloc>().add(FilterUsers(
                      role: selectedRole,
                      status: (value == 'All' || value.isEmpty) ? null : value,
                      query: _searchQuery,
                    ));
              },
              width: 150,
            ),

            // Search Field
            Container(
              width: 200,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Colors.white, // Use card color from theme
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).cardTheme.surfaceTintColor ??
                      Colors.grey[300]!, // Use border color from theme
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).cardTheme.shadowColor ??
                        Colors.transparent,
                    blurRadius: 13,
                    offset: const Offset(0, 8),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: TextField(
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color, // Use text color from theme
                ),
                decoration: InputDecoration(
                  hintText: 'Search yields...',
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .hintColor, // Use hint color from theme
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Theme.of(context)
                        .iconTheme
                        .color, // Use icon color from theme
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  context.read<UserBloc>().add(SearchUsers(value));
                },
              ),
            ),

            // Add User Button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GlobalColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: () async {
                  // Show loading indicator while ensuring data is fresh

                  // Refresh the farmer list
                  context.read<FarmerBloc>().add(LoadFarmers());

                  // Wait for the load to complete if not already loaded
                  if (context.read<FarmerBloc>().state is! FarmersLoaded) {
                    await Future.delayed(const Duration(milliseconds: 100));
                  }

                  AccountCreationMethodModal.show(
                    context: context,
                    onMethodSelected: (role, method) async {
                      if (role == 'admin' || role == 'officer') {
                        if (method == 'email') {
                          AddUserModal.show(
                            context: context,
                            role: role,
                            onUserAdded: (userData) { 
                              context.read<UserBloc>().add(AddUser(
                                  name: userData.name,
                                  email: userData.email,
                                  password: userData.password,
                                  role: userData.role));
                            },
                          );
                        } else {
                          final googleUser =
                              await AuthService.getGoogleUserIsolated();
                          if (googleUser != null) { 
                            context.read<UserBloc>().add(AddUser(
                                  name: googleUser['name']!,
                                  email: googleUser['email']!,
                                  idToken: googleUser['idToken'],
                                  role: role,
                                ));
                          }
                        }
                      } else if (role == 'farmer') {
                        showFarmerOptionsModal(context, 'farmer', method,
                            (String role, String method) {
                          
                        }, () {
                    
                        },
                            farmers: (context.read<FarmerBloc>().state
                                    is FarmersLoaded
                                ? () {
                                    final allFarmers = (context
                                            .read<FarmerBloc>()
                                            .state as FarmersLoaded)
                                        .farmers;
                                    return allFarmers
                                        .where((farmer) =>
                                            farmer.userId == null ||
                                            farmer.userId == 0)
                                        .toList();
                                  }()
                                : <Farmer>[]));
                      }
                    },
                    onLinkExistingFarmer: () {
                      AddFarmerModal.show(
                        context: context,
                        onFarmerAdded: (farmerData) {
                          context.read<FarmerBloc>().add(AddFarmer(
                                name: farmerData.name,
                                email: farmerData.email,
                                sector: farmerData.sector,
                                phone: farmerData.phone,
                                barangay: farmerData.barangay,
                                imageUrl: farmerData.imageUrl,
                              ));
                        },
                      );
                    },
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add,
                        size: 20, color: FlarelineColors.background),
                    SizedBox(width: 4),
                    Text("Add User", style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBarDesktop() {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Role ComboBox
          buildComboBox(
            context: context,
            hint: 'User Role',
            options: const ['All', 'Admin', 'Officer', 'Farmer'],
            selectedValue: selectedRole,
            onSelected: (value) {
              setState(() => selectedRole = value);
              context.read<UserBloc>().add(FilterUsers(
                    role: (value == 'All' || value.isEmpty) ? null : value,
                    status: selectedStatus,
                    query: _searchQuery,
                  ));
            },
            width: 150,
          ),
          const SizedBox(width: 8),

          // Status ComboBox
          buildComboBox(
            context: context,
            hint: 'Status',
            options: const ['All', 'Active', 'Pending', 'Inactive'],
            selectedValue: selectedStatus,
            onSelected: (value) {
              setState(() => selectedStatus = value);
              context.read<UserBloc>().add(FilterUsers(
                    role: selectedRole,
                    status: (value == 'All' || value.isEmpty) ? null : value,
                    query: _searchQuery,
                  ));
            },
            width: 150,
          ),
          const SizedBox(width: 8),

          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color ??
                    Colors.white, // Use card color from theme
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).cardTheme.surfaceTintColor ??
                      Colors.grey[300]!, // Use border color from theme
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).cardTheme.shadowColor ??
                        Colors.transparent,
                    blurRadius: 13,
                    offset: const Offset(0, 8),
                    spreadRadius: -3,
                  ),
                ],
              ),
              child: TextField(
                style: TextStyle(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color, // Use text color from theme
                ),
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(
                    color: Theme.of(context)
                        .hintColor, // Use hint color from theme
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: Theme.of(context)
                        .iconTheme
                        .color, // Use icon color from theme
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  context.read<UserBloc>().add(SearchUsers(value));
                },
              ),
            ),
          ),

          // Add User Button
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GlobalColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              onPressed: () async {
                // Show loading indicator while ensuring data is fresh

                // Refresh the farmer list
                context.read<FarmerBloc>().add(LoadFarmers());

                // Wait for the load to complete if not already loaded
                if (context.read<FarmerBloc>().state is! FarmersLoaded) {
                  await Future.delayed(const Duration(milliseconds: 100));
                }

                AccountCreationMethodModal.show(
                  context: context,
                  onMethodSelected: (role, method) async {
                    if (role == 'admin' || role == 'officer') {
                      if (method == 'email') {
                        AddUserModal.show(
                          context: context,
                          role: role,
                          onUserAdded: (userData) { 
                            context.read<UserBloc>().add(AddUser(
                                name: userData.name,
                                email: userData.email,
                                password: userData.password,
                                role: userData.role));
                          },
                        );
                      } else {
                        final googleUser =
                            await AuthService.getGoogleUserIsolated();
                        if (googleUser != null) { 
                          context.read<UserBloc>().add(AddUser(
                                name: googleUser['name']!,
                                email: googleUser['email']!,
                                idToken: googleUser['idToken'],
                                role: role,
                              ));
                        }
                      }
                    } else if (role == 'farmer') {
                      // if (method == 'email') {
                      showFarmerOptionsModal(context, 'farmer', method,
                          // Callback when a method is selected
                          (String role, String method) { 
                        // Handle the method selection here
                      },
                          // Callback for linking existing farmer
                          () {
                     
                        // Handle linking existing farmer here
                      },

                          // Pass the farmers data from the FarmerBloc
                          farmers:
                              (context.read<FarmerBloc>().state is FarmersLoaded
                                  ? () {
                                      final allFarmers = (context
                                              .read<FarmerBloc>()
                                              .state as FarmersLoaded)
                                          .farmers;
                                      final filteredFarmers = allFarmers
                                          .where((farmer) =>
                                              farmer.userId == null ||
                                              farmer.userId == 0)
                                          .toList();

                                      return filteredFarmers;
                                    }()
                                  : <Farmer>[]));
                    }
                  },
                  onLinkExistingFarmer: () {
                    AddFarmerModal.show(
                      context: context,
                      onFarmerAdded: (farmerData) {
                        context.read<FarmerBloc>().add(AddFarmer(
                              name: farmerData.name,
                              email: farmerData.email,
                              sector: farmerData.sector,
                              phone: farmerData.phone,
                              barangay: farmerData.barangay,
                              imageUrl: farmerData.imageUrl,
                            ));
                      },
                    );
                  },
                );
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 20, color: FlarelineColors.background),
                  SizedBox(width: 4),
                  Text("Add User", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataTableWidget extends TableWidget<UsersViewModel> {
  final List<Map<String, dynamic>> users;

  DataTableWidget({
    required this.users,
     super.key,
  });

  @override
  UsersViewModel viewModelBuilder(BuildContext context) {
    return UsersViewModel(context, users);
  }

  @override
  Widget headerBuilder(
      BuildContext context, String headerName, UsersViewModel viewModel) {
    if (headerName == 'Action') {
      return Text(headerName);
    }

    return InkWell(
      onTap: () {
        context.read<UserBloc>().add(SortUsers(headerName));
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              headerName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UsersLoaded) {
                final bloc = context.read<UserBloc>();
                return Icon(
                  bloc.sortColumn == headerName
                      ? (bloc.sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 16,
                  color: bloc.sortColumn == headerName
                      ? Theme.of(context).primaryColor
                      : Colors.grey,
                );
              }
              return const Icon(Icons.unfold_more,
                  size: 16, color: Colors.grey);
            },
          ),
        ],
      ),
    );
  }




   @override
  void onCellTap(BuildContext context, TableDataRowsTableDataRows columnData, UsersViewModel viewModel) {
 
        final user = viewModel.users.firstWhere(
      (u) => u['id'].toString() == columnData.id,
    );

      final role = (user['role'] ?? '').toLowerCase();
            final status = (user['Status'] ?? '').toLowerCase();
 

   
 


            if (role.contains('farmer') && status.contains('pending')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FarmerRegistrationPage(farmerData: user),
                ),
              );
            } else if (role.contains('officer') || role.contains('admin')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DAOfficerProfile(daUser: user),
                ),
              );
            } else if (role.contains('farmer')) {
 
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FarmersProfile(farmerID: user['farmerId'] as int),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DAOfficerProfile(daUser: user),
                ),
              );
            }



  } 


  @override
  Widget actionWidgetsBuilder(
    BuildContext context,
    TableDataRowsTableDataRows columnData,
    UsersViewModel viewModel,
  ) {
    final user = viewModel.users.firstWhere(
      (u) => u['id'].toString() == columnData.id,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            ModalDialog.show(
              context: context,
              title: 'Delete User',
              showTitle: true,
              showTitleDivider: true,
              modalType: ModalType.medium,
              onCancelTap: () => Navigator.of(context).pop(),
              onSaveTap: () {
                context.read<UserBloc>().add(DeleteUser(user['id'] as int));
                Navigator.of(context).pop();
              },
              child: Center(
                child: Text('Are you sure you want to delete this'),
              ),
              footer: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120,
                        child: ButtonWidget(
                          btnText: 'Cancel',
                          textColor: FlarelineColors.darkBlackText,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 120,
                        child: ButtonWidget(
                          btnText: 'Delete',
                          onTap: () {
                            context
                                .read<UserBloc>()
                                .add(DeleteUser(user['id'] as int));
                            Navigator.of(context).pop();
                          },
                          type: ButtonType.primary.type,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_sharp),
          onPressed: () {
            final role = (user['role'] ?? '').toLowerCase();
            final status = (user['Status'] ?? '').toLowerCase();
 

            if (role.contains('farmer') && status.contains('pending')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FarmerRegistrationPage(farmerData: user),
                ),
              );
            } else if (role.contains('officer') || role.contains('admin')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DAOfficerProfile(daUser: user),
                ),
              );
            } else if (role.contains('farmer')) {

 
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      FarmersProfile(farmerID: user['farmerId'] as int),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DAOfficerProfile(daUser: user),
                ),
              );
            }



          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      desktop: _buildDesktopTable,
      mobile: _buildMobileTable,
      tablet: _buildMobileTable,
    );
  }

  Widget _buildDesktopTable(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double tableWidth = constraints.maxWidth > 1200
            ? 1200
            : constraints.maxWidth > 800
                ? constraints.maxWidth * 0.9
                : constraints.maxWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: SizedBox(
              width: tableWidth,
              child: super.build(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileTable(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 800,
        child: super.build(context),
      ),
    );
  }
}

class UsersViewModel extends BaseTableProvider {
  final List<Map<String, dynamic>> users;

  UsersViewModel(super.context, this.users);

  @override
  Future loadData(BuildContext context) async {
    const headers = ["Name", "UserRole", "Email", "Status", "Action"];

    List<List<TableDataRowsTableDataRows>> rows = [];

    for (var user in users) {
      List<TableDataRowsTableDataRows> row = [];
 
      var userNameCell = TableDataRowsTableDataRows()
        ..text = user['name']
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Name'
        ..id = user['id'].toString();
      row.add(userNameCell);

      // User Role
      var roleCell = TableDataRowsTableDataRows()
        ..text = user['role']
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'role'
        ..id = user['id'].toString();
      row.add(roleCell);

      // Email
      var emailCell = TableDataRowsTableDataRows()
        ..text = user['email']
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'email'
        ..id = user['id'].toString();
      row.add(emailCell);

      // Status
      var statusCell = TableDataRowsTableDataRows()
        ..text = user['status']
        ..dataType = CellDataType.TEXT.type
        ..columnName = 'Status'
        ..id = user['id'].toString();
      row.add(statusCell);

      // Action
      var actionCell = TableDataRowsTableDataRows()
        ..text = ""
        ..dataType = CellDataType.ACTION.type
        ..columnName = 'Action'
        ..id = user['id'].toString();
      row.add(actionCell);

      rows.add(row);
    }

    TableDataEntity tableData = TableDataEntity()
      ..headers = headers
      ..rows = rows;

    tableDataEntity = tableData;
  }
}
