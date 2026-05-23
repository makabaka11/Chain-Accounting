import 'dart:convert';
import 'package:crypto/crypto.dart';

class Block {
  final int index;
  final String previousHash;
  final String timestamp;
  final Map<String, dynamic> data;
  final int nonce;
  late final String hash;

  Block({
    required this.index,
    required this.previousHash,
    required this.timestamp,
    required this.data,
    required this.nonce,
  }) {
    hash = _calculateHash();
  }

  String _calculateHash() {
    final input = '$index$previousHash$timestamp${jsonEncode(data)}$nonce';
    return sha256.convert(utf8.encode(input)).toString();
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'previousHash': previousHash,
        'timestamp': timestamp,
        'data': data,
        'nonce': nonce,
        'hash': hash,
      };

  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      index: json['index'] as int,
      previousHash: json['previousHash'] as String,
      timestamp: json['timestamp'] as String,
      data: json['data'] as Map<String, dynamic>,
      nonce: json['nonce'] as int,
    );
  }

  bool get isValid => hash == _calculateHash();
}
