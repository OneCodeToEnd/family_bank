import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../utils/app_logger.dart';

/// SQL 日志标签
const _tag = '[SQL]';

/// 格式化参数用于日志输出
String _formatArgs(List<Object?>? args) {
  if (args == null || args.isEmpty) return '';
  return ' args=$args';
}

/// Database 包装器，拦截所有 SQL 操作并打印日志
class LoggingDatabase implements Database {
  final Database _delegate;

  LoggingDatabase(this._delegate);

  @override
  String get path => _delegate.path;

  @override
  bool get isOpen => _delegate.isOpen;

  @override
  Database get database => this;

  @override
  Future<void> close() => _delegate.close();

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    final sw = Stopwatch()..start();
    await _delegate.execute(sql, arguments);
    sw.stop();
    AppLogger.d('$_tag EXECUTE $sql${_formatArgs(arguments)} [${sw.elapsedMilliseconds}ms]');
  }

  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async {
    final sw = Stopwatch()..start();
    final id = await _delegate.rawInsert(sql, arguments);
    sw.stop();
    AppLogger.d('$_tag RAW_INSERT $sql${_formatArgs(arguments)} -> id=$id [${sw.elapsedMilliseconds}ms]');
    return id;
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    final sw = Stopwatch()..start();
    final id = await _delegate.insert(table, values,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: conflictAlgorithm);
    sw.stop();
    AppLogger.d('$_tag INSERT $table -> id=$id [${sw.elapsedMilliseconds}ms]');
    return id;
  }

  @override
  Future<List<Map<String, Object?>>> query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) async {
    final sw = Stopwatch()..start();
    final result = await _delegate.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
    sw.stop();
    final whereInfo = where != null ? ' WHERE $where${_formatArgs(whereArgs)}' : '';
    AppLogger.d('$_tag QUERY $table$whereInfo -> ${result.length} rows [${sw.elapsedMilliseconds}ms]');
    return result;
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql,
      [List<Object?>? arguments]) async {
    final sw = Stopwatch()..start();
    final result = await _delegate.rawQuery(sql, arguments);
    sw.stop();
    AppLogger.d('$_tag RAW_QUERY $sql${_formatArgs(arguments)} -> ${result.length} rows [${sw.elapsedMilliseconds}ms]');
    return result;
  }

  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async {
    final sw = Stopwatch()..start();
    final count = await _delegate.rawUpdate(sql, arguments);
    sw.stop();
    AppLogger.d('$_tag RAW_UPDATE $sql${_formatArgs(arguments)} -> $count changed [${sw.elapsedMilliseconds}ms]');
    return count;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) async {
    final sw = Stopwatch()..start();
    final count = await _delegate.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
    sw.stop();
    final whereInfo = where != null ? ' WHERE $where${_formatArgs(whereArgs)}' : '';
    AppLogger.d('$_tag UPDATE $table$whereInfo -> $count changed [${sw.elapsedMilliseconds}ms]');
    return count;
  }

  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async {
    final sw = Stopwatch()..start();
    final count = await _delegate.rawDelete(sql, arguments);
    sw.stop();
    AppLogger.d('$_tag RAW_DELETE $sql${_formatArgs(arguments)} -> $count deleted [${sw.elapsedMilliseconds}ms]');
    return count;
  }

  @override
  Future<int> delete(String table,
      {String? where, List<Object?>? whereArgs}) async {
    final sw = Stopwatch()..start();
    final count =
        await _delegate.delete(table, where: where, whereArgs: whereArgs);
    sw.stop();
    final whereInfo = where != null ? ' WHERE $where${_formatArgs(whereArgs)}' : '';
    AppLogger.d('$_tag DELETE $table$whereInfo -> $count deleted [${sw.elapsedMilliseconds}ms]');
    return count;
  }

  @override
  Batch batch() {
    return LoggingBatch(_delegate.batch());
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
      {bool? exclusive}) async {
    AppLogger.d('$_tag TXN BEGIN');
    final sw = Stopwatch()..start();
    try {
      final result = await _delegate.transaction(action, exclusive: exclusive);
      sw.stop();
      AppLogger.d('$_tag TXN COMMIT [${sw.elapsedMilliseconds}ms]');
      return result;
    } catch (e) {
      sw.stop();
      AppLogger.e('$_tag TXN ROLLBACK [${sw.elapsedMilliseconds}ms]', error: e);
      rethrow;
    }
  }

  @override
  Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action) {
    return _delegate.readTransaction(action);
  }

  @override
  Future<QueryCursor> rawQueryCursor(String sql, List<Object?>? arguments,
      {int? bufferSize}) {
    return _delegate.rawQueryCursor(sql, arguments, bufferSize: bufferSize);
  }

  @override
  Future<QueryCursor> queryCursor(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset,
      int? bufferSize}) {
    return _delegate.queryCursor(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
        bufferSize: bufferSize);
  }

  @override
  @Deprecated('Dev only')
  Future<T> devInvokeMethod<T>(String method, [Object? arguments]) {
    // ignore: deprecated_member_use
    return _delegate.devInvokeMethod(method, arguments);
  }

  @override
  @Deprecated('Dev only')
  Future<T> devInvokeSqlMethod<T>(String method, String sql,
      [List<Object?>? arguments]) {
    // ignore: deprecated_member_use
    return _delegate.devInvokeSqlMethod(method, sql, arguments);
  }
}

