---
description: 创建 Git 发布标签 - 基于 pubspec.yaml 版本号创建标签并推送
allowed-tools: [Bash, Read, AskUserQuestion]
argument-hint: [可选参数: --push 自动推送标签到远程]
---

# 创建发布标签

基于 pubspec.yaml 中的版本号创建 Git 标签，用于版本发布管理。

## 执行流程

1. **读取版本信息**
   - 从 pubspec.yaml 读取当前版本号
   - 格式：`version: x.y.z+build`（如 1.0.0+1）

2. **检查标签状态**
   - 运行 `git tag -l` 查看已有标签
   - 检查当前版本标签是否已存在
   - 如果标签已存在，询问用户是否覆盖

3. **生成发布说明**
   - 运行 `git log` 查看最近的提交
   - 分析提交内容，生成发布说明
   - 包含新功能、修复、改进等分类

4. **创建标签**
   - 使用 `git tag -a v{version} -m "Release v{version}"` 创建带注释的标签
   - 标签信息包含：
     - 版本号
     - 发布日期
     - 主要更新内容
     - 构建信息

5. **推送标签（可选）**
   - 如果用户提供 `--push` 参数，自动推送标签
   - 否则询问用户是否推送
   - 运行 `git push origin v{version}` 推送标签

## 标签格式

```
v{version}

Release v{version} - {date}

主要更新：
- 新功能：xxx
- 修复：xxx
- 改进：xxx

构建信息：
- Flutter 版本：xxx
- 构建号：xxx

🤖 Generated with Claude Code
```

## 使用示例

```bash
# 创建标签但不推送
/release-tag

# 创建标签并自动推送
/release-tag --push
```

## 注意事项

- 确保当前分支是 main/master
- 确保工作区是干净的（无未提交的修改）
- 标签创建后可以触发 GitHub Actions 自动构建
- 如果需要删除标签：`git tag -d v{version}` 和 `git push origin :refs/tags/v{version}`

## 版本号规范

遵循语义化版本（Semantic Versioning）：
- **主版本号（Major）**: 不兼容的 API 修改
- **次版本号（Minor）**: 向下兼容的功能性新增
- **修订号（Patch）**: 向下兼容的问题修正
- **构建号（Build）**: 构建次数或内部版本号
