import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String get userId => _user?.uid ?? '';
  String get displayName => _user?.displayName ?? _user?.email?.split('@')[0] ?? 'Usuario';
  String get email => _user?.email ?? '';
  String get imageUrl => _user?.photoURL ?? '';

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _mapFirebaseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String name) async {
    _setLoading(true);
    try {
      await _authService.signUp(email, password, name);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _mapFirebaseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = _mapFirebaseError(e);
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateProfile({String? name, File? imageFile}) async {
    _setLoading(true);
    try {
      if (name != null && name.isNotEmpty) {
        await _authService.updateDisplayName(name);
      }
      if (imageFile != null) {
        await _authService.updateProfilePicture(imageFile);
      }
      
      // Forzar actualización local del usuario
      _user = FirebaseAuth.instance.currentUser;
      notifyListeners();
      
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapFirebaseError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found': return 'Usuario no encontrado';
        case 'wrong-password': return 'Contraseña incorrecta';
        case 'email-already-in-use': return 'El email ya está registrado';
        case 'invalid-email': return 'Email inválido';
        case 'weak-password': return 'Contraseña muy debil';
        default: return 'Error de autenticación: ${e.message}';
      }
    }
    return e.toString();
  }
}
