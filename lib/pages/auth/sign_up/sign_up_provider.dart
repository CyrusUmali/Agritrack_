import 'package:dio/dio.dart';
import 'package:flareline/pages/sectors/sector_service.dart';
import 'package:flareline/pages/toast/toast_helper.dart';
import 'package:flareline/services/api_service.dart';
import 'package:flareline_uikit/core/mvvm/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class SignUpProvider extends BaseViewModel {
  int currentStep = 0;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  String? _associationsLoadError;
  String? get associationsLoadError => _associationsLoadError;

  // Account Info
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController rePasswordController;

  bool _isPendingVerification = false;
  bool get isPendingVerification => _isPendingVerification;

  // Personal Info
  late TextEditingController firstNameController;
  late TextEditingController middleNameController;
  late TextEditingController lastNameController;
  late TextEditingController extensionController;
  late TextEditingController spouseNameController;
  String? sex;
  String? civilStatus;
  late TextEditingController birthDateController;

  // Household Info
  late TextEditingController householdHeadController;
  late TextEditingController householdNumController;
  late TextEditingController maleMembersController;
  late TextEditingController femaleMembersController;
  late TextEditingController motherMaidenNameController;
  late TextEditingController religionController;

  // Contact Info
  late TextEditingController barangayController;
  late TextEditingController associationController;
  late TextEditingController sectorController;
  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController personToNotifyController;
  late TextEditingController ptnContactController;
  late TextEditingController ptnRelationshipController;

  SignUpProvider(super.context) {
    // Initialize all controllers
    emailController = TextEditingController();
    passwordController = TextEditingController();
    rePasswordController = TextEditingController();

    firstNameController = TextEditingController();
    middleNameController = TextEditingController();
    lastNameController = TextEditingController();
    extensionController = TextEditingController();
    spouseNameController = TextEditingController();
    birthDateController = TextEditingController();

    householdHeadController = TextEditingController();
    householdNumController = TextEditingController();
    maleMembersController = TextEditingController();
    femaleMembersController = TextEditingController();
    motherMaidenNameController = TextEditingController();
    religionController = TextEditingController();

    barangayController = TextEditingController();
    associationController = TextEditingController();
    sectorController = TextEditingController();
    addressController = TextEditingController();
    phoneController = TextEditingController();
    personToNotifyController = TextEditingController();
    ptnContactController = TextEditingController();
    ptnRelationshipController = TextEditingController();
  }

