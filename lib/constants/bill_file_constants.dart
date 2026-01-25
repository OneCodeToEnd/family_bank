/// 账单文件格式常量
///
/// 定义不同账单文件格式的解析参数
class BillFileConstants {
  BillFileConstants._();

  /// 支付宝 CSV 文件常量
  static const alipay = AlipayConstants();

  /// 微信 XLSX 文件常量
  static const wechat = WeChatConstants();
}

/// 支付宝账单文件常量
class AlipayConstants {
  const AlipayConstants();

  /// 表头行数（前24行是文件信息）
  int get headerRows => 24;

  /// 列名行索引（第25行，索引为24）
  int get columnHeaderRow => 24;

  /// 数据起始行索引（第26行，索引为25）
  int get dataStartRow => 25;

  /// 文件编码
  String get encoding => 'GBK';

  /// 用于 LLM 提取摘要的行数（包含表头信息，用于识别总计数据）
  int get summaryRows => 24;
}

/// 微信账单文件常量
class WeChatConstants {
  const WeChatConstants();

  /// 表头行数（前17行是文件信息）
  int get headerRows => 17;

  /// 列名行索引（第18行，索引为17）
  int get columnHeaderRow => 17;

  /// 数据起始行索引（第19行，索引为18）
  int get dataStartRow => 18;

  /// 文件编码
  String get encoding => 'UTF-8';

  /// 用于 LLM 提取摘要的行数（包含表头信息，用于识别总计数据）
  int get summaryRows => 17;
}
