import 'package:uuid/uuid.dart';

class Account {
  final String id;
  String name;
  double balance;

  Account({
    String? id,
    required this.name,
    required this.balance,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String,
        balance: (json['balance'] as num).toDouble(),
      );
}
