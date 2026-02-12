# 文档站点设置指南

本指南说明如何设置和部署账清项目的文档站点。

## 本地预览

### 1. 安装依赖

```bash
# 使用pip安装MkDocs和相关插件
pip install -r requirements.txt

# 或者单独安装
pip install mkdocs-material
```

### 2. 本地运行

```bash
# 启动开发服务器
mkdocs serve

# 访问 http://127.0.0.1:8000 查看文档
```

### 3. 构建静态文件

```bash
# 构建文档站点
mkdocs build

# 生成的文件在 site/ 目录
```

---

## GitHub Pages部署

### 自动部署（推荐）

项目已配置GitHub Actions自动部署，当以下情况发生时会自动触发：

1. 推送到main分支且修改了docs/目录或mkdocs.yml
2. 手动触发workflow

**首次设置步骤**：

1. 进入GitHub仓库设置
2. 导航到 **Settings** → **Pages**
3. 在 **Source** 下选择 **GitHub Actions**
4. 推送代码后，Actions会自动构建并部署

文档将发布到: `https://onecodetoend.github.io/family_bank/`

### 手动部署

如果需要手动部署：

```bash
# 构建并部署到gh-pages分支
mkdocs gh-deploy

# 或指定远程仓库
mkdocs gh-deploy --remote-name origin
```

---

## 文档结构

```
docs/
├── index.md                    # 首页
├── getting-started/            # 快速开始
│   ├── installation.md         # 安装指南
│   └── quickstart.md           # 快速上手
├── features/                   # 功能特性
│   ├── accounts.md             # 账户管理
│   ├── categories.md           # 分类系统
│   ├── transactions.md         # 交易记录
│   ├── bill-import.md          # 账单导入
│   ├── ai-classification.md    # AI智能分类
│   ├── analysis.md             # 数据分析
│   └── backup-sync.md          # 备份与同步
├── architecture/               # 架构设计
│   ├── tech-stack.md           # 技术栈
│   ├── database.md             # 数据库设计
│   ├── state-management.md     # 状态管理
│   └── services.md             # 服务层
├── development/                # 开发指南
│   ├── setup.md                # 开发环境
│   ├── coding-standards.md     # 代码规范
│   ├── testing.md              # 测试指南
│   └── building.md             # 构建发布
├── reference/                  # 参考文档
│   ├── database-schema.md      # 数据库Schema
│   ├── api.md                  # API文档
│   └── faq.md                  # 常见问题
└── changelog.md                # 更新日志
```

---

## 编写文档

### Markdown语法

MkDocs使用标准Markdown语法，并支持以下扩展：

#### 代码块

\`\`\`dart
void main() {
  print('Hello World');
}
\`\`\`

#### 提示框

!!! note "提示"
    这是一个提示框

!!! warning "警告"
    这是一个警告框

!!! tip "技巧"
    这是一个技巧框

#### 标签页

=== "macOS"
    macOS相关内容

=== "Windows"
    Windows相关内容

=== "Linux"
    Linux相关内容

#### 任务列表

- [x] 已完成任务
- [ ] 待完成任务

---

## 配置说明

### mkdocs.yml

主配置文件，包含：

- **site_name**: 站点名称
- **theme**: 主题配置（使用Material主题）
- **nav**: 导航结构
- **plugins**: 插件配置
- **markdown_extensions**: Markdown扩展

### 主题定制

在`mkdocs.yml`中可以自定义：

- 颜色方案（primary, accent）
- 字体
- 图标
- 导航特性
- 搜索功能

---

## 常见问题

### 本地预览时样式不正常

确保已安装所有依赖：
```bash
pip install -r requirements.txt
```

### 部署后页面404

1. 检查GitHub Pages设置是否正确
2. 确认Actions workflow执行成功
3. 等待几分钟让GitHub Pages更新

### 中文搜索不工作

已在配置中启用中文搜索支持：
```yaml
plugins:
  - search:
      lang:
        - zh
        - en
```

---

## 更新文档

1. 编辑docs/目录下的Markdown文件
2. 本地预览确认无误
3. 提交并推送到main分支
4. GitHub Actions自动部署

---

## 参考资源

- [MkDocs官方文档](https://www.mkdocs.org/)
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)
- [Markdown语法指南](https://www.markdownguide.org/)
- [GitHub Pages文档](https://docs.github.com/en/pages)