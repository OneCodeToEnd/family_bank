import 'package:sqflite/sqflite.dart';
import '../../models/family_group.dart';
import '../../models/family_member.dart';
import '../../constants/db_constants.dart';
import 'database_service.dart';
import '../../utils/app_logger.dart';

/// 家庭组和成员数据库操作服务
class FamilyDbService {
  final DatabaseService _dbService = DatabaseService();

  // ==================== 家庭组操作 ====================

  /// 创建家庭组
  Future<int> createFamilyGroup(FamilyGroup group) async {
    AppLogger.i('[FamilyDbService] 创建家庭组: ${group.name}');
    final db = await _dbService.database;
    final id = await db.insert(
      DbConstants.tableFamilyGroups,
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.i('[FamilyDbService] ✅ 家庭组创建成功，ID: $id');
    return id;
  }

  /// 获取所有家庭组
  Future<List<FamilyGroup>> getAllFamilyGroups() async {
    AppLogger.d('[FamilyDbService] 查询所有家庭组');
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableFamilyGroups,
      orderBy: '${DbConstants.columnCreatedAt} DESC',
    );

    final groups = List.generate(maps.length, (i) {
      return FamilyGroup.fromMap(maps[i]);
    });

    AppLogger.d('[FamilyDbService] 查询到 ${groups.length} 个家庭组');
    if (groups.isNotEmpty) {
      for (var group in groups) {
        AppLogger.d('[FamilyDbService]   - ID: ${group.id}, 名称: ${group.name}, 创建时间: ${group.createdAt}');
      }
    }

    return groups;
  }

  /// 根据ID获取家庭组
  Future<FamilyGroup?> getFamilyGroupById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableFamilyGroups,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return FamilyGroup.fromMap(maps.first);
  }

  /// 更新家庭组
  Future<int> updateFamilyGroup(FamilyGroup group) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableFamilyGroups,
      group.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [group.id],
    );
  }

  /// 删除家庭组（级联删除所有成员和账户）
  Future<int> deleteFamilyGroup(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableFamilyGroups,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  // ==================== 家庭成员操作 ====================

  /// 创建家庭成员
  Future<int> createFamilyMember(FamilyMember member) async {
    AppLogger.i('[FamilyDbService] 创建家庭成员: ${member.name} (家庭组ID: ${member.familyGroupId})');
    final db = await _dbService.database;
    final id = await db.insert(
      DbConstants.tableFamilyMembers,
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    AppLogger.i('[FamilyDbService] ✅ 家庭成员创建成功，ID: $id');
    return id;
  }

  /// 获取指定家庭组的所有成员
  Future<List<FamilyMember>> getMembersByGroupId(int groupId) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableFamilyMembers,
      where: '${DbConstants.columnMemberFamilyGroupId} = ?',
      whereArgs: [groupId],
      orderBy: '${DbConstants.columnCreatedAt} ASC',
    );

    return List.generate(maps.length, (i) {
      return FamilyMember.fromMap(maps[i]);
    });
  }

  /// 获取所有家庭成员
  Future<List<FamilyMember>> getAllFamilyMembers() async {
    AppLogger.d('[FamilyDbService] 查询所有家庭成员');
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableFamilyMembers,
      orderBy: '${DbConstants.columnCreatedAt} ASC',
    );

    final members = List.generate(maps.length, (i) {
      return FamilyMember.fromMap(maps[i]);
    });

    AppLogger.d('[FamilyDbService] 查询到 ${members.length} 个家庭成员');
    if (members.isNotEmpty) {
      for (var member in members) {
        AppLogger.d('[FamilyDbService]   - ID: ${member.id}, 名称: ${member.name}, 家庭组ID: ${member.familyGroupId}, 创建时间: ${member.createdAt}');
      }
    }

    return members;
  }

  /// 根据ID获取家庭成员
  Future<FamilyMember?> getFamilyMemberById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbConstants.tableFamilyMembers,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return FamilyMember.fromMap(maps.first);
  }

  /// 更新家庭成员
  Future<int> updateFamilyMember(FamilyMember member) async {
    final db = await _dbService.database;
    return await db.update(
      DbConstants.tableFamilyMembers,
      member.copyWith(updatedAt: DateTime.now()).toMap(),
      where: '${DbConstants.columnId} = ?',
      whereArgs: [member.id],
    );
  }

  /// 删除家庭成员（级联删除所有账户）
  Future<int> deleteFamilyMember(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbConstants.tableFamilyMembers,
      where: '${DbConstants.columnId} = ?',
      whereArgs: [id],
    );
  }

  /// 获取家庭成员数量
  Future<int> getMemberCountByGroupId(int groupId) async {
    final db = await _dbService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DbConstants.tableFamilyMembers} WHERE ${DbConstants.columnMemberFamilyGroupId} = ?',
      [groupId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ==================== 联合查询 ====================

  /// 获取家庭组及其成员信息
  Future<Map<String, dynamic>> getFamilyGroupWithMembers(int groupId) async {
    final group = await getFamilyGroupById(groupId);
    if (group == null) {
      throw Exception('Family group not found');
    }

    final members = await getMembersByGroupId(groupId);

    return {
      'group': group,
      'members': members,
      'memberCount': members.length,
    };
  }

  /// 批量创建家庭成员
  Future<List<int>> createFamilyMembersBatch(List<FamilyMember> members) async {
    final db = await _dbService.database;
    final batch = db.batch();

    for (var member in members) {
      batch.insert(
        DbConstants.tableFamilyMembers,
        member.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    final results = await batch.commit();
    return results.cast<int>();
  }
}
