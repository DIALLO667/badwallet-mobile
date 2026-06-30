class Wallet {
  final String phone;
  final String name;
  final double balance;

  const Wallet({
    required this.phone,
    required this.name,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      phone: (json['phone'] ?? json['telephone'] ?? '').toString(),
      name: (json['name'] ?? json['nom'] ?? '').toString(),
      balance: (json['balance'] ?? json['solde'] ?? 0).toDouble(),
    );
  }
}
