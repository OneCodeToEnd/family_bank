import 'dart:io';
import 'package:enough_mail/enough_mail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../../models/email_config.dart';
import '../../models/bill_email_item.dart';
import '../../models/import_result.dart';
import '../../models/bill_file_type.dart';
import '../../utils/app_logger.dart';
import 'bill_import_service.dart';

/// 邮箱服务
///
/// 注意：此服务需要enough_mail包的正确API
/// 当前实现为简化版本，实际使用时需要根据enough_mail的文档调整
class EmailService {
  ImapClient? _imapClient;
  bool _isConnected = false;
  final BillImportService? _billImportService;

  EmailService({BillImportService? billImportService})
      : _billImportService = billImportService;

  /// 支付宝官方邮箱地址
  static const String alipayEmail = 'service@mail.alipay.com';

  /// 微信支付官方邮箱地址
  static const List<String> wechatEmails = [
    'wechatpay@tencent.com',
    'wxpay@tenpay.com',
  ];

  /// 连接邮箱
  Future<void> connect(EmailConfig config) async {
    if (_isConnected) {
      AppLogger.d('[EmailService] 已经连接，跳过重复连接');
      return;
    }

    AppLogger.i('[EmailService] 开始连接邮箱');
    AppLogger.d('[EmailService] 邮箱地址: ${config.email}');
    AppLogger.d('[EmailService] IMAP服务器: ${config.imapServer}');
    AppLogger.d('[EmailService] IMAP端口: ${config.imapPort}');
    AppLogger.d('[EmailService] 密码长度: ${config.password.length}');

    try {
      _imapClient = ImapClient(isLogEnabled: true);
      AppLogger.d('[EmailService] ImapClient 已创建，日志已启用');

      // 连接到IMAP服务器
      AppLogger.d('[EmailService] 正在连接到服务器...');
      await _imapClient!.connectToServer(
        config.imapServer,
        config.imapPort,
        isSecure: true,
      );
      AppLogger.i('[EmailService] 服务器连接成功');

      // 登录
      AppLogger.d('[EmailService] 正在登录...');
      await _imapClient!.login(config.email, config.password);
      AppLogger.i('[EmailService] 登录成功');

      _isConnected = true;
      AppLogger.i('[EmailService] 邮箱连接完成');
    } catch (e) {
      AppLogger.e('[EmailService] 连接失败', error: e);
      _imapClient = null;
      _isConnected = false;
      rethrow;
    }
  }