/// Batch 包装器，在 commit 时打印汇总日志
class LoggingBatch implements Batch {
  final Batch _delegate;
  int _opCount = 0;

  LoggingBatch(this._delegate);

  @override
  Future<List<Object?>> commit(
      {bool? exclusive, bool? noResult, bool? continueOnError}) async {
    final sw = Stopwatch()..start();
    final result = await _delegate.commit(
        exclusive: exclusive,
        noResult: noResult,
        continueOnError: continueOnError);
    sw.stop();
    AppLogger.d('$_tag BATCH COMMIT ($_opCount ops) [${sw.elapsedMilliseconds}ms]');
    return result;
  }

  @override
  Future<List<Object?>> apply({bool? noResult, bool? continueOnError}) async {
    final sw = Stopwatch()..start();
    final result = await _delegate.apply(
        noResult: noResult, continueOnError: continueOnError);
    sw.stop();
    AppLogger.d('$_tag BATCH APPLY ($_opCount ops) [${sw.elapsedMilliseconds}ms]');
    return result;
  }

  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {
    _opCount++;
    _delegate.rawInsert(sql, arguments);
  }

  @override
  void insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {
    _opCount++;
    _delegate.insert(table, values,
        nullColumnHack: nullColumnHack,
        conflictAlgorithm: conflictAlgorithm);
  }

  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) {
    _opCount++;
    _delegate.rawUpdate(sql, arguments);
  }

  @override
  void update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) {
    _opCount++;
    _delegate.update(table, values,
        where: where,
        whereArgs: whereArgs,
        conflictAlgorithm: conflictAlgorithm);
  }

  @override
  void rawDelete(String sql, [List<Object?>? arguments]) {
    _opCount++;
    _delegate.rawDelete(sql, arguments);
  }

  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {
    _opCount++;
    _delegate.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  void execute(String sql, [List<Object?>? arguments]) {
    _opCount++;
    _delegate.execute(sql, arguments);
  }

  @override
  void query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {
    _opCount++;
    _delegate.query(table,
        distinct: distinct,
        columns: columns,
        where: where,
        whereArgs: whereArgs,
        groupBy: groupBy,
        having: having,
        orderBy: orderBy,
        limit: limit,
        offset: offset);
  }

  @override
  void rawQuery(String sql, [List<Object?>? arguments]) {
    _opCount++;
    _delegate.rawQuery(sql, arguments);
  }

  @override
  int get length => _delegate.length;
}
