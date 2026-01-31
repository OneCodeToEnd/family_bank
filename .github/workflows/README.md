# GitHub Actions 自动构建说明

## 📦 自动构建的平台

此 workflow 会自动构建以下平台的应用包：

- **Android**：APK（直接安装）和 AAB（Google Play 发布）
- **Web**：可部署到任何 Web 服务器的静态文件
- **Linux**：x64 架构的 Linux 桌面应用
- **Windows**：x64 架构的 Windows 桌面应用

## 🚀 如何触发构建

### 方法 1：推送版本标签（推荐）

```bash
# 创建并推送版本标签
git tag v1.0.0
git push origin v1.0.0
```

标签命名规范：
- 必须以 `v` 开头
- 建议使用语义化版本号：`v主版本.次版本.修订号`
- 例如：`v1.0.0`, `v1.2.3`, `v2.0.0-beta.1`

### 方法 2：手动触发

1. 进入 GitHub 仓库页面
2. 点击 **Actions** 标签
3. 选择 **Build and Release** workflow
4. 点击 **Run workflow** 按钮
5. 选择分支并点击 **Run workflow**

## 📥 下载构建产物

构建完成后，可以在以下位置下载：

### GitHub Releases（推荐）
1. 进入仓库的 **Releases** 页面
2. 找到对应版本的 release
3. 在 **Assets** 区域下载需要的平台包

### GitHub Actions Artifacts
1. 进入 **Actions** 标签
2. 点击对应的 workflow 运行记录
3. 在 **Artifacts** 区域下载

## 📋 构建产物说明

| 文件名 | 平台 | 说明 |
|--------|------|------|
| `family-bank-android.apk` | Android | 可直接安装的 APK 文件 |
| `family-bank-android.aab` | Android | Google Play 发布用的 AAB 文件 |
| `family-bank-web.zip` | Web | 解压后可部署到 Web 服务器 |
| `family-bank-linux-x64.tar.gz` | Linux | 解压后运行 `family_bank` 可执行文件 |
| `family-bank-windows-x64.zip` | Windows | 解压后运行 `family_bank.exe` |

## ⚙️ 配置说明

### Flutter 版本
当前配置使用 Flutter 3.24.5 stable 版本。如需更改：

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.5'  # 修改此处
    channel: 'stable'
```

### 构建模式
所有平台默认使用 `--release` 模式构建，生成优化后的生产版本。

### Web 渲染器
Web 构建使用 `canvaskit` 渲染器，提供更好的性能和兼容性：

```yaml
run: flutter build web --release --web-renderer canvaskit
```

如需使用 HTML 渲染器（更小的包体积），可改为：
```yaml
run: flutter build web --release --web-renderer html
```

## 🔧 故障排查

### 构建失败
1. 检查 Actions 日志中的错误信息
2. 确保本地可以成功构建：`flutter build <platform> --release`
3. 检查 Flutter 版本是否与本地一致

### 依赖问题
如果出现依赖相关错误，可以在 workflow 中添加：
```yaml
- name: Clean and get dependencies
  run: |
    flutter clean
    flutter pub get
```

### 权限问题
确保仓库的 Actions 权限已启用：
1. 进入仓库 **Settings** > **Actions** > **General**
2. 在 **Workflow permissions** 中选择 **Read and write permissions**
3. 勾选 **Allow GitHub Actions to create and approve pull requests**

## 💰 成本估算

GitHub Actions 免费额度（每月）：
- Linux runner：2000 分钟
- Windows runner：2000 分钟（消耗 2x）
- macOS runner：2000 分钟（消耗 10x）

本 workflow 预估单次构建时间：
- Android：~5 分钟（Linux）
- Web：~3 分钟（Linux）
- Linux：~5 分钟（Linux）
- Windows：~8 分钟（Windows，消耗 16 分钟额度）

**总计**：约 13 分钟 Linux + 8 分钟 Windows = 29 分钟额度/次

免费账户每月可以构建约 **60+ 次**。

## 🎯 下一步优化

### 添加代码签名
- **Android**：配置 keystore 进行签名
- **Windows**：配置代码签名证书
- **macOS/iOS**：需要 Apple 开发者账号和证书

### 添加测试
在构建前运行测试：
```yaml
- name: Run tests
  run: flutter test
```

### 缓存优化
已启用 Flutter 缓存，可进一步优化：
```yaml
- name: Cache pub dependencies
  uses: actions/cache@v3
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}
```

### 部署 Web 版本
可以自动部署到 GitHub Pages：
```yaml
- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v3
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: ./build/web
```

## 📚 相关文档

- [GitHub Actions 文档](https://docs.github.com/en/actions)
- [Flutter CI/CD 最佳实践](https://docs.flutter.dev/deployment/cd)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