  /// 搜索账单邮件
  ///
  /// [senders] 发件人列表（支付宝/微信）
  /// [since] 起始时间
  /// [limit] 最多返回数量
  ///
  /// 返回账单邮件列表
  Future<List<BillEmailItem>> searchBillEmails({
    List<String>? senders,
    DateTime? since,
    int limit = 50,
  }) async {
    AppLogger.i('[EmailService] 开始搜索账单邮件');
    AppLogger.d('[EmailService] 连接状态: $_isConnected');
    AppLogger.d('[EmailService] 搜索限制: $limit');
    AppLogger.d('[EmailService] 起始时间: $since');

    if (!_isConnected || _imapClient == null) {
      AppLogger.w('[EmailService] 邮箱未连接');
      throw Exception('邮箱未连接');
    }

    try {
      // 确保收件箱已选择
      try {
        AppLogger.d('[EmailService] 正在选择收件箱 (SELECT)...');
        await _imapClient!.selectInbox();
        AppLogger.d('[EmailService] 收件箱选择成功');
      } catch (e) {
        AppLogger.w('[EmailService] SELECT 失败，尝试使用 EXAMINE (只读模式)', error: e);
        final errorMsg = e.toString();

        // 如果是 Unsafe Login 错误，尝试使用 EXAMINE 命令（只读模式）
        if (errorMsg.contains('Unsafe Login') || errorMsg.contains('unsafe')) {
          try {
            AppLogger.d('[EmailService] 尝试使用 EXAMINE 命令...');
            // 先列出邮箱以获取 INBOX 的 Mailbox 对象
            final mailboxes = await _imapClient!.listMailboxes();
            final inbox = mailboxes.firstWhere(
              (box) => box.name == 'INBOX',
              orElse: () => throw Exception('未找到 INBOX'),
            );
            await _imapClient!.examineMailbox(inbox);
            AppLogger.i('[EmailService] EXAMINE 成功，使用只读模式');
          } catch (examineError) {
            AppLogger.e('[EmailService] EXAMINE 也失败', error: examineError);
            throw Exception(
              '163邮箱访问失败。\n\n'
              '可能的原因：\n'
              '1. 授权码权限不足\n'
              '2. 需要在163邮箱网页版中进行额外的安全验证\n'
              '3. 需要在"设置-POP3/SMTP/IMAP"中开启"IMAP/SMTP服务"\n\n'
              '建议操作：\n'
              '1. 登录163邮箱网页版\n'
              '2. 进入"设置" → "POP3/SMTP/IMAP"\n'
              '3. 确认"IMAP/SMTP服务"已开启\n'
              '4. 重新生成授权码\n'
              '5. 查看是否有安全验证提示\n\n'
              '如果问题仍然存在，建议使用 QQ邮箱 或 Gmail。\n\n'
              'SELECT错误: $errorMsg\n'
              'EXAMINE错误: $examineError'
            );
          }
        } else {
          // 其他错误
          throw Exception('访问邮箱失败: $errorMsg');
        }
      }

      final billEmails = <BillEmailItem>[];

      // 默认搜索支付宝和微信的邮件
      final searchSenders = senders ?? [alipayEmail, ...wechatEmails];
      AppLogger.d('[EmailService] 搜索发件人: $searchSenders');

      // 为每个发件人搜索邮件
      for (final sender in searchSenders) {
        AppLogger.d('[EmailService] 正在搜索来自 $sender 的邮件...');

        // 构建搜索条件
        final searchQuery = SearchQueryBuilder.from(
          sender,
          SearchQueryType.from,
          since: since,
        );
        AppLogger.d('[EmailService] 搜索查询: $searchQuery');

        // 执行搜索
        final searchResult = await _imapClient!.searchMessagesWithQuery(searchQuery);
        AppLogger.d('[EmailService] 搜索结果: ${searchResult.matchingSequence?.length ?? 0} 封邮件');

        if (searchResult.matchingSequence == null ||
            searchResult.matchingSequence!.isEmpty) {
          AppLogger.d('[EmailService] 未找到来自 $sender 的邮件');
          continue;
        }

        // 获取邮件详情（包括完整的邮件体）
        AppLogger.d('[EmailService] 正在获取邮件详情...');
        final fetchResult = await _imapClient!.fetchMessages(
          searchResult.matchingSequence!,
          '(ENVELOPE BODYSTRUCTURE BODY[])',
        );
        AppLogger.d('[EmailService] 获取到 ${fetchResult.messages.length} 封邮件');

        // 解析邮件
        for (final message in fetchResult.messages) {
          try {
            AppLogger.d('[EmailService] 解析邮件: ${message.decodeSubject() ?? "(无主题)"}');
            AppLogger.d('[EmailService] 邮件 UID: ${message.uid}, 序列号: ${message.sequenceId}');
            AppLogger.d('[EmailService] Body parts: ${message.parts?.length ?? 0}');

            // 检查是否是微信邮件
            final isWeChatEmail = sender.contains('tenpay') || sender.contains('wechat') || sender.contains('tencent');
            String? wechatDownloadUrl;

            // 如果是微信邮件，尝试提取下载链接
            if (isWeChatEmail) {
              AppLogger.i('[EmailService] ========== 微信邮件内容开始 ==========');

              // 打印所有 parts
              if (message.parts != null && message.parts!.isNotEmpty) {
                AppLogger.i('[EmailService] 邮件共有 ${message.parts!.length} 个部分');
                for (var i = 0; i < message.parts!.length; i++) {
                  final part = message.parts![i];
                  AppLogger.d('[EmailService] Part $i: ${part.toString()}');
                }
              }

              // 尝试获取 HTML 内容并提取下载链接
              final htmlText = message.decodeTextHtmlPart();
              if (htmlText != null && htmlText.isNotEmpty) {
                AppLogger.i('[EmailService] HTML 内容长度: ${htmlText.length}');
                AppLogger.i('[EmailService] HTML 内容:\n$htmlText');

                // 提取下载链接
                wechatDownloadUrl = extractWeChatDownloadLink(htmlText);
                if (wechatDownloadUrl != null) {
                  AppLogger.i('[EmailService] 成功提取微信下载链接');
                }
              } else {
                AppLogger.w('[EmailService] 未找到 HTML 内容');
              }

              // 尝试获取纯文本内容
              final plainText = message.decodeTextPlainPart();
              if (plainText != null && plainText.isNotEmpty) {
                AppLogger.i('[EmailService] 纯文本内容长度: ${plainText.length}');
                AppLogger.i('[EmailService] 纯文本内容:\n$plainText');
              } else {
                AppLogger.w('[EmailService] 未找到纯文本内容');
              }

              AppLogger.i('[EmailService] ========== 微信邮件内容结束 ==========');
            }

            // 查找附件
            final attachments = message.findContentInfo();
            AppLogger.d('[EmailService] 找到 ${attachments.length} 个附件');

            // 如果是微信邮件且有下载链接，创建虚拟附件项
            if (isWeChatEmail && wechatDownloadUrl != null) {
              final subject = message.decodeSubject() ?? '(无主题)';
              final fileName = _extractFileNameFromSubject(subject);

              // 创建唯一的邮件项ID
              final uniqueId = '${message.uid?.toString() ?? message.sequenceId.toString()}_$fileName';

              // 检查是否已经添加过
              if (!billEmails.any((item) => item.messageId == uniqueId)) {
                final emailItem = BillEmailItem(
                  messageId: uniqueId,
                  subject: subject,
                  sender: sender,
                  date: message.decodeDate() ?? DateTime.now(),
                  attachmentName: fileName,
                  attachmentSize: 0, // 未知大小
                  platform: 'wechat',
                  downloadUrl: wechatDownloadUrl, // 保存下载链接
                );

                billEmails.add(emailItem);
                AppLogger.i('[EmailService] 添加微信账单邮件（通过下载链接）: $fileName');

                // 达到限制数量后停止
                if (billEmails.length >= limit) {
                  AppLogger.i('[EmailService] 已达到搜索限制: $limit');
                  break;
                }
              }

              // 如果已经处理了微信下载链接，跳过附件处理
              continue;
            }

            // 如果没有找到附件，跳过
            if (attachments.isEmpty) {
              AppLogger.w('[EmailService] findContentInfo() 未找到附件');
              continue;
            }

            // 只处理ZIP、CSV、XLSX附件
            for (final contentInfo in attachments) {
              final fileName = contentInfo.fileName ?? '';
              final extension = fileName.split('.').last.toLowerCase();
              AppLogger.d('[EmailService] 附件: $fileName ($extension)');

              if (!['zip', 'csv', 'xlsx', 'xls'].contains(extension)) {
                AppLogger.d('[EmailService] 跳过不支持的文件类型: $extension');
                continue;
              }

              // 确定平台
              String platform = 'unknown';
              if (sender.contains('alipay')) {
                platform = 'alipay';
              } else if (sender.contains('tenpay') || sender.contains('wechat') || sender.contains('tencent')) {
                platform = 'wechat';
              }
              AppLogger.d('[EmailService] 平台: $platform');

              // 创建唯一的邮件项ID（邮件ID + 附件名）
              final uniqueId = '${message.uid?.toString() ?? message.sequenceId.toString()}_$fileName';

              // 检查是否已经添加过这个附件
              if (billEmails.any((item) => item.messageId == uniqueId)) {
                AppLogger.d('[EmailService] 跳过重复的附件: $fileName');
                continue;
              }

              // 创建邮件项
              final emailItem = BillEmailItem(
                messageId: uniqueId,
                subject: message.decodeSubject() ?? '(无主题)',
                sender: sender,
                date: message.decodeDate() ?? DateTime.now(),
                attachmentName: fileName,
                attachmentSize: contentInfo.size ?? 0,
                platform: platform,
              );

              billEmails.add(emailItem);
              AppLogger.i('[EmailService] 添加账单邮件: $fileName');

              // 达到限制数量后停止
              if (billEmails.length >= limit) {
                AppLogger.i('[EmailService] 已达到搜索限制: $limit');
                break;
              }
            }

            // 如果已达到限制，停止处理更多邮件
            if (billEmails.length >= limit) {
              break;
            }
          } catch (e) {
            // 跳过解析失败的邮件
            AppLogger.w('[EmailService] 解析邮件失败', error: e);
            continue;
          }
        }

        // 如果已达到限制，停止搜索更多发件人
        if (billEmails.length >= limit) {
          break;
        }
      }

      // 按日期降序排序
      billEmails.sort((a, b) => b.date.compareTo(a.date));

      AppLogger.i('[EmailService] 搜索完成，共找到 ${billEmails.length} 封账单邮件');
      return billEmails;
    } catch (e) {
      AppLogger.e('[EmailService] 搜索邮件失败', error: e);
      throw Exception('搜索邮件失败: $e');
    }
  }

