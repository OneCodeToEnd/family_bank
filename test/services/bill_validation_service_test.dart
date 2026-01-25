import 'package:flutter_test/flutter_test.dart';
import 'package:family_bank/models/bill_summary.dart';
import 'package:family_bank/models/validation_result.dart';
import 'package:family_bank/models/bill_file_type.dart';
import 'package:family_bank/models/transaction.dart';
import 'package:family_bank/models/category.dart';
import 'package:family_bank/models/category_match_result.dart';
import 'package:family_bank/models/ai_model.dart';
import 'package:family_bank/models/ai_provider.dart';
import 'package:family_bank/services/bill_validation_service.dart';
import 'package:family_bank/services/ai/ai_classifier_service.dart';

void main() {
  group('BillSummary', () {
    test('toJson should use English keys', () {
      final summary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.50,
        totalExpense: 3000.25,
        netAmount: 2000.25,
      );

      final json = summary.toJson();

      expect(json['totalCount'], 100);
      expect(json['incomeCount'], 40);
      expect(json['expenseCount'], 60);
      expect(json['totalIncome'], 5000.50);
      expect(json['totalExpense'], 3000.25);
      expect(json['netAmount'], 2000.25);
    });

    test('fromJson should parse correctly', () {
      final json = {
        'totalCount': 100,
        'incomeCount': 40,
        'expenseCount': 60,
        'totalIncome': 5000.50,
        'totalExpense': 3000.25,
        'netAmount': 2000.25,
      };

      final summary = BillSummary.fromJson(json);

      expect(summary.totalCount, 100);
      expect(summary.incomeCount, 40);
      expect(summary.expenseCount, 60);
      expect(summary.totalIncome, 5000.50);
      expect(summary.totalExpense, 3000.25);
      expect(summary.netAmount, 2000.25);
    });

    test('equality should work correctly', () {
      final summary1 = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.50,
        totalExpense: 3000.25,
        netAmount: 2000.25,
      );

      final summary2 = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.50,
        totalExpense: 3000.25,
        netAmount: 2000.25,
      );

      expect(summary1, equals(summary2));
      expect(summary1.hashCode, equals(summary2.hashCode));
    });
  });

  group('ValidationStatus', () {
    test('toString should return correct string', () {
      expect(ValidationStatus.perfect.toString(), 'perfect');
      expect(ValidationStatus.warning.toString(), 'warning');
      expect(ValidationStatus.error.toString(), 'error');
    });

    test('fromString should parse correctly', () {
      expect(ValidationStatus.fromString('perfect'), ValidationStatus.perfect);
      expect(ValidationStatus.fromString('warning'), ValidationStatus.warning);
      expect(ValidationStatus.fromString('error'), ValidationStatus.error);
      expect(ValidationStatus.fromString('PERFECT'), ValidationStatus.perfect);
    });

    test('fromString should throw on invalid value', () {
      expect(() => ValidationStatus.fromString('invalid'), throwsArgumentError);
    });
  });

  group('ValidationResult', () {
    test('isValid should return true for perfect and warning', () {
      final fileSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
      );

      final perfectResult = ValidationResult(
        status: ValidationStatus.perfect,
        fileSummary: fileSummary,
        calculatedSummary: fileSummary,
        issues: [],
      );

      final warningResult = ValidationResult(
        status: ValidationStatus.warning,
        fileSummary: fileSummary,
        calculatedSummary: fileSummary,
        issues: [],
      );

      final errorResult = ValidationResult(
        status: ValidationStatus.error,
        fileSummary: fileSummary,
        calculatedSummary: fileSummary,
        issues: [],
      );

      expect(perfectResult.isValid, true);
      expect(warningResult.isValid, true);
      expect(errorResult.isValid, false);
    });

    test('hasWarnings should return true only for warning status', () {
      final fileSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
      );

      final perfectResult = ValidationResult(
        status: ValidationStatus.perfect,
        fileSummary: fileSummary,
        calculatedSummary: fileSummary,
        issues: [],
      );

      final warningResult = ValidationResult(
        status: ValidationStatus.warning,
        fileSummary: fileSummary,
        calculatedSummary: fileSummary,
        issues: [],
      );

      expect(perfectResult.hasWarnings, false);
      expect(warningResult.hasWarnings, true);
    });
  });

  group('BillFileType', () {
    test('fromFileName should detect Alipay CSV', () {
      expect(
        BillFileTypeExtension.fromFileName('alipay_bills_2024.csv'),
        BillFileType.alipayCSV,
      );
      expect(
        BillFileTypeExtension.fromFileName('支付宝账单.csv'),
        BillFileType.alipayCSV,
      );
      expect(
        BillFileTypeExtension.fromFileName('ALIPAY_EXPORT.CSV'),
        BillFileType.alipayCSV,
      );
    });

    test('fromFileName should detect WeChat XLSX', () {
      expect(
        BillFileTypeExtension.fromFileName('wechat_bills_2024.xlsx'),
        BillFileType.wechatXLSX,
      );
      expect(
        BillFileTypeExtension.fromFileName('微信账单.xlsx'),
        BillFileType.wechatXLSX,
      );
      expect(
        BillFileTypeExtension.fromFileName('WECHAT_EXPORT.XLSX'),
        BillFileType.wechatXLSX,
      );
    });

    test('fromFileName should return unknown for unrecognized files', () {
      expect(
        BillFileTypeExtension.fromFileName('random_file.txt'),
        BillFileType.unknown,
      );
      expect(
        BillFileTypeExtension.fromFileName('bills.pdf'),
        BillFileType.unknown,
      );
    });
  });

  group('BillValidationService', () {
    late BillValidationService service;

    setUp(() {
      // Create a mock AIClassifierService (we'll use a simple implementation for now)
      final mockAIService = MockAIClassifierService();
      service = BillValidationService(mockAIService);
    });

    test('calculateSummaryFromTransactions should handle empty list', () {
      final summary = service.calculateSummaryFromTransactions([]);

      expect(summary.totalCount, 0);
      expect(summary.incomeCount, 0);
      expect(summary.expenseCount, 0);
      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpense, 0.0);
      expect(summary.netAmount, 0.0);
    });

    test('calculateSummaryFromTransactions should calculate correctly for income only', () {
      final now = DateTime.now();
      final transactions = [
        Transaction(
          accountId: 1,
          type: 'income',
          amount: 1000.0,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          accountId: 1,
          type: 'income',
          amount: 2000.50,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = service.calculateSummaryFromTransactions(transactions);

      expect(summary.totalCount, 2);
      expect(summary.incomeCount, 2);
      expect(summary.expenseCount, 0);
      expect(summary.totalIncome, 3000.50);
      expect(summary.totalExpense, 0.0);
      expect(summary.netAmount, 3000.50);
    });

    test('calculateSummaryFromTransactions should calculate correctly for expense only', () {
      final now = DateTime.now();
      final transactions = [
        Transaction(
          accountId: 1,
          type: 'expense',
          amount: 500.25,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          accountId: 1,
          type: 'expense',
          amount: 300.75,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = service.calculateSummaryFromTransactions(transactions);

      expect(summary.totalCount, 2);
      expect(summary.incomeCount, 0);
      expect(summary.expenseCount, 2);
      expect(summary.totalIncome, 0.0);
      expect(summary.totalExpense, 801.0);
      expect(summary.netAmount, -801.0);
    });

    test('calculateSummaryFromTransactions should calculate correctly for mixed transactions', () {
      final now = DateTime.now();
      final transactions = [
        Transaction(
          accountId: 1,
          type: 'income',
          amount: 5000.0,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          accountId: 1,
          type: 'expense',
          amount: 1500.50,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          accountId: 1,
          type: 'income',
          amount: 2000.0,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          accountId: 1,
          type: 'expense',
          amount: 800.25,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = service.calculateSummaryFromTransactions(transactions);

      expect(summary.totalCount, 4);
      expect(summary.incomeCount, 2);
      expect(summary.expenseCount, 2);
      expect(summary.totalIncome, 7000.0);
      expect(summary.totalExpense, 2300.75);
      expect(summary.netAmount, 4699.25);
    });

    test('calculateSummaryFromTransactions should handle floating point precision', () {
      final now = DateTime.now();
      final transactions = [
        Transaction(
          accountId: 1,
          type: 'income',
          amount: 0.1,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
        Transaction(
          accountId: 1,
          type: 'income',
          amount: 0.2,
          transactionTime: now,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final summary = service.calculateSummaryFromTransactions(transactions);

      // Should be 0.3, not 0.30000000000000004
      expect(summary.totalIncome, 0.3);
      expect(summary.netAmount, 0.3);
    });
  });

  group('BillValidationService - validateImport', () {
    late BillValidationService service;

    setUp(() {
      final mockAIService = MockAIClassifierService();
      service = BillValidationService(mockAIService);
    });

    test('validateImport should return perfect status when all fields match', () {
      final fileSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
      );

      final calculatedSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
      );

      final result = service.validateImport(fileSummary, calculatedSummary);

      expect(result.status, ValidationStatus.perfect);
      expect(result.issues, isEmpty);
      expect(result.isValid, true);
      expect(result.hasWarnings, false);
      expect(result.suggestion, contains('验证通过'));
    });

    test('validateImport should return warning status for minor count discrepancy', () {
      final fileSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
      );

      final calculatedSummary = BillSummary(
        totalCount: 98, // 2 transactions missing
        incomeCount: 40,
        expenseCount: 58,
        totalIncome: 5000.0,
        totalExpense: 2950.0,
        netAmount: 2050.0,
      );

      final result = service.validateImport(fileSummary, calculatedSummary);

      expect(result.status, ValidationStatus.warning);
      expect(result.issues.length, greaterThan(0));
      expect(result.isValid, true);
      expect(result.hasWarnings, true);
      expect(result.suggestion, contains('轻微差异'));
    });

    test('validateImport should return error status for major count discrepancy', () {
      final fileSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
      );

      final calculatedSummary = BillSummary(
        totalCount: 90, // 10 transactions missing
        incomeCount: 35,
        expenseCount: 55,
        totalIncome: 4500.0,
        totalExpense: 2700.0,
        netAmount: 1800.0,
      );

      final result = service.validateImport(fileSummary, calculatedSummary);

      expect(result.status, ValidationStatus.error);
      expect(result.issues.length, greaterThan(0));
      expect(result.isValid, false);
      expect(result.hasWarnings, false);
      expect(result.suggestion, contains('重大差异'));
    });

    test('validateImport should return error status for major amount discrepancy', () {
      final fileSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
      );

      final calculatedSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 4500.0, // 10% difference
        totalExpense: 3000.0,
        netAmount: 1500.0,
      );

      final result = service.validateImport(fileSummary, calculatedSummary);

      expect(result.status, ValidationStatus.error);
      expect(result.issues.length, greaterThan(0));
      expect(result.isValid, false);
    });

    test('validateImport should tolerate floating point precision differences', () {
      final fileSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.00,
        totalExpense: 3000.00,
        netAmount: 2000.00,
      );

      final calculatedSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.005, // 0.005 difference (within tolerance)
        totalExpense: 3000.005,
        netAmount: 2000.00,
      );

      final result = service.validateImport(fileSummary, calculatedSummary);

      expect(result.status, ValidationStatus.perfect);
      expect(result.issues, isEmpty);
    });

    test('validateImport should generate appropriate issues for each discrepancy', () {
      final fileSummary = BillSummary(
        totalCount: 100,
        incomeCount: 40,
        expenseCount: 60,
        totalIncome: 5000.0,
        totalExpense: 3000.0,
        netAmount: 2000.0,
      );

      final calculatedSummary = BillSummary(
        totalCount: 98,
        incomeCount: 39,
        expenseCount: 59,
        totalIncome: 4950.0,
        totalExpense: 2950.0,
        netAmount: 2000.0,
      );

      final result = service.validateImport(fileSummary, calculatedSummary);

      // Should have issues for totalCount, incomeCount, expenseCount, totalIncome, totalExpense
      expect(result.issues.length, 5);

      // Check that each issue has proper fields
      for (final issue in result.issues) {
        expect(issue.field, isNotEmpty);
        expect(issue.message, isNotEmpty);
        expect(issue.discrepancy, isNotNull);
        expect(issue.discrepancy, greaterThan(0));
      }
    });
  });
}

/// Mock AIClassifierService for testing
class MockAIClassifierService implements AIClassifierService {
  @override
  Future<CategoryMatchResult?> classify(
    Transaction transaction,
    List<Category> availableCategories,
  ) async {
    return null;
  }

  @override
  Future<List<CategoryMatchResult?>> classifyBatch(
    List<Transaction> transactions,
    List<Category> availableCategories,
  ) async {
    return [];
  }

  @override
  Future<List<AIModel>> getAvailableModels() async {
    return [];
  }

  @override
  Future<bool> testConnection() async {
    return true;
  }

  @override
  Future<Map<String, dynamic>> extractBillSummary(
    String fileContent,
    String fileType,
  ) async {
    // Return mock summary data
    return {
      'totalCount': 100,
      'incomeCount': 40,
      'expenseCount': 60,
      'totalIncome': 5000.0,
      'totalExpense': 3000.0,
      'netAmount': 2000.0,
    };
  }

  @override
  AIProvider get provider => AIProvider.qwen;

  @override
  String get currentModel => 'test-model';
}
