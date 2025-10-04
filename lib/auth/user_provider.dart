import 'package:flutter/material.dart';
import 'package:flutter_application_1/auth/auth_service.dart';

class UserProvider with ChangeNotifier {
  String? _role;

  String? get role => _role;

  // Fetch the user's role from Firestore
  Future<void> fetchUserRole() async {
    final authService = AuthService();
    _role = await authService.getUserRole();
    notifyListeners(); // Notify listeners to rebuild the UI
  }
}