  /// 下载附件
  ///
  /// [messageId] 邮件ID（格式：uid_filename 或 sequenceId_filename）
  /// [attachmentName] 附件名称
  ///
  /// 返回下载的文件
  Future<File> downloadAttachment(
    String messageId,
    String attachmentName,
  ) async {
    if (!_isConnected || _imapClient == null) {
      throw Exception('邮箱未连接');
    }

    try {
      // 确保收件箱已选择
      await _imapClient!.selectInbox();

      // 解析邮件ID（格式：uid_filename）
      final parts = messageId.split('_');
      if (parts.isEmpty) {
        throw Exception('无效的邮件ID格式: $messageId');
      }

      final uid = int.tryParse(parts[0]);
      if (uid == null) {
        throw Exception('无效的邮件ID: $messageId');
      }

      // 获取邮件详情（包括附件信息）
      final fetchResult = await _imapClient!.fetchMessages(
        MessageSequence.fromId(uid),
        'BODY[]',
      );

      if (fetchResult.messages.isEmpty) {
        throw Exception('未找到邮件: $messageId');
      }

      final message = fetchResult.messages.first;

      // 查找指定的附件
      final attachments = message.findContentInfo();
      ContentInfo? targetAttachment;

      for (final contentInfo in attachments) {
        if (contentInfo.fileName == attachmentName) {
          targetAttachment = contentInfo;
          break;
        }
      }

      if (targetAttachment == null) {
        throw Exception('未找到附件: $attachmentName');
      }

      // 获取附件内容
      final mimePart = message.getPart(targetAttachment.fetchId);
      if (mimePart == null) {
        throw Exception('无法获取附件内容');
      }

      // 解码附件二进制数据
      final attachmentData = mimePart.decodeContentBinary();
      if (attachmentData == null) {
        throw Exception('无法解码附件数据');
      }

      // 创建临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(
        tempDir.path,
        'bill_import',
        attachmentName,
      ));

