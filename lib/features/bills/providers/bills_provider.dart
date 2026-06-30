import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/http_client.dart';
import '../../../models/bill.dart';

enum BillsState { initial, loading, loaded, error }

enum PaymentState { initial, loading, success, error }

class BillsProvider extends ChangeNotifier {
  BillsState _state = BillsState.initial;
  PaymentState _paymentState = PaymentState.initial;
  List<Bill> _bills = [];
  String _errorMessage = '';
  String _selectedProvider = '';

  static const List<Map<String, Object>> providers = [
    {'name': 'ISM', 'icon': Icons.school, 'code': 'ism'},
    {'name': 'WOYAFAL', 'icon': Icons.water_drop, 'code': 'woyafal'},
    {'name': 'RAPIDO', 'icon': Icons.directions_bus, 'code': 'rapido'},
    {'name': 'SENELEC', 'icon': Icons.bolt, 'code': 'senelec'},
  ];

  BillsState get state => _state;
  PaymentState get paymentState => _paymentState;
  List<Bill> get bills => _bills;
  String get errorMessage => _errorMessage;
  String get selectedProvider => _selectedProvider;
  List<Bill> get selectedBills => _bills.where((b) => b.isSelected).toList();
  double get totalSelected => selectedBills.fold(0, (sum, b) => sum + b.amount);

  Future<void> loadBills(String provider, String phone) async {
    _selectedProvider = provider;
    _state = BillsState.loading;
    _bills = [];
    notifyListeners();

    try {
      final data = await HttpClient.get(ApiConstants.factures(provider, phone));
      final List<dynamic> list =
          data is List ? data : (data as Map<String, dynamic>)['factures'] as List<dynamic>? ?? [];
      _bills = list.map((b) => Bill.fromJson(b as Map<String, dynamic>, provider)).toList();
      _state = BillsState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = BillsState.error;
    }

    notifyListeners();
  }

  void toggleBillSelection(String id) {
    final idx = _bills.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bills[idx].isSelected = !_bills[idx].isSelected;
      notifyListeners();
    }
  }

  Future<bool> paySelectedBills(String phone) async {
    if (selectedBills.isEmpty) return false;

    _paymentState = PaymentState.loading;
    notifyListeners();

    try {
      await HttpClient.post(ApiConstants.payBills, {
        'phone': phone,
        'factures': selectedBills.map((b) => b.id).toList(),
      });
      _paymentState = PaymentState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _paymentState = PaymentState.error;
      notifyListeners();
      return false;
    }
  }

  void goBackToProviders() {
    _state = BillsState.initial;
    _bills = [];
    _selectedProvider = '';
    _paymentState = PaymentState.initial;
    _errorMessage = '';
    notifyListeners();
  }

  void resetPaymentState() {
    _paymentState = PaymentState.initial;
    _errorMessage = '';
    notifyListeners();
  }
}
