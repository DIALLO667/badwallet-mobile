import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/http_client.dart';

enum TransferState { initial, loading, success, error }

class TransferProvider extends ChangeNotifier {
  TransferState _state = TransferState.initial;
  String _errorMessage = '';
  String _amount = '';
  String _recipient = '';

  TransferState get state => _state;
  String get errorMessage => _errorMessage;
  String get amount => _amount;
  String get recipient => _recipient;

  void setRecipient(String value) {
    _recipient = value;
    notifyListeners();
  }

  void addDigit(String digit) {
    if (_amount.length < 10) {
      _amount += digit;
      notifyListeners();
    }
  }

  void removeDigit() {
    if (_amount.isNotEmpty) {
      _amount = _amount.substring(0, _amount.length - 1);
      notifyListeners();
    }
  }

  void reset() {
    _state = TransferState.initial;
    _amount = '';
    _recipient = '';
    _errorMessage = '';
    notifyListeners();
  }

  Future<bool> sendTransfer(String senderPhone) async {
    if (_amount.isEmpty || _recipient.isEmpty) {
      _errorMessage = 'Veuillez remplir tous les champs';
      _state = TransferState.error;
      notifyListeners();
      return false;
    }

    _state = TransferState.loading;
    notifyListeners();

    try {
      await HttpClient.post(ApiConstants.transfer, {
        'sender': senderPhone,
        'recipient': _recipient,
        'amount': double.parse(_amount),
      });
      _state = TransferState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _state = TransferState.error;
      notifyListeners();
      return false;
    }
  }
}
