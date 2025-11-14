import 'package:flareline/pages/auth/forgot_password/forgot_password_provider.dart';
import 'package:flareline_uikit/core/mvvm/base_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flareline_uikit/components/buttons/button_widget.dart';
import 'package:flareline_uikit/components/card/common_card.dart';
import 'package:flareline_uikit/components/forms/outborder_text_form_field.dart';
import 'package:flareline/core/theme/global_colors.dart';
import 'package:flareline/flutter_gen/app_localizations.dart';
import 'package:responsive_builder/responsive_builder.dart';

class ForgotPasswordWidget extends BaseWidget<ForgotPasswordProvider> {
  @override
  Widget bodyWidget(
      BuildContext context, ForgotPasswordProvider viewModel, Widget? child) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image (same as sign in)
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
          // Content
          Center(
            child: SingleChildScrollView(
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
                          const SizedBox(height: 16),
                          SizedBox(
                            width: 80,
                            child: Image.asset('assets/DA_image.jpg'),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            viewModel.otpVerified
                                ? "Set New Password"
                                : viewModel.otpSent
                                    ? "Verify OTP"
                                    : "Reset Password",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            viewModel.otpVerified
                                ? "Enter your new password"
                                : viewModel.otpSent
                                    ? "Enter the OTP sent to your email"
                                    : "Enter your email to receive a password reset OTP",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildFormContent(context, viewModel),
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
  ForgotPasswordProvider viewModelBuilder(BuildContext context) {
    return ForgotPasswordProvider(context);
  }

  Widget _buildFormContent(
      BuildContext context, ForgotPasswordProvider viewModel) {
    if (viewModel.otpVerified) {
      return _buildResetPasswordForm(context, viewModel);
    } else if (viewModel.otpSent) {
      return _buildVerifyOtpForm(context, viewModel);
    } else {
      return _buildEmailForm(context, viewModel);
    }
  }

  Widget _buildEmailForm(
      BuildContext context, ForgotPasswordProvider viewModel) {
    final _formKey = GlobalKey<FormState>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutBorderTextFormField(
            labelText: "Email",
            hintText: "Enter your email address",
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
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
          const SizedBox(height: 30),
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              type: ButtonType.primary.type,
              btnText: "Send OTP",
              onTap: () async {
                if (_formKey.currentState!.validate()) {
                  await viewModel.sendResetOTP(context);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          // Back to sign in
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Remember your password?"),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popAndPushNamed('/signIn');
                },
                child: Text(
                  'Sign In',
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

  Widget _buildVerifyOtpForm(
      BuildContext context, ForgotPasswordProvider viewModel) {
    final _formKey = GlobalKey<FormState>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutBorderTextFormField(
            labelText: "OTP Code",
            hintText: "Enter 6-digit OTP",
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'OTP is required';
              }
              if (value.length != 6) {
                return 'OTP must be 6 digits';
              }
              return null;
            },
            controller: viewModel.otpController,
            showErrorText: true,
            errorBorderColor: Colors.red,
          ),
          const SizedBox(height: 30),
          // Verify Button
          SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              type: ButtonType.primary.type,
              btnText: "Verify OTP",
              onTap: () async {
                if (_formKey.currentState!.validate()) {
                  await viewModel.verifyOTP(context);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          // Resend OTP and back to email
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () async {
                  await viewModel.sendResetOTP(context);
                },
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: GlobalColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  viewModel.otpSent = false;
                  viewModel.notifyListeners();
                },
                child: Text(
                  'Change Email',
                  style: TextStyle(
                    color: GlobalColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetPasswordForm(
      BuildContext context, ForgotPasswordProvider viewModel) {
    final _formKey = GlobalKey<FormState>();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutBorderTextFormField(
            labelText: "New Password",
            hintText: "Enter your new password",
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }
              return null;
            },
            controller: viewModel.newPasswordController,
            showErrorText: true,
            errorBorderColor: Colors.red,
          ),
          const SizedBox(height: 20),
          OutBorderTextFormField(
            labelText: "Confirm Password",
            hintText: "Confirm your new password",
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != viewModel.newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            controller: viewModel.confirmPasswordController,
            showErrorText: true,
            errorBorderColor: Colors.red,
          ),
          const SizedBox(height: 30),
          // Reset Password Button
          SizedBox(
            width: double.infinity,
            child: ButtonWidget(
              type: ButtonType.primary.type,
              btnText: "Reset Password",
              onTap: () async {
                if (_formKey.currentState!.validate()) {
                  await viewModel.resetPassword(context);
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          // Back to sign in
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Remember your password?"),
              TextButton(
                onPressed: () {
                  Navigator.of(context).popAndPushNamed('/signIn');
                },
                child: Text(
                  'Sign In',
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
