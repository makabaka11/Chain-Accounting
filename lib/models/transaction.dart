import 'package:uuid/uuid.dart';

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String accountId;
  final String accountName;
  final String note;
  final DateTime timestamp;
  final String blockHash;
  final int blockIndex;

  Transaction({
    String? id,
    required this.amount,
    required this.type,
    required this.accountId,
    required this.accountName,
    this.note = '',
    DateTime? timestamp,
    required this.blockHash,
    required this.blockIndex,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'type': type.name,
        'accountId': accountId,
        'accountName': accountName,
        'note': note,
        'timestamp': timestamp.toIso8601String(),
        'blockHash': blockHash,
        'blockIndex': blockIndex,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.values.byName(json['type'] as String),
        accountId: json['accountId'] as String,
        accountName: json['accountName'] as String,
        note: json['note'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        blockHash: json['blockHash'] as String,
        blockIndex: json['blockIndex'] as int,
      );
}