// In SignUpProvider, add:
  List<String> associationOptions = [];
  bool isLoadingAssociations = false;

  // Add a method to initialize data
  Future<void> initialize(SectorService sectorService) async {
    await loadAssociations(sectorService);
  }

  Future<void> loadAssociations(SectorService sectorService) async {
    isLoadingAssociations = true;
    notifyListeners();

    try {
      final associations = await sectorService.fetchAssociations2();
      // print('assoc success');
      associationOptions =
          associations.map((a) => '${a.id}: ${a.name}').toList();
      _associationsLoadError = null;

      // print(associationOptions);
    } catch (e) {
      print('Error loading associations: $e');

      print('assoc errorr');
      // associationOptions = [];

      _associationsLoadError = 'Failed to load associations: ';
      // Optionally keep previous association options if available
      if (associationOptions.isEmpty) {
        associationOptions = ['None']; // fallback option
      }
    } finally {
      isLoadingAssociations = false;
      notifyListeners();
    }
  }

  void nextStep() {
    if (currentStep < 3) {
      currentStep++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      currentStep--;
      notifyListeners();
    }
  }

  void goToStep(int step) {
    currentStep = step;
    notifyListeners();
  }

  Future<void> signUp(BuildContext context) async {
    setLoading(true);
    notifyListeners();

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);

      final farmer = FarmerData(
        name: '${firstNameController.text} ${lastNameController.text}',
        password: passwordController.text,
        email: emailController.text,
        phone: phoneController.text,
        barangay: barangayController.text,
        association: associationController.text,
        sector: sectorController.text,
        imageUrl:
            'https://res.cloudinary.com/dk41ykxsq/image/upload/v1745590990/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDIzLTAxL3JtNjA5LXNvbGlkaWNvbi13LTAwMi1wLnBuZw-removebg-preview_myrmrf.png',
        fname: firstNameController.text,
        lname: lastNameController.text,
        mname: middleNameController.text,
        extension: extensionController.text,
        birthDate: birthDateController.text,
        sex: sex,
        civilStatus: civilStatus,
        spouseName: spouseNameController.text,
        householdHead: householdHeadController.text,
        householdNum: int.tryParse(householdNumController.text) ?? 0,
        maleMembers: int.tryParse(maleMembersController.text) ?? 0,
        femaleMembers: int.tryParse(femaleMembersController.text) ?? 0,
        motherMaidenName: motherMaidenNameController.text,
        religion: religionController.text,
        address: addressController.text,
        personToNotify: personToNotifyController.text,
        ptnContact: ptnContactController.text,
        ptnRelationship: ptnRelationshipController.text,
      );

      // Use ApiService instead of BLoC
      await apiService.post('/auth/register-farmer', data: {
        'email': farmer.email,
        'password': farmer.password,
        'name': farmer.name,
        'sector': farmer.sector,
        'firstname': farmer.fname,
        'lname': farmer.lname,
        'barangay': farmer.barangay,
        'association': farmer.association,
        'phone': farmer.phone,
        'mname': farmer.mname,
        'extension': farmer.extension,
        'birthDate': farmer.birthDate,
        'sex': farmer.sex,
        'civilStatus': farmer.civilStatus,
        'spouseName': farmer.spouseName,
        'householdHead': farmer.householdHead,
        'householdNum': farmer.householdNum,
        'maleMembers': farmer.maleMembers,
        'femaleMembers': farmer.femaleMembers,
        'motherMaidenName': farmer.motherMaidenName,
        'religion': farmer.religion,
        'address': farmer.address,
        'personToNotify': farmer.personToNotify,
        'ptnContact': farmer.ptnContact,
        'ptnRelationship': farmer.ptnRelationship,
      });

      _isPendingVerification = true;
      notifyListeners();

      // Show success toast
      ToastHelper.showSuccessToast(
          'Registration successful! Please check your email for verification.',
          context);
    } on DioException catch (e) {
      // Show error toast with server error message
      ToastHelper.showErrorToast(
        'Registration failed: ${e.response?.data['message'] ?? e.message}',
        context,
      );
    } catch (e) {
      ToastHelper.showErrorToast(
        'Registration failed: ${e.toString()}',
        context,
      );
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    rePasswordController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    extensionController.dispose();
    spouseNameController.dispose();
    birthDateController.dispose();
    householdHeadController.dispose();
    householdNumController.dispose();
    maleMembersController.dispose();
    femaleMembersController.dispose();
    motherMaidenNameController.dispose();
    religionController.dispose();
    associationController.dispose();
    sectorController.dispose();
    addressController.dispose();
    phoneController.dispose();
    personToNotifyController.dispose();
    ptnContactController.dispose();
    ptnRelationshipController.dispose();
    super.dispose();
  }
}

class FarmerData {
  final String name;
  final String email;
  final String password;
  final String association;
  final String phone;
  final String barangay;
  final String sector;
  final String? imageUrl;

  // Personal Info
  final String fname;
  final String lname;
  final String? mname;
  final String? extension;
  final String? birthDate;
  final String? sex;
  final String? civilStatus;
  final String? spouseName;

  // Household Info
  final String householdHead;
  final int householdNum;
  final int maleMembers;
  final int femaleMembers;
  final String motherMaidenName;
  final String religion;

  // Contact Info
  final String address;
  final String personToNotify;
  final String ptnContact;
  final String ptnRelationship;

  FarmerData({
    required this.name,
    required this.password,
    required this.association,
    required this.email,
    required this.phone,
    required this.barangay,
    required this.sector,
    this.imageUrl,
    required this.fname,
    required this.lname,
    this.mname,
    this.extension,
    this.birthDate,
    this.sex,
    this.civilStatus,
    this.spouseName,
    required this.householdHead,
    required this.householdNum,
    required this.maleMembers,
    required this.femaleMembers,
    required this.motherMaidenName,
    required this.religion,
    required this.address,
    required this.personToNotify,
    required this.ptnContact,
    required this.ptnRelationship,
  });
}
