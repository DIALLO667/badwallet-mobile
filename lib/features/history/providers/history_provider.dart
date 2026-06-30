import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/http_client.dart';
import '../../../models/transaction.dart';

enum HistoryState { initial, loading, loaded, error }

class HistoryProvider extends ChangeNotifier {
  HistoryState _state = HistoryState.initial;
  List<Transaction> _transactions = [];
  String _errorMessage = '';

  HistoryState get state => _state;
  List<Transaction> get transactions => _transactions;
  String get errorMessage => _errorMessage;

  Future<void> loadHistory(String phone) async {
    _state = HistoryState.loading;
    notifyListeners();

    try {
      final data = await HttpClient.get(ApiConstants.transactions(phone));
      final List<dynamic> list =
          data is List ? data : (data as Map<String, dynamic>)['transactions'] as List<dynamic>? ?? [];
      _transactions =
          list.map((t) => Transaction.fromJson(t as Map<String, dynamic>)).toList();
      _state = HistoryState.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _state = HistoryState.error;
    }

    notifyListeners();
  }
}
