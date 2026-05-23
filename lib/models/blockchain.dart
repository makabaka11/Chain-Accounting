import 'dart:convert';
import 'block.dart';

class Blockchain {
  final List<Block> chain;

  Blockchain._({required this.chain});

  factory Blockchain.genesis() {
    final genesisBlock = Block(
      index: 0,
      previousHash: '0' * 64,
      timestamp: DateTime.now().toIso8601String(),
      data: {'message': '创世区块 - Genesis Block'},
      nonce: 0,
    );
    return Blockchain._(chain: [genesisBlock]);
  }

  Block get latestBlock => chain.last;

  Block addBlock(Map<String, dynamic> data) {
    final block = Block(
      index: chain.length,
      previousHash: latestBlock.hash,
      timestamp: DateTime.now().toIso8601String(),
      data: data,
      nonce: _proofOfWork(data),
    );
    chain.add(block);
    return block;
  }

  int _proofOfWork(Map<String, dynamic> data) {
    int nonce = 0;
    while (true) {
      final input =
          '${chain.length}${latestBlock.hash}${DateTime.now().toIso8601String()}${jsonEncode(data)}$nonce';
      final hash = input.hashCode.toRadixString(16);
      if (hash.startsWith('0')) break;
      nonce++;
    }
    return nonce;
  }

  bool isChainValid() {
    for (int i = 1; i < chain.length; i++) {
      final current = chain[i];
      final previous = chain[i - 1];
      if (!current.isValid) return false;
      if (current.previousHash != previous.hash) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'chain': chain.map((b) => b.toJson()).toList(),
      };

  factory Blockchain.fromJson(Map<String, dynamic> json) {
    final blocks = (json['chain'] as List)
        .map((b) => Block.fromJson(b as Map<String, dynamic>))
        .toList();
    return Blockchain._(chain: blocks);
  }
}
