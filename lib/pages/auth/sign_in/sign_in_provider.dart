import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flareline/core/models/farmer_model.dart';
import 'package:flareline/services/api_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flareline/core/models/user_model.dart';
import 'package:flareline/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flareline_uikit/core/mvvm/base_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

class SignInProvider extends BaseViewModel { 
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth;
  final ApiService _apiService;
  final GoogleSignIn _googleSignIn;
  bool _showDownloadSection = false;
  bool get showDownloadSection => _showDownloadSection;

  void toggleDownloadSection() {
    _showDownloadSection = !_showDownloadSection;
    notifyListeners();
  }

  bool _testLoading = false;

  SignInProvider(super.ctx,
      {FirebaseAuth? auth, ApiService? apiService, GoogleSignIn? googleSignIn})
      : _auth = auth ?? FirebaseAuth.instance,
        _apiService = apiService ?? Provider.of<ApiService>(ctx, listen: false),
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: ['email', 'profile'],
            );

  Future<void> _handleSignInResponse(
      UserCredential userCredential, BuildContext context) async {
    try {
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token from Firebase');
      }

      final response = await _apiService.post(
        '/auth/login',
        data: {'firebaseToken': idToken},
      );

      final responseData = response.data;
      if (response.statusCode != 200) {
        throw Exception(
            'Server responded with status code ${response.statusCode}');
      }

      final userData = responseData['user'];
      if (userData == null) {
        throw Exception('User data not found in server response');
      }

      final farmerData = responseData['farmer'];

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setUser(UserModel.fromMap(userData));

      if (farmerData != null) {
        await userProvider.setFarmer(Farmer.fromMap(farmerData));
      }

      if (!_testLoading) {
        setLoading(false);
      }

      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      setLoading(false);
      String errorMsg;

      if (e is FirebaseAuthException) {
        errorMsg = _mapAuthError(e.code);
      } else if (e is DioException) {
        if (e.response != null) {
          if (e.response?.data is Map && e.response?.data['message'] != null) {
            errorMsg = e.response!.data['message'];
          } else {
            errorMsg =
                'Server error: ${e.response?.statusCode} - ${e.response?.statusMessage}';
          }
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMsg =
              'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.receiveTimeout) {
          errorMsg = 'Server took too long to respond. Please try again.';
        } else {
          errorMsg = 'Network error. Please check your connection.';
        }
      } else {
        errorMsg = 'An unexpected error occurred: ${e.toString()}';
      }

      _showErrorToast(context, errorMsg);

      // Sign out from both Firebase and Google if authentication fails
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.clearUser();
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      setLoading(true);

      GoogleSignInAccount? googleUser = _isWeb()
          ? await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn()
          : await _googleSignIn.signIn();

      if (googleUser == null) {
        setLoading(false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _handleSignInResponse(userCredential, context);
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      _showErrorToast(context, _mapAuthError(e.code));
    } catch (e) {
      setLoading(false);
      _showErrorToast(context, 'Google Sign-In error: ${e.toString()}');
    } finally {
      if (!_testLoading) {
        setLoading(false);
      }
    }
  }

  bool _isWeb() => identical(0, 0.0);

  void _showErrorToast(BuildContext context, String message) {
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text('Error'),
      description: Text(message),
      alignment: Alignment.topRight,
      autoCloseDuration: const Duration(seconds: 5),
      animationDuration: const Duration(milliseconds: 300),
      icon: const Icon(Icons.error),
      showProgressBar: true,
      closeButtonShowType: CloseButtonShowType.always,
      closeOnClick: false,
      pauseOnHover: true,
      dragToClose: true,
      applyBlurEffect: true,
    );
  }

  Future<void> signIn(BuildContext context) async {
    try {
      setLoading(true);
      debugPrint(
          'Attempting sign in with email: ${emailController.text.trim()}');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      debugPrint(
          'Firebase auth successful, proceeding to backend verification');
      await _handleSignInResponse(userCredential, context);
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      String errorMessage = _mapAuthError(e.code);
      _showErrorToast(context, errorMessage);
      debugPrint('Firebase Auth Error: ${e.code} - $errorMessage');
    } catch (e) {
      setLoading(false);
      _showErrorToast(
          context, 'Unexpected error during sign in: ${e.toString()}');
      debugPrint('Unexpected error during sign in: ${e.toString()}');
    }
  }

  String _mapAuthError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email address.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'invalid-email' => 'Invalid email format. Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled. Please contact support.',
      'invalid-credential' => 'Invalid login credentials. Please check your email and password.',
      'INVALID_LOGIN_CREDENTIALS' => 'Invalid login credentials. Please check your email and password.',
      'too-many-requests' => 'Too many unsuccessful login attempts. Please try again later or reset your password.',
      'operation-not-allowed' => 'Email/password sign-in is not enabled. Please contact support.',
      'network-request-failed' => 'Network error. Please check your internet connection.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}