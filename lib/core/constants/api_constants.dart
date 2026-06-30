class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8080';

  static String wallet(String phone) => '$baseUrl/api/wallets/$phone';
  static String transactions(String phone) =>
      '$baseUrl/api/wallets/$phone/transactions';
  static const String transfer = '$baseUrl/api/wallets/transfer';
  static const String payBills = '$baseUrl/api/wallets/pay-factures';
  static String factures(String provider, String phone) =>
      '$baseUrl/api/external/factures/$provider/$phone';
}
