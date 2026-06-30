class Transaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final DateTime date;
  final String? recipient;
  final String? sender;

  const Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.recipient,
    this.sender,
  });

  bool get isCredit {
    final t = type.toLowerCase();
    return t == 'credit' || t == 'reception' || t == 'depot' || t == 'receive';
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      amount: (json['amount'] ?? json['montant'] ?? 0).toDouble(),
      description:
          (json['description'] ?? json['libelle'] ?? 'Transaction').toString(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      recipient: json['recipient']?.toString() ?? json['destinataire']?.toString(),
      sender: json['sender']?.toString() ?? json['expediteur']?.toString(),
    );
  }
}
