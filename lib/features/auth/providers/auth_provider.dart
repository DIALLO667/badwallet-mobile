import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthProvider extends ChangeNotifier {
  static const _phoneKey = 'saved_phone';
  final _storage = const FlutterSecureStorage();

  String? _phone;
  bool _isLoading = false;

  String? get phone => _phone;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _phone != null && _phone!.isNotEmpty;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _phone = await _storage.read(key: _phoneKey);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> savePhone(String phone) async {
    await _storage.write(key: _phoneKey, value: phone);
    _phone = phone;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: _phoneKey);
    _phone = null;
    notifyListeners();
  }
}
