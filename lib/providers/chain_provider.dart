import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/blockchain.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../models/block.dart';

/// Offload block creation to a background isolate to avoid UI freeze
Block _createBlockSync(Map<String, dynamic> params) {
  final index = params['index'] as int;
  final previousHash = params['previousHash'] as String;
  final data = params['data'] as Map<String, dynamic>;

  final timestamp = DateTime.now().toIso8601String();
  // Simple proof of work: find nonce where hash starts with '0'
  int nonce = 0;
  while (true) {
    final block = Block(
      index: index,
      previousHash: previousHash,
      timestamp: timestamp,
      data: data,
      nonce: nonce,
    );
    if (block.hash.startsWith('0')) return block;
    nonce++;
    if (nonce > 100000) return block; // safety cap
  }
}

class ChainProvider extends ChangeNotifier {
  Blockchain _blockchain = Blockchain.genesis();
  List<Account> _accounts = [];
  List<Transaction> _transactions = [];
  bool _isDarkMode = false;
  bool _isProcessing = false;

  bool get isDarkMode => _isDarkMode;
  bool get isProcessing => _isProcessing;

  Blockchain get blockchain => _blockchain;
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Transaction> get transactions => List.unmodifiable(_transactions.reversed);

  double get totalBalance =>
      _accounts.fold(0.0, (sum, acc) => sum + acc.balance);

  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final chainJson = prefs.getString('blockchain');
    final accountsJson = prefs.getString('accounts');
    final transactionsJson = prefs.getString('transactions');
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;

    if (chainJson != null) {
      _blockchain = Blockchain.fromJson(jsonDecode(chainJson));
    }
    if (accountsJson != null) {
      _accounts = (jsonDecode(accountsJson) as List)
          .map((a) => Account.fromJson(a as Map<String, dynamic>))
          .toList();
    }
    if (transactionsJson != null) {
      _transactions = (jsonDecode(transactionsJson) as List)
          .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
          .toList();
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('blockchain', jsonEncode(_blockchain.toJson())),
      prefs.setString(
          'accounts', jsonEncode(_accounts.map((a) => a.toJson()).toList())),
      prefs.setString(
          'transactions',
          jsonEncode(_transactions.map((t) => t.toJson()).toList())),
    ]);
  }

  void addAccount(String name, double initialBalance) {
    final account = Account(name: name, balance: initialBalance);
    _accounts.add(account);
    _saveData();
    notifyListeners();
  }

  void deleteAccount(String accountId) {
    _accounts.removeWhere((a) => a.id == accountId);
    _saveData();
    notifyListeners();
  }

  Future<Transaction?> addTransaction({
    required double amount,
    required TransactionType type,
    required Account account,
    String note = '',
  }) async {
    if (_isProcessing) return null;
    _isProcessing = true;

    // Update account balance immediately (fast, in-memory)
    final accountIdx = _accounts.indexWhere((a) => a.id == account.id);
    if (accountIdx != -1) {
      if (type == TransactionType.income) {
        _accounts[accountIdx].balance += amount;
      } else {
        _accounts[accountIdx].balance -= amount;
      }
    }

    // Create block in background isolate
    final blockData = {
      'transaction': {
        'amount': amount,
        'type': type.name,
        'accountId': account.id,
        'accountName': account.name,
        'note': note,
        'timestamp': DateTime.now().toIso8601String(),
      }
    };

    final block = await compute(_createBlockSync, {
      'index': _blockchain.chain.length,
      'previousHash': _blockchain.latestBlock.hash,
      'data': blockData,
    });

    // Add block to chain (fast, in-memory)
    _blockchain.chain.add(block);

    // Create transaction record
    final transaction = Transaction(
      amount: amount,
      type: type,
      accountId: account.id,
      accountName: account.name,
      note: note,
      blockHash: block.hash,
      blockIndex: block.index,
    );
    _transactions.add(transaction);

    // Save in background
    await _saveData();

    _isProcessing = false;
    notifyListeners();
    return transaction;
  }

  bool verifyChain() => _blockchain.isChainValid();

  List<Transaction> getTransactionsForAccount(String accountId) {
    return _transactions.where((t) => t.accountId == accountId).toList();
  }

  double getAccountIncome(String accountId) {
    return _transactions
        .where(
            (t) => t.accountId == accountId && t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getAccountExpense(String accountId) {
    return _transactions
        .where((t) =>
            t.accountId == accountId && t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Map<String, Map<String, double>> getMonthlyData() {
    final now = DateTime.now();
    final monthlyData = <String, Map<String, double>>{};

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.month}月';
      monthlyData[key] = {'income': 0, 'expense': 0};
    }

    for (final t in _transactions) {
      final key = '${t.timestamp.month}月';
      if (monthlyData.containsKey(key)) {
        if (t.type == TransactionType.income) {
          monthlyData[key]!['income'] =
              monthlyData[key]!['income']! + t.amount;
        } else {
          monthlyData[key]!['expense'] =
              monthlyData[key]!['expense']! + t.amount;
        }
      }
    }

    return monthlyData;
  }

  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  String exportData() {
    final data = {
      'version': '1.0.0',
      'exportTime': DateTime.now().toIso8601String(),
      'blockchain': _blockchain.toJson(),
      'accounts': _accounts.map((a) => a.toJson()).toList(),
      'transactions': _transactions.map((t) => t.toJson()).toList(),
      'chainValid': verifyChain(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> clearAll() async {
    _blockchain = Blockchain.genesis();
    _accounts.clear();
    _transactions.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('blockchain');
    await prefs.remove('accounts');
    await prefs.remove('transactions');
    notifyListeners();
  }
}