      // 确保目录存在
      await tempFile.parent.create(recursive: true);

      // 写入文件
      await tempFile.writeAsBytes(attachmentData);

      return tempFile;
    } catch (e) {
      throw Exception('下载附件失败: $e');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    if (_isConnected && _imapClient != null) {
      try {
        await _imapClient!.logout();
      } catch (e) {
        // 忽略登出错误
      }
      _isConnected = false;
      _imapClient = null;
    }
  }

  /// 测试连接
  static Future<bool> testConnection(EmailConfig config) async {
    final service = EmailService();
    try {
      await service.connect(config);
      await service.disconnect();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 从邮件主题中提取文件名
  String _extractFileNameFromSubject(String subject) {
    // 微信账单邮件主题格式：微信支付-账单流水文件(20260101-20260123)
    // 提取日期范围作为文件名
    final regex = RegExp(r'\((\d{8}-\d{8})\)');
    final match = regex.firstMatch(subject);

    if (match != null) {
      final dateRange = match.group(1);
      return '微信支付-账单流水文件($dateRange).zip';
    }

    // 如果无法提取，使用默认名称
    return '微信支付-账单流水文件.zip';
  }

  /// 从 HTML 内容中提取微信账单下载链接
  ///
  /// 返回下载链接，如果未找到则返回 null
  String? extractWeChatDownloadLink(String htmlContent) {
    try {
      final document = html_parser.parse(htmlContent);

      // 查找所有 <a> 标签
      final links = document.querySelectorAll('a');

      for (final link in links) {
        final href = link.attributes['href'];
        if (href != null && href.contains('tenpay.wechatpay.cn/userroll/userbilldownload')) {
          AppLogger.i('[EmailService] 找到微信下载链接: $href');
          return href;
        }
      }

      AppLogger.w('[EmailService] 未找到微信下载链接');
      return null;
    } catch (e) {
      AppLogger.e('[EmailService] 解析 HTML 失败', error: e);
      return null;
    }
  }

  /// 通过 HTTP 下载文件
  ///
  /// [url] 下载链接
  /// [fileName] 保存的文件名
  ///
  /// 返回下载的文件
  Future<File> downloadFileFromUrl(String url, String fileName) async {
    try {
      AppLogger.i('[EmailService] 开始下载文件: $url');

      // 发送 HTTP GET 请求
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('下载失败，HTTP状态码: ${response.statusCode}');
      }

      AppLogger.i('[EmailService] 下载成功，文件大小: ${response.bodyBytes.length} 字节');

      // 创建临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(path.join(
        tempDir.path,
        'bill_import',
        fileName,
      ));

      // 确保目录存在
      await tempFile.parent.create(recursive: true);

      // 写入文件
      await tempFile.writeAsBytes(response.bodyBytes);

      AppLogger.i('[EmailService] 文件已保存: ${tempFile.path}');
      return tempFile;
    } catch (e) {
      AppLogger.e('[EmailService] 下载文件失败', error: e);
      throw Exception('下载文件失败: $e');
    }
  }

  /// 处理邮件附件并导入（带验证）
  ///
  /// [messageId] 邮件ID
  /// [attachmentName] 附件名称
  /// [defaultAccountId] 默认账户ID
  ///
  /// 返回 ImportResult，包含交易列表和验证结果
  Future<ImportResult> processAttachmentWithValidation(
    String messageId,
    String attachmentName,
    int defaultAccountId,
  ) async {
    if (_billImportService == null) {
      throw Exception('BillImportService 未初始化');
    }

    try {
      AppLogger.i('[EmailService] 开始处理邮件附件: $attachmentName');

      // 1. 下载附件
      final file = await downloadAttachment(messageId, attachmentName);
      AppLogger.d('[EmailService] 附件已下载: ${file.path}');

      // 2. 检测文件类型
      final fileType = BillFileTypeExtension.fromFileName(attachmentName);
      AppLogger.d('[EmailService] 文件类型: $fileType');

      // 3. 根据文件类型调用相应的导入方法
      ImportResult result;
      switch (fileType) {
        case BillFileType.alipayCSV:
          AppLogger.d('[EmailService] 使用支付宝导入方法');
          result = await _billImportService.importAlipayCSVWithValidation(
            file,
            defaultAccountId,
          );
          break;

        case BillFileType.wechatXLSX:
          AppLogger.d('[EmailService] 使用微信导入方法');
          result = await _billImportService.importWeChatExcelWithValidation(
            file,
            defaultAccountId,
          );
          break;

        default:
          AppLogger.w('[EmailService] 不支持的文件类型: $fileType');
          throw Exception('不支持的文件类型: $attachmentName');
      }

      AppLogger.i('[EmailService] 附件处理完成，导入 ${result.successCount} 笔交易');

      // 4. 清理临时文件
      try {
        await file.delete();
        AppLogger.d('[EmailService] 临时文件已删除');
      } catch (e) {
        AppLogger.w('[EmailService] 删除临时文件失败', error: e);
      }

      return result;
    } catch (e) {
      AppLogger.e('[EmailService] 处理附件失败', error: e);
      rethrow;
    }
  }
}
