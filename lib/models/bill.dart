class Bill {
  final String id;
  final String provider;
  final String reference;
  final double amount;
  final String description;
  bool isSelected;

  Bill({
    required this.id,
    required this.provider,
    required this.reference,
    required this.amount,
    required this.description,
    this.isSelected = false,
  });

  factory Bill.fromJson(Map<String, dynamic> json, String provider) {
    return Bill(
      id: (json['id'] ?? '').toString(),
      provider: provider,
      reference: (json['reference'] ?? json['ref'] ?? '').toString(),
      amount: (json['amount'] ?? json['montant'] ?? 0).toDouble(),
      description:
          (json['description'] ?? json['libelle'] ?? 'Facture').toString(),
    );
  }
}
