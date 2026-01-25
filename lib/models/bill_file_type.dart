enum BillFileType {
  alipayCSV,
  wechatXLSX,
  unknown;

  @override
  String toString() {
    switch (this) {
      case BillFileType.alipayCSV:
        return 'alipayCSV';
      case BillFileType.wechatXLSX:
        return 'wechatXLSX';
      case BillFileType.unknown:
        return 'unknown';
    }
  }

  static BillFileType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'alipaycsv':
        return BillFileType.alipayCSV;
      case 'wechatxlsx':
        return BillFileType.wechatXLSX;
      default:
        return BillFileType.unknown;
    }
  }
}

extension BillFileTypeExtension on BillFileType {
  /// Detect file type from file name
  static BillFileType fromFileName(String fileName) {
    final lowerName = fileName.toLowerCase();

    // Check for Alipay CSV
    if (lowerName.contains('alipay') && lowerName.endsWith('.csv')) {
      return BillFileType.alipayCSV;
    }

    // Check for WeChat XLSX
    if (lowerName.contains('wechat') && lowerName.endsWith('.xlsx')) {
      return BillFileType.wechatXLSX;
    }

    // Check for common Chinese names
    if (lowerName.contains('支付宝') && lowerName.endsWith('.csv')) {
      return BillFileType.alipayCSV;
    }

    if (lowerName.contains('微信') && lowerName.endsWith('.xlsx')) {
      return BillFileType.wechatXLSX;
    }

    // Default to unknown
    return BillFileType.unknown;
  }
}
