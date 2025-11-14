import 'package:flareline/core/models/user_model.dart';
import 'package:flareline/core/models/farmer_model.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider extends ChangeNotifier {
  final GetStorage _storage = GetStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  UserModel? _user;
  Farmer? _farmer;

  UserModel? get user => _user;
  Farmer? get farmer => _farmer;

  bool get isFarmer => _user?.role == 'farmer';

  UserProvider() {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userData = _storage.read('userData');
    final farmerData = _storage.read('farmerData');

    if (userData != null) {
      // print(userData);
      _user = UserModel.fromMap(userData);
    }

    if (farmerData != null) {
      _farmer = Farmer.fromMap(farmerData);
      // print(farmerData);
    }

    notifyListeners();
  }

  Future<void> setUser(UserModel user) async {
    _user = user;
    await _storage.write('userData', user.toMap());
    notifyListeners();
  }

  Future<void> setFarmer(Farmer farmer) async {
    _farmer = farmer;
    await _storage.write('farmerData', farmer.toMap());
    notifyListeners();
  }

  Future<void> clearUser() async {
    _user = null;
    _farmer = null;
    await _storage.remove('userData');
    await _storage.remove('farmerData');
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await clearUser();
    } catch (e) {
      // print('Error signing out: $e');
      rethrow;
    }
  }
}
