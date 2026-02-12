# 图标设计规范指南

## 问题说明
当前图标在 Android 和 macOS 上显示过大，原因是图标内容占满了整个画布，没有留足够的内边距。

## 设计规范

### 1. 源图标尺寸
- **推荐尺寸**: 1024x1024 px
- **格式**: PNG（带透明通道）

### 2. Android Adaptive Icon 规范

#### 画布分区（基于 1024x1024）
```
┌─────────────────────────────────────┐
│  Trim Area (裁剪区域)                │
│  ┌───────────────────────────────┐  │
│  │  Safe Zone (安全区域)          │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │                         │  │  │
│  │  │   图标内容应在此区域内    │  │  │
│  │  │                         │  │  │
│  │  └─────────────────────────┘  │  │
│  │                               │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

#### 具体尺寸（1024x1024 画布）
- **整个画布**: 1024x1024 px
- **Trim Area（裁剪区域）**: 864x864 px（中心区域，84.4%）
- **Safe Zone（安全区域）**: 676x676 px（中心区域，66%）
- **推荐内容区域**: 650x650 px（留一点额外边距）

#### 计算方式
- Safe Zone 边距 = (1024 - 676) / 2 = **174 px**（上下左右各留 174px）
- 推荐内容边距 = (1024 - 650) / 2 = **187 px**（上下左右各留 187px）

### 3. macOS 图标规范

#### 尺寸建议（1024x1024 画布）
- **推荐内容区域**: 820x820 px（80% 的画布）
- **内边距**: 102 px（上下左右各留 102px，约 10%）

#### 设计要点
- macOS 会自动添加阴影和圆角效果
- 图标不应该太满，需要"呼吸空间"
- 避免在边缘放置重要内容

### 4. iOS 图标规范
- **内容区域**: 约 820x820 px（80%）
- **内边距**: 102 px（上下左右各留 102px）
- iOS 会自动添加圆角，不要在图标中预设圆角

## 当前图标问题

### 问题分析
当前的 `app_icon.png` 图标内容几乎占满整个画布：
- 房子和钱包的图形延伸到画布边缘
- 没有留足够的内边距
- 在 Android 圆形裁剪时，边缘会被切掉
- 在 macOS 上显得过于拥挤

### 视觉效果对比
```
当前设计（不推荐）:
┌─────────────────┐
│🏠💰            │  ← 图标内容占满画布
└─────────────────┘

推荐设计:
┌─────────────────┐
│                 │
│    🏠💰        │  ← 图标内容缩小，周围留白
│                 │
└─────────────────┘
```

## 修改建议

### 方案 1: 整体缩小图标内容（推荐）
**适用于**: 所有平台使用同一个图标

1. **目标尺寸**: 将图标内容缩小到 650x650 px 区域内
2. **操作步骤**:
   - 在设计软件中打开 1024x1024 画布
   - 将当前图标内容等比例缩小到约 63.5%（650/1024）
   - 确保图标内容居中
   - 上下左右各留 187 px 的透明边距

3. **检查要点**:
   - 房子的屋顶和底部距离画布边缘至少 187 px
   - 钱包的左右边缘距离画布边缘至少 187 px
   - 所有重要元素都在安全区域内

### 方案 2: 创建专门的 Android 前景图
**适用于**: Android 使用单独的前景图，其他平台使用原图标

1. **创建新文件**: `app_icon_adaptive_foreground.png`（1024x1024）
2. **内容尺寸**: 650x650 px（居中）
3. **背景**: 完全透明
4. **更新配置**:
   ```yaml
   adaptive_icon_foreground: "assets/icon/app_icon_adaptive_foreground.png"
   ```

### 方案 3: 简化图标设计
如果缩小后图标细节不清晰，考虑简化设计：
- 减少线条粗细
- 简化房子和钱包的细节
- 使用更大胆的图形元素

## 设计工具建议

### 使用 Figma/Sketch/Illustrator
1. 创建 1024x1024 画布
2. 添加参考线：
   - 安全区域: 174px, 850px（水平和垂直）
   - 推荐区域: 187px, 837px（水平和垂直）
3. 将图标内容限制在参考线内

### 使用在线工具
- **Figma**: 免费，支持导出高质量 PNG
- **Canva**: 简单易用，适合非设计师
- **GIMP**: 免费开源图像编辑器

## 测试建议

### 生成图标后测试
```bash
# 1. 生成图标
flutter pub run flutter_launcher_icons

# 2. 在不同设备上测试
flutter run -d android    # Android 设备
flutter run -d macos      # macOS
flutter run -d ios        # iOS（如果有 Mac）

# 3. 检查不同形状的显示效果
# Android: 在设置中查看不同启动器的图标形状
# macOS: 在 Finder 和 Dock 中查看
```

### 视觉检查清单
- [ ] Android 圆形裁剪：图标内容完整，无被切边
- [ ] Android 方形裁剪：周围有适当留白
- [ ] macOS Dock：图标清晰，不显得拥挤
- [ ] macOS Finder：图标在不同尺寸下都清晰
- [ ] 深色/浅色背景：图标在两种背景下都清晰可见

## 快速修复步骤

如果你想快速修复当前图标：

1. **使用图像编辑器**（如 Photoshop、GIMP）:
   ```
   - 打开 app_icon.png
   - 画布大小保持 1024x1024
   - 选择图标内容图层
   - 等比例缩小到 63.5%（或 650px 宽度）
   - 居中对齐
   - 导出为 PNG
   ```

2. **重新生成图标**:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

3. **重新构建应用**:
   ```bash
   flutter clean
   flutter build apk --release    # Android
   flutter build macos --release  # macOS
   ```

## 参考资源

- [Android Adaptive Icons 官方文档](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Flutter Launcher Icons 文档](https://pub.dev/packages/flutter_launcher_icons)

## 总结

**关键要点**:
- Android adaptive icon 前景图内容应在 650x650 px 区域内（1024x1024 画布）
- macOS 图标内容应在 820x820 px 区域内
- 周围留白是必需的，不是可选的
- 测试时检查不同形状和背景下的显示效果
