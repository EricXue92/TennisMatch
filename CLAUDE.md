# CLAUDE.md

## 项目

Let's Tennis — iOS 网球约球 App。SwiftUI，iOS 26+

## 构建 & 运行

- 用 Xcode 打开 `TennisMatch.xcodeproj`
- Scheme: `TennisMatch`，模拟器运行即可
- 入口: `TennisMatchApp.swift` → 当前加载 `HomeView`

## 目录结构

```
TennisMatch/
├── TennisMatchApp.swift   # App 入口
├── Theme/                 # 设计 token
│   ├── Theme.swift        # 颜色
│   ├── Typography.swift   # 字体
│   └── Spacing.swift      # 间距
├── Views/                 # 所有页面（每页一个文件）
├── Components/            # 可复用组件（待填充）
├── Models/                # 数据模型（待填充）
└── Assets.xcassets        # 图片资源
```

## 核心规则

1. **响应式布局**，适配 iPhone SE → 17 Pro Max
   - 宽度用 `.frame(maxWidth: .infinity)`，不写死 393
   - 内间距/圆角/字号保留 pt 值

2. **禁止硬编码设计值**
   - 颜色 → `Theme.swift`
   - 字体 → `Typography.swift`
   - 间距 → `Spacing.swift`（8 的倍数）

3. **iOS HIG**
   - 最小点击区 44pt
   - 图标优先 SF Symbols
   - 导航用 `NavigationStack`，滚动用 `ScrollView`

4. **每个 View 必须**
   - 提供至少 2 个机型的 `#Preview`（iPhone SE + iPhone 15 Pro）
   - 使用 mock 数据，不接网络

5. **组件复用**
   - 多处复用 → 抽到 `Components/`
   - 单页面内子视图 → 同文件 `private struct`

## 禁止

- ❌ 一次做 3 个以上页面
- ❌ 硬编码颜色/字体/间距
- ❌ 改 `.xcodeproj` 文件
- ❌ 加第三方依赖
- ❌ 删除/重命名现有文件

## SwiftUI 避坑（iOS 26+）

- ❌ `Text("A") + Text("B")` → ✅ `Text("A\(Text("B").bold())")`
- ❌ `.onChange(of: x) { newValue in }` → ✅ `.onChange(of: x) { oldValue, newValue in }`
- ❌ `#Preview { ... .previewDevice("iPhone 15 Pro") }` → ✅ 直接用 Canvas 设备选择器
- ❌ `.preferredColorScheme(.dark)` 在子视图（会污染整个窗口）→ ✅ `.toolbarColorScheme(.dark, for: .navigationBar)` 只控制导航栏
