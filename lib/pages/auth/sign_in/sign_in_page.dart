import 'package:flareline/pages/auth/sign_in/sign_in_provider.dart';
import 'package:flareline_uikit/core/mvvm/base_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/flutter_gen/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class SignInWidget extends BaseWidget<SignInProvider> {
  // Move the form key to widget level to prevent recreation on rebuilds
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget bodyWidget(
      BuildContext context, SignInProvider viewModel, Widget? child) {
    return Scaffold(
      // Add this to prevent keyboard issues
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/loginBG2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Color overlay/filter
          Container(
            color: Colors.black.withOpacity(0.2),
          ),
          // Your content
          Center(
            child: SingleChildScrollView(
              // Add physics to prevent keyboard bounce
              physics: ClampingScrollPhysics(),
              child: ResponsiveBuilder(
                builder: (context, sizingInfo) {
                  final maxWidth =
                      sizingInfo.isMobile ? double.infinity : 440.0;
                  return Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    margin: EdgeInsets.all(10),
                    child: CommonCard(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: sizingInfo.isMobile ? 20 : 20,
                      ),
                      borderRadius: 8.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Toggle button
                          if (kIsWeb)
                            Align(
                              alignment: Alignment.topRight,
                              child: _toggleButton(context, viewModel),
                            ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 80,
                            child: Image.asset('assets/DA_image.jpg'),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            "AgriTrack",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Show either sign-in form or download section
                          viewModel.showDownloadSection
                              ? _androidDownloadSection(context)
                              : _signInFormWidget(context, viewModel),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Loading indicator overlay
          if (viewModel.isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  @override
  SignInProvider viewModelBuilder(BuildContext context) {
    return SignInProvider(context);
  }

  Widget _toggleButton(BuildContext context, SignInProvider viewModel) {
    return GestureDetector(
      onTap: () {
        viewModel.toggleDownloadSection();
      },
      child: Container(
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          viewModel.showDownloadSection ? Icons.person : Icons.download,
          size: 16,
          color: GlobalColors.primary,
        ),
      ),
    );
  }

  Widget _androidDownloadSection(BuildContext context) {
    return Column(
      children: [
        Text(
          'Get the Mobile App',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Download AgriTrack mobile app for the best experience',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        // Download APK button
        GestureDetector(
          onTap: () async {
            // Replace with your actual APK download URL
            const apkUrl =
                'https://agritrack-server.onrender.com/download/apk/app-release.apk';

            try {
              if (await canLaunchUrl(Uri.parse(apkUrl))) {
                await launchUrl(
                  Uri.parse(apkUrl),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                // Show error message if URL can't be launched
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Unable to download app. Please try again later.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text('Download failed. Please check your connection.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  GlobalColors.primary,
                  GlobalColors.primary.withOpacity(0.8)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: GlobalColors.primary.withOpacity(0.3),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Download APK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Version 1.0 • Android 5.0+',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        // Back to sign in button
        TextButton(
          onPressed: () {
            // This will be handled by the toggle button, but adding for convenience
            final viewModel =
                Provider.of<SignInProvider>(context, listen: false);
            viewModel.toggleDownloadSection();
          },
          child: Text(
            'Back to Sign In',
            style: TextStyle(
              color: GlobalColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _signInFormWidget(BuildContext context, SignInProvider viewModel) {
    // Use the class-level form key instead of creating a new one
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutBorderTextFormField(
            labelText: "Username",
            hintText: "Enter your Username",
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Username is required';
              }
              return null;
            },
            suffixWidget: SvgPicture.asset(
              'assets/signin/email.svg',
              width: 22,
              height: 22,
            ),
            controller: viewModel.emailController,
            showErrorText: true,
            errorBorderColor: Colors.red,
          ),

          const SizedBox(height: 16),
          OutBorderTextFormField(
            obscureText: true,
            labelText: AppLocalizations.of(context)!.password,
            hintText: "Enter your Password",
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            suffixWidget: SvgPicture.asset(
              'assets/signin/lock.svg',
              width: 22,
              height: 22,
            ),
            controller: viewModel.passwordController,
            onFieldSubmitted: (value) {
              if (_formKey.currentState!.validate()) {
                viewModel.signIn(context);
              }
            },
            showErrorText: true,
            errorBorderColor: Colors.red,
          ),

          const SizedBox(height: 8),
          // Forgot password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/forgotPwd');
              },
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: GlobalColors.primary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Email/Password Sign In Button
          SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              type: ButtonType.primary.type,
              btnText: AppLocalizations.of(context)!.signIn,
              onTap: () {
                if (_formKey.currentState!.validate()) {
                  viewModel.signIn(context);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Expanded(
                  child: Divider(
                height: 1,
                color: GlobalColors.border,
              )),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  AppLocalizations.of(context)!.or,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const Expanded(
                  child: Divider(
                height: 1,
                color: GlobalColors.border,
              )),
            ],
          ),
          const SizedBox(height: 20),
          // Google Sign In Button
          SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              color: Colors.white,
              borderColor: GlobalColors.border,
              iconWidget: SvgPicture.asset(
                'assets/brand/brand-01.svg',
                width: 25,
                height: 25,
              ),
              btnText: AppLocalizations.of(context)!.signInWithGoogle,
              textColor: Colors.black87,
              onTap: () {
                viewModel.signInWithGoogle(context);
              },
            ),
          ),
          const SizedBox(height: 16),
          // Sign up prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account?"),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/signUp');
                },
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    color: GlobalColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

 