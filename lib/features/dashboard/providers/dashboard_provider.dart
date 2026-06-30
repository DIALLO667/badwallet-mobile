import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/http_client.dart';
import '../../../models/transaction.dart';
import '../../../models/wallet.dart';

enum DashboardState { initial, loading, loaded, error }

class DashboardProvider extends ChangeNotifier {
  DashboardState _state = DashboardState.initial;
  Wallet? _wallet;
  List<Transaction> _recentTransactions = [];
  String _errorMessage = '';
  bool _balanceVisible = true;

  DashboardState get state => _state;
  Wallet? get wallet => _wallet;
  List<Transaction> get recentTransactions => _recentTransactions;
  String get errorMessage => _errorMessage;
  bool get balanceVisible => _balanceVisible;

  void toggleBalanceVisibility() {
    _balanceVisible = !_balanceVisible;
    notifyListeners();
  }

  Future<void> loadDashboard(String phone) async {
    _state = DashboardState.loading;
    notifyListeners();

    try {
      final walletData =
          await HttpClient.get(ApiConstants.wallet(phone)) as Map<String, dynamic>;
      _wallet = Wallet.fromJson(walletData);

      final txData = await HttpClient.get(ApiConstants.transactions(phone));
      final List<dynamic> txList =
          txData is List ? txData : (txData as Map<String, dynamic>)['transactions'] as List<dynamic>? ?? [];
      _recentTransactions =
          txList.map((t) => Transaction.fromJson(t as Map<String, dynamic>)).take(5).toList();

      _state = DashboardState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = DashboardState.error;
    }

    notifyListeners();
  }
}
