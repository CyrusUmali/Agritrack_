import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/pages/farmers/add_farmer_modal_2.dart';
import 'package:flareline/pages/farmers/farmer/farmer_bloc.dart';
import 'package:flareline/pages/users/auth_service.dart';
import 'package:flareline/pages/users/link_modal.dart';
import 'package:flareline/pages/users/user_bloc/user_bloc.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/modal/modal_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void showFarmerOptionsModal(
  BuildContext context,
  String selectedRole,
  String selectedMethod,
  Function(
    String role,
    String method,
  ) onMethodSelected,
  Function() onLinkExistingFarmer, {
  List<Farmer> farmers = const [],
}) {
  final double screenWidth = MediaQuery.of(context).size.width;
  final bool isSmallScreen = screenWidth < 600;

  ModalDialog.show(
    context: context,
    title: 'Farmer Account Creation',
    showTitle: true,
    showTitleDivider: true,
    modalType: isSmallScreen ? ModalType.large : ModalType.medium,
    child: Padding(
      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedMethod == 'email'
                ? 'Create farmer account with email:'
                : 'Create farmer account with Google:',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          SizedBox(height: isSmallScreen ? 16.0 : 24.0),
          if (selectedMethod == 'email') ...[
            // Email account creation options
            Column(
              children: [
                ListTile(
                  leading: Icon(Icons.person_add),
                  title: Text('Create New Farmer Account'),
                  subtitle: Text('Register a completely new farmer'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // onMethodSelected(selectedRole, selectedMethod);

                    // For email/password auth
                    AddFarmerModal.show(
                      context: context,
                      onFarmerAdded: (farmer) {
                        context.read<UserBloc>().add(AddUser(
                              name: farmer.name,
                              email: farmer.email,
                              password: farmer.password,
                              role: selectedRole,
                              sector: farmer.sector,
                              phone: farmer.phone,
                              barangay: farmer.barangay,
                              photoUrl: farmer.imageUrl,
                            ));
                      },
                      authMethod: 'email',
                    );
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.link),
                  title: Text('Link to Existing Farmer Record'),
                  subtitle: Text('Connect account to farmer already in system'),
                  onTap: () {
                    Navigator.of(context).pop();
                    // onLinkExistingFarmer();

                    LinkUserModal.show(
                      context: context,
                      role: 'user',
                      farmers: farmers, // Pass the farmers list here
                      onUserLinked: (userData) {
                        context.read<UserBloc>().add(AddUser(
                            name: userData.name,
                            email: userData.email,
                            password: userData.password,
                            role: selectedRole,
                            farmerId: userData.farmerId));
                      },
                    );
                  },
                ),
              ],
            ),
          ] else ...[
            // Google account creation option
            Column(
              children: [
                ListTile(
                  leading: Icon(Icons.g_mobiledata),
                  title: Text('Create with Google'),
                  subtitle: Text('Sign up with Google account'),
                  onTap: () async {
                    Navigator.of(context).pop();

                    final googleUser =
                        await AuthService.getGoogleUserIsolated();

                    if (googleUser != null) {
                      // For email/password auth
                      AddFarmerModal.show(
                        context: context,
                        onFarmerAdded: (farmer) {
                          context.read<UserBloc>().add(AddUser(
                                name: farmer.name,
                                email: farmer.email,
                                role: selectedRole,
                                sector: farmer.sector,
                                idToken: googleUser['idToken'],
                                phone: farmer.phone,
                                barangay: farmer.barangay,
                                photoUrl: farmer.imageUrl,
                              ));
                        },
                        authMethod: 'google',
                        email: googleUser['email']!,
                      );
                    }
                  },
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.link),
                  title: Text('Link Google to Existing Farmer'),
                  subtitle:
                      Text('Connect Google account to existing farmer record'),
                  onTap: () async {
                    Navigator.of(context).pop();

                    final googleUser =
                        await AuthService.getGoogleUserIsolated();

                    if (googleUser != null) {
                      LinkUserModal.show(
                        context: context,
                        role: 'user',
                        farmers: farmers,
                        googleEmail: googleUser['email']!,
                        onUserLinked: (userData) {
                          context.read<UserBloc>().add(AddUser(
                              name: userData.name,
                              email: userData.email,
                              password: userData.password,
                              role: selectedRole,
                              idToken: googleUser['idToken'],
                              farmerId: userData.farmerId));
                        },
                      );

                      // For email/password auth
                      // AddFarmerModal.show(
                      //   context: context,
                      //   onFarmerAdded: (farmer) {
                      //     context.read<UserBloc>().add(AddUser(
                      //           name: farmer.name,
                      //           email: farmer.email,
                      //           role: selectedRole,
                      //           sector: farmer.sector,
                      //           idToken: googleUser['idToken'],
                      //           phone: farmer.phone,
                      //           barangay: farmer.barangay,
                      //           photoUrl: farmer.imageUrl,
                      //         ));
                      //   },
                      //   authMethod: 'google',
                      //   email: googleUser['email']!,
                      // );
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    ),
    footer: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 600 ? 10.0 : 20.0,
        vertical: 10.0,
      ),
    ),
  );
}
