/// 账单邮件项
class BillEmailItem {
  final String messageId;      // 邮件唯一ID
  final String subject;        // 邮件主题
  final String sender;         // 发件人
  final DateTime date;         // 邮件日期
  final String attachmentName; // 附件名称
  final int attachmentSize;    // 附件大小（字节）
  final String platform;       // 平台：alipay 或 wechat
  final String? downloadUrl;   // 下载链接（用于微信富文本邮件）
  bool isSelected;             // 是否被选中
  String? password;            // 用户输入的解压密码

  BillEmailItem({
    required this.messageId,
    required this.subject,
    required this.sender,
    required this.date,
    required this.attachmentName,
    required this.attachmentSize,
    required this.platform,
    this.downloadUrl,
    this.isSelected = false,
    this.password,
  });

  /// 是否有下载链接（微信富文本邮件）
  bool get hasDownloadUrl => downloadUrl != null && downloadUrl!.isNotEmpty;

  /// 格式化文件大小
  String get formattedSize {
    if (attachmentSize < 1024) {
      return '$attachmentSize B';
    } else if (attachmentSize < 1024 * 1024) {
      return '${(attachmentSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(attachmentSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 获取平台显示名称
  String get platformName {
    switch (platform) {
      case 'alipay':
        return '支付宝';
      case 'wechat':
        return '微信';
      default:
        return '未知';
    }
  }

  /// 复制并更新部分字段
  BillEmailItem copyWith({
    String? messageId,
    String? subject,
    String? sender,
    DateTime? date,
    String? attachmentName,
    int? attachmentSize,
    String? platform,
    String? downloadUrl,
    bool? isSelected,
    String? password,
  }) {
    return BillEmailItem(
      messageId: messageId ?? this.messageId,
      subject: subject ?? this.subject,
      sender: sender ?? this.sender,
      date: date ?? this.date,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
      platform: platform ?? this.platform,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      isSelected: isSelected ?? this.isSelected,
      password: password ?? this.password,
    );
  }
}
