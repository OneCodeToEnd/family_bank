import 'bill_summary.dart';

enum ValidationStatus {
  perfect,
  warning,
  error;

  @override
  String toString() {
    switch (this) {
      case ValidationStatus.perfect:
        return 'perfect';
      case ValidationStatus.warning:
        return 'warning';
      case ValidationStatus.error:
        return 'error';
    }
  }

  static ValidationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'perfect':
        return ValidationStatus.perfect;
      case 'warning':
        return ValidationStatus.warning;
      case 'error':
        return ValidationStatus.error;
      default:
        throw ArgumentError('Invalid ValidationStatus: $value');
    }
  }
}

class ValidationIssue {
  final String field;
  final dynamic expectedValue;
  final dynamic actualValue;
  final double? discrepancy;
  final String message;

  ValidationIssue({
    required this.field,
    required this.expectedValue,
    required this.actualValue,
    this.discrepancy,
    required this.message,
  });

  Map<String, dynamic> toJson() => {
        'field': field,
        'expectedValue': expectedValue,
        'actualValue': actualValue,
        'discrepancy': discrepancy,
        'message': message,
      };

  factory ValidationIssue.fromJson(Map<String, dynamic> json) =>
      ValidationIssue(
        field: json['field'] as String,
        expectedValue: json['expectedValue'],
        actualValue: json['actualValue'],
        discrepancy: json['discrepancy'] != null
            ? (json['discrepancy'] as num).toDouble()
            : null,
        message: json['message'] as String,
      );

  @override
  String toString() {
    return 'ValidationIssue(field: $field, expected: $expectedValue, '
        'actual: $actualValue, discrepancy: $discrepancy, message: $message)';
  }
}

class ValidationResult {
  final ValidationStatus status;
  final BillSummary fileSummary;
  final BillSummary calculatedSummary;
  final List<ValidationIssue> issues;
  final String? suggestion;

  ValidationResult({
    required this.status,
    required this.fileSummary,
    required this.calculatedSummary,
    required this.issues,
    this.suggestion,
  });

  /// Returns true if validation passed (status is not error)
  bool get isValid => status != ValidationStatus.error;

  /// Returns true if there are warnings
  bool get hasWarnings => status == ValidationStatus.warning;

  Map<String, dynamic> toJson() => {
        'status': status.toString(),
        'fileSummary': fileSummary.toJson(),
        'calculatedSummary': calculatedSummary.toJson(),
        'issues': issues.map((i) => i.toJson()).toList(),
        'suggestion': suggestion,
      };

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      ValidationResult(
        status: ValidationStatus.fromString(json['status'] as String),
        fileSummary: BillSummary.fromJson(json['fileSummary']),
        calculatedSummary: BillSummary.fromJson(json['calculatedSummary']),
        issues: (json['issues'] as List)
            .map((i) => ValidationIssue.fromJson(i))
            .toList(),
        suggestion: json['suggestion'] as String?,
      );

  @override
  String toString() {
    return 'ValidationResult(status: $status, issues: ${issues.length}, '
        'suggestion: $suggestion)';
  }
}
