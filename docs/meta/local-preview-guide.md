# MkDocs 本地查看指南

## 快速开始

### 1. 安装依赖（首次）

```bash
pip install mkdocs mkdocs-material
```

### 2. 启动本地服务器

```bash
# 在项目根目录执行
mkdocs serve
```

然后在浏览器访问：http://127.0.0.1:8000

### 3. 常用命令

```bash
# 启动开发服务器（支持热重载）
mkdocs serve

# 指定端口
mkdocs serve -a 127.0.0.1:8080

# 构建静态网站
mkdocs build

# 严格模式构建（检查断链）
mkdocs build --strict

# 部署到 GitHub Pages
mkdocs gh-deploy
```

## 文档编辑

- 修改 `docs/` 目录下的 Markdown 文件
- 保存后浏览器会自动刷新
- 新增文档需要在 `mkdocs.yml` 的 `nav` 部分添加导航

## 故障排查

### 构建失败

```bash
# 检查配置和链接
mkdocs build --strict
```

常见问题：
- 文档内部链接错误（使用相对路径）
- 文档未添加到导航配置
- Markdown 语法错误

### 端口被占用

```bash
# 使用其他端口
mkdocs serve -a 127.0.0.1:8001
```

## 文档结构

```
docs/
├── index.md              # 首页
├── getting-started/      # 快速开始
├── features/             # 功能特性
├── architecture/         # 架构设计
├── design/               # 设计文档
├── implementation/       # 实现细节
├── development/          # 开发指南
└── reference/            # 参考文档
```

## 配置文件

- `mkdocs.yml` - MkDocs 配置文件
- 主题：Material for MkDocs
- 语言：中文（zh）
- 支持深色/浅色模式切换
