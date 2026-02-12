# 邮箱账单同步功能实现文档

## 功能概述

通过IMAP协议连接用户邮箱，自动检测并下载支付宝/微信发送的账单附件，用户手动选择邮件并输入解压密码后自动导入账单。

## 实现状态

### ✅ 已完成

#### 1. 依赖包添加
- `enough_mail: ^2.1.0` - 邮件处理
- `archive: ^3.4.0` - ZIP解压（支持密码）

文件：`pubspec.yaml:88-92`

#### 2. 数据模型
- **EmailConfig** (`lib/models/email_config.dart`)
  - 邮箱配置模型
  - 包含邮箱地址、IMAP服务器、端口、密码等信息
  - 密码加密存储

- **BillEmailItem** (`lib/models/bill_email_item.dart`)
  - 账单邮件项模型
  - 包含邮件ID、主题、发件人、附件信息等
  - 支持用户选择和密码输入

#### 3. 服务层

- **UnzipService** (`lib/services/import/unzip_service.dart`)
  - ZIP文件解压
  - 密码验证
  - 临时文件清理

- **EmailService** (`lib/services/import/email_service.dart`)
  - IMAP连接和认证
  - 搜索特定发件人的邮件（支付宝/微信）
  - 下载邮件附件
  - 支持的发件人：
    - 支付宝：`service@mail.alipay.com`
    - 微信：`wxpay@tenpay.com`

- **EmailConfigDbService** (`lib/services/database/email_config_db_service.dart`)
  - 邮箱配置的CRUD操作
  - 密码加密存储（使用EncryptionService）
  - 启用/禁用状态管理

#### 4. 数据库

- **数据库版本**：升级到 V5
- **新增表**：`email_configs`
  ```sql
  CREATE TABLE email_configs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    imap_server TEXT NOT NULL,
    imap_port INTEGER NOT NULL,
    password TEXT NOT NULL,
    is_enabled INTEGER DEFAULT 1,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
  )
  ```

- **文件位置**：
  - 表创建：`lib/services/database/database_service.dart:198-210`
  - 升级逻辑：`lib/services/database/database_service.dart:401-415`
  - 常量定义：`lib/constants/db_constants.dart:5,17`

### 🚧 待完成

#### 1. 邮箱配置页面
**文件**：`lib/screens/settings/email_config_screen.dart`

**功能**：
- 邮箱地址输入
- IMAP服务器配置（预设常见邮箱）
- 端口配置（默认993）
- 密码/授权码输入
- 测试连接功能
- 保存配置

**UI布局**：
```
┌─────────────────────────────────────┐
│  ← 邮箱账单同步设置                   │
├─────────────────────────────────────┤
│  📧 邮箱配置                         │
│  [邮箱地址输入框]                    │
│  [IMAP服务器输入框]                  │
│  [端口输入框]                        │
│  [密码输入框]                        │
│                                     │
│  ℹ️ 常见邮箱IMAP设置                 │
│  • QQ邮箱: imap.qq.com:993         │
│  • 163邮箱: imap.163.com:993       │
│  • Gmail: imap.gmail.com:993       │
│                                     │
│  [测试连接]  [保存配置]              │
└─────────────────────────────────────┘
```

#### 2. 邮件选择页面
**文件**：`lib/screens/import/email_bill_select_screen.dart`

**功能**：
- 连接邮箱并搜索账单邮件
- 展示邮件列表（支付宝/微信）
- 用户勾选需要导入的邮件
- 为每个选中的邮件输入解压密码
- 下载、解压、解析账单
- 跳转到现有的导入确认页面

**UI布局**：
```
┌─────────────────────────────────────┐
│  ← 选择账单邮件                      │
├─────────────────────────────────────┤
│  [正在搜索邮件...]                   │
│                                     │
│  ☑️ 支付宝账单_202601.zip            │
│     2026-01-15  1.2MB               │
│     [输入解压密码]                   │
│                                     │
│  ☑️ 微信账单_202601.xlsx             │
│     2026-01-10  856KB               │
│     [输入解压密码]                   │
│                                     │
│  □ 支付宝账单_202512.zip             │
│     2025-12-20  1.5MB               │
│                                     │
│  [取消]  [导入选中的账单(2)]         │
└─────────────────────────────────────┘
```

#### 3. 设置页面入口
**文件**：`lib/screens/settings/settings_screen.dart`

**修改**：
- 在"数据管理"或"导入导出"部分添加"邮箱账单同步"选项
- 点击跳转到邮箱配置页面（如果未配置）或邮件选择页面（如果已配置）

#### 4. 文档更新
**文件**：`docs/database_schema.md`

**内容**：
- 添加 `email_configs` 表的schema说明
- 字段说明
- 索引说明
- 安全性说明（密码加密）

## 核心流程

```
1. 用户首次使用
   ↓
2. 进入邮箱配置页面
   ↓
3. 输入邮箱信息（地址、IMAP服务器、密码）
   ↓
4. 测试连接（可选）
   ↓
5. 保存配置
   ↓
6. 点击"从邮箱同步账单"
   ↓
7. 连接邮箱，搜索支付宝/微信的账单邮件
   ↓
8. 展示邮件列表
   ↓
9. 用户勾选需要导入的邮件
   ↓
10. 为每个邮件输入解压密码
   ↓
11. 下载附件到临时目录
   ↓
12. 使用密码解压ZIP文件
   ↓
13. 识别文件类型（CSV/XLSX）
   ↓
14. 调用现有的 BillImportService 解析
   ↓
15. 跳转到 ImportConfirmationScreen 预览
   ↓
16. 用户确认导入
   ↓
17. 清理临时文件
   ↓
18. 完成
```

## 技术细节

### 邮箱连接
- 协议：IMAP over SSL/TLS
- 端口：993（标准SSL端口）
- 认证：用户名密码（部分邮箱需要授权码）

### 邮件搜索规则
```dart
SearchQueryBuilder()
  .from(sender)           // 发件人过滤
  .withAttachment()       // 必须有附件
  .since(DateTime)        // 时间过滤（可选）
```

### 附件识别
- 文件扩展名：`.zip`, `.csv`, `.xlsx`
- 发件人验证：
  - 支付宝：包含 `alipay`
  - 微信：包含 `tenpay` 或 `wechat`

### 密码加密
- 使用现有的 `EncryptionService`
- AES加密算法
- 密码存储在数据库中加密
- 使用时解密

### 临时文件管理
- 下载位置：`getTemporaryDirectory()/bill_import/`
- 解压位置：同上
- 导入完成后自动清理

## 安全性考虑

1. **密码加密存储**
   - 邮箱密码使用AES加密
   - 解压密码不存储，每次手动输入

2. **权限控制**
   - 只读取特定发件人的邮件
   - 只下载ZIP/CSV/XLSX附件
   - 不修改邮箱内容

3. **临时文件清理**
   - 导入完成后立即删除
   - 应用退出时清理残留文件

4. **错误处理**
   - 连接失败提示
   - 密码错误提示
   - 网络异常重试

## 常见问题

### "Unsafe Login" 错误

**错误信息**：
```
Exception: 搜索邮件失败: SELECT Unsafe Login. Please contact kefu@188.com for help
```

**原因**：
中国的邮箱服务商（QQ、163、126等）对第三方客户端有额外的安全限制。

**解决方案**：

1. **使用授权码而非登录密码**
   - QQ邮箱：设置 → 账户 → 开启IMAP/SMTP服务 → 生成授权码
   - 163邮箱：设置 → POP3/SMTP/IMAP → 开启IMAP服务 → 设置客户端授权密码
   - 126邮箱：设置 → 客户端授权密码 → 开启IMAP服务 → 设置授权密码

2. **确保已开启IMAP服务**
   - 登录邮箱网页版
   - 进入设置页面
   - 找到 POP3/SMTP/IMAP 设置
   - 开启 IMAP/SMTP 服务

