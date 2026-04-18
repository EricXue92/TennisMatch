# CLAUDE.md

## 项目

Let's Tennis — iOS 网球约球 App。SwiftUI，iOS 16+，设计稿在 Figma（通过 MCP 读取）。

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

## Figma 工作流

收到 Figma 链接后：
1. 用 MCP 读取 → **先汇报**尺寸、颜色、结构
2. 等我确认后再写代码
3. 信息缺失时明确说明你的假设

## 任务汇报

每次任务完成后，说明：
- 修改了哪些画板
- 复用了哪些 token/组件
- 新增了什么（附理由）

## 禁止

- ❌ 一次做 3 个以上页面
- ❌ 硬编码颜色/字体/间距
- ❌ 改 `.xcodeproj` 文件
- ❌ 加第三方依赖
- ❌ 删除/重命名现有文件

## Figma 文件

File Key: `glLUNB4aWqSejCPm09NEe0`，基准 393×852，目前共 14 个页面。