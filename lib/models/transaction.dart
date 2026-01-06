import 'package:crypto/crypto.dart';
import 'dart:convert';

/// 账单流水模型
class Transaction {
  final int? id;
  final int accountId;
  final int? categoryId;
  final String type; // income/expense
  final double amount;
  final String? description;
  final DateTime transactionTime;
  final String importSource; // manual/alipay/wechat/photo
  final bool isConfirmed;
  final String? notes;
  final String? counterparty; // 交易对方
  final String hash;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.accountId,
    this.categoryId,
    required this.type,
    required this.amount,
    this.description,
    required this.transactionTime,
    this.importSource = 'manual',
    this.isConfirmed = false,
    this.notes,
    this.counterparty,
    String? hash,
    required this.createdAt,
    required this.updatedAt,
  }) : hash = hash ?? _generateHash(transactionTime, amount, description ?? '');

  /// 生成去重哈希值
  static String _generateHash(DateTime time, double amount, String description) {
    final content = '${time.millisecondsSinceEpoch}_${amount}_$description';
    return md5.convert(utf8.encode(content)).toString();
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      accountId: map['account_id'] as int,
      categoryId: map['category_id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String?,
      transactionTime: DateTime.fromMillisecondsSinceEpoch(map['transaction_time'] as int),
      importSource: map['import_source'] as String? ?? 'manual',
      isConfirmed: (map['is_confirmed'] as int) == 1,
      notes: map['notes'] as String?,
      counterparty: map['counterparty'] as String?,
      hash: map['hash'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'transaction_time': transactionTime.millisecondsSinceEpoch,
      'import_source': importSource,
      'is_confirmed': isConfirmed ? 1 : 0,
      'notes': notes,
      'counterparty': counterparty,
      'hash': hash,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  Transaction copyWith({
    int? id,
    int? accountId,
    int? categoryId,
    String? type,
    double? amount,
    String? description,
    DateTime? transactionTime,
    String? importSource,
    bool? isConfirmed,
    String? notes,
    String? counterparty,
    String? hash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      transactionTime: transactionTime ?? this.transactionTime,
      importSource: importSource ?? this.importSource,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      notes: notes ?? this.notes,
      counterparty: counterparty ?? this.counterparty,
      hash: hash ?? this.hash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Transaction(id: $id, amount: $amount, type: $type, description: $description, time: $transactionTime)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Transaction && other.hash == hash;
  }

  @override
  int get hashCode {
    return hash.hashCode;
  }
}