3. **允许第三方客户端访问**
   - 部分邮箱需要在安全设置中允许第三方客户端
   - 关闭"安全登录"或"只允许安全客户端"选项

4. **检查网络环境**
   - 确保网络连接正常
   - 部分邮箱可能限制海外IP访问

**测试步骤**：
1. 在邮箱配置页面输入邮箱地址
2. 输入授权码（不是登录密码）
3. 点击"测试连接"
4. 如果测试成功，说明配置正确

## 常见邮箱IMAP设置

| 邮箱服务商 | IMAP服务器 | 端口 | 说明 |
|-----------|-----------|------|------|
| QQ邮箱 | imap.qq.com | 993 | 需要开启IMAP并获取授权码 |
| 163邮箱 | imap.163.com | 993 | 需要开启IMAP并获取授权码 |
| Gmail | imap.gmail.com | 993 | 需要开启IMAP和应用专用密码 |
| Outlook | outlook.office365.com | 993 | 直接使用账号密码 |
| 126邮箱 | imap.126.com | 993 | 需要开启IMAP并获取授权码 |

## 用户使用指南

### 1. 获取邮箱授权码

**QQ邮箱**：
1. 登录QQ邮箱网页版
2. 设置 → 账户
3. 开启IMAP/SMTP服务
4. 生成授权码

**163邮箱**：
1. 登录163邮箱网页版
2. 设置 → POP3/SMTP/IMAP
3. 开启IMAP服务
4. 设置客户端授权密码

### 2. 申请账单

**支付宝**：
1. 打开支付宝APP → 我的 → 账单
2. 右上角设置 → 开具交易流水证明
3. 选择时间范围 → 申请邮箱接收
4. 下载CSV文件（会发送到邮箱）

**微信**：
1. 打开微信 → 我 → 服务 → 钱包
2. 账单 → 常见问题 → 下载账单
3. 选择时间范围 → 申请邮箱接收
4. 下载XLSX文件（会发送到邮箱）

### 3. 使用应用同步

1. 在应用中配置邮箱
2. 点击"从邮箱同步账单"
3. 选择需要导入的邮件
4. 输入解压密码（通常在邮件正文中）
5. 确认导入

## 测试计划

### 单元测试
- [ ] UnzipService 解压功能
- [ ] EmailService 连接和搜索
- [ ] EmailConfigDbService 数据库操作

### 集成测试
- [ ] 完整的邮箱连接流程
- [ ] 邮件搜索和下载
- [ ] 解压和导入流程

### 用户测试
- [ ] QQ邮箱连接测试
- [ ] 163邮箱连接测试
- [ ] 支付宝账单导入测试
- [ ] 微信账单导入测试
- [ ] 密码错误处理测试
- [ ] 网络异常处理测试

## 已知限制

1. **邮箱限制**
   - 部分邮箱需要开启IMAP服务
   - 部分邮箱需要使用授权码而非密码
   - Gmail需要应用专用密码

2. **附件限制**
   - 只支持ZIP、CSV、XLSX格式
   - 附件大小受邮箱服务商限制

3. **平台限制**
   - 只支持支付宝和微信的官方邮件
   - 发件人地址固定

## 未来优化

1. **自动同步**
   - 后台定时同步
   - 推送通知

2. **多邮箱支持**
   - 支持配置多个邮箱
   - 同时搜索多个邮箱

3. **智能识别**
   - 自动识别账单类型
   - 自动提取解压密码

4. **同步历史**
   - 记录同步历史
   - 避免重复导入

## 参考资料

- [enough_mail 文档](https://pub.dev/packages/enough_mail)
- [archive 文档](https://pub.dev/packages/archive)
- [IMAP协议](https://tools.ietf.org/html/rfc3501)
- [支付宝账单导出](https://opendocs.alipay.com/)
- [微信账单导出](https://pay.weixin.qq.com/)

---

**文档维护者**: Claude
**最后更新**: 2026-01-20
**项目**: 账清 (Family Bank) - 个人账单流水分析APP
