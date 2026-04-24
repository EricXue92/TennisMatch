# App 多语言切换 — 设计文档

**日期**：2026-04-24
**状态**：Draft → 待用户 review

## 1. 目标

在设置页加入"语言"选项，支持用户在 **简体中文 / 繁體中文 / English** 之间切换；默认**跟随系统**。切换后整个 App 的所有面向用户的字符串、日期、数字格式立即响应（无需重启）。

## 2. 技术架构

### 2.1 不做的事

- ❌ 不做 `Bundle` 方法 swizzling（hacky、易踩坑、难维护）
- ❌ 不让用户在切换后必须重启 App
- ❌ 不在第一阶段就强行翻译所有页面（见迁移策略）

### 2.2 核心组件

#### `LocaleManager`（`@Observable` 单例）

```swift
@Observable
final class LocaleManager {
    static let shared = LocaleManager()

    enum AppLanguage: String, CaseIterable, Identifiable {
        case system, zhHans, zhHant, en
        var id: String { rawValue }
    }

    var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Self.storageKey)
        }
    }

    /// 当前生效的 Locale —— SwiftUI env 注入用
    var currentLocale: Locale {
        switch selectedLanguage {
        case .system: return .autoupdatingCurrent
        case .zhHans: return Locale(identifier: "zh-Hans")
        case .zhHant: return Locale(identifier: "zh-Hant")
        case .en:     return Locale(identifier: "en")
        }
    }

    private static let storageKey = "appLanguage"

    private init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppLanguage.system.rawValue
        self.selectedLanguage = AppLanguage(rawValue: raw) ?? .system
    }
}
```

#### 根节点注入

`TennisMatchApp.swift` 的根 View 上：

```swift
@State private var localeManager = LocaleManager.shared
// ...
.environment(\.locale, localeManager.currentLocale)
.environment(localeManager)
```

SwiftUI 的 `Text("...")`、`Label`、`Button("...")`、`navigationTitle("...")` 等所有 `LocalizedStringKey` 接口会自动从 env locale 读字符串目录。改 `selectedLanguage` → `currentLocale` 变化 → SwiftUI 全树重渲染 → 所有文案/日期/数字立刻切换。

### 2.3 字符串目录

新建 `Localizable.xcstrings`（String Catalog，Xcode 15+ 原生）：

- **Source language**：`zh-Hant`（与现有代码一致，零改动）
- **Translatable target languages**：`zh-Hans`、`en`
- Xcode build 时自动从代码中扫描 `Text("...")`、`String(localized:)` 等并注册 key
- 手动在 Xcode String Catalog 编辑器里补翻译

### 2.4 非 SwiftUI 字符串

Toast、alert message、Model 里产出的动态字符串需要显式传 locale：

```swift
let manager = LocaleManager.shared
toastMessage = String(localized: "已關聯\(title)", locale: manager.currentLocale)
```

封装一个轻量辅助函数：

```swift
enum L10n {
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: LocaleManager.shared.currentLocale)
    }
}

// 用法
toastMessage = L10n.string("已關聯\(title)")
```

### 2.5 Info.plist / Project 配置

- `CFBundleDevelopmentRegion = zh-Hant`
- `CFBundleLocalizations = ["zh-Hant", "zh-Hans", "en"]`
- Xcode project 的 "Localizations" 列表里加上 zh-Hans、en

## 3. UI 设计：Settings 页"语言"行

在 `SettingsView` 的 `aboutSection` **上方**新增 section：**"通用"**（English: "General" / 简中: "通用"）。

新 section 内放一个 `Picker`：

```swift
private var generalSection: some View {
    Section {
        Picker(selection: $languageSelection) {
            Text("跟隨系統").tag(LocaleManager.AppLanguage.system)
            Text("简体中文").tag(LocaleManager.AppLanguage.zhHans)
            Text("繁體中文").tag(LocaleManager.AppLanguage.zhHant)
            Text("English").tag(LocaleManager.AppLanguage.en)
        } label: {
            Label("語言", systemImage: "globe")
                .font(Typography.fieldValue)
                .foregroundColor(Theme.textPrimary)
        }
    } header: {
        Text("通用")
    }
}
```

- 视觉与现有 Picker 行（如"誰能看到我的資料"）完全一致
- 图标用 SF Symbol `globe`
- 选中"跟隨系統"时，显示当前系统语言对应的次行说明（可选，初版可省）

## 4. 迁移策略（分阶段）

整个 App 估计 600–1000 个面向用户的字符串。**绝不一个 PR 全做完**。

### Phase 1（本设计的实施目标）：基础设施 + 设置页 + Tab Bar

- 建好 `LocaleManager`、根节点 env 注入、`Localizable.xcstrings`、project localizations 配置
- `SettingsView` 加"通用 / 语言" section
- **完整翻译**以下范围（提供 zh-Hans 和 en 翻译）：
  - `SettingsView`（含子 sheet：`ChangePasswordSheet`、`LinkedAccountsSheet`）
  - 主 Tab Bar 标签
- 其他所有页面**保持现状**：代码不动，xcstrings 中暂无对应翻译条目，切到 zh-Hans/en 时 SwiftUI 自动 fallback 到 source locale（zh-Hant）

**Phase 1 完成后用户能看到**：
- 设置页有"语言"行
- 切换语言后，**设置页本身**和 **Tab Bar** 立即变成所选语言；其他页面仍是繁中（已知短期状态）

### Phase 2 ~ N（后续 PR）

按页面/功能区批次推进，每个 PR 翻译 1–3 个 View。优先级建议：

1. HomeView + 子组件
2. MyMatchesView + MatchDetailView + CreateMatchView
3. ProfileView + EditProfileView + PublicProfileView
4. MessagesView + ChatDetailView
5. NotificationsView
6. TournamentView + CreateTournamentView
7. 其余 View（NTRPGuide、Help、Terms、Privacy 等长文本）
8. Models 内的动态字符串（toast、通知文案等）

每个后续 PR 都遵循同样的模式：把目标 View 内所有用户可见字符串迁移到 xcstrings，补 zh-Hans 和 en 翻译。

## 5. 验收标准（Phase 1）

- [ ] App 启动后默认跟随系统语言（zh-Hans 系统 → 设置页显示简中；en 系统 → 设置页显示英文；其他系统 → fallback 到 zh-Hant）
- [ ] 在设置页选择语言，**当前页面立即切换**（无需重启、无需返回）
- [ ] 选择"跟隨系統"后，杀掉 App 重启，仍跟随系统
- [ ] 选择固定语言（如"English"）后，杀掉 App 重启，仍是英文
- [ ] Tab Bar 标签随语言切换
- [ ] 其他未翻译页面正常显示繁中（不出现 key 名或 ??? 占位）
- [ ] 切换语言时不出现闪烁、白屏、崩溃
- [ ] 设置页内所有原有功能（修改密碼、關聯帳號等）继续工作

## 6. 风险与备注

- **String Catalog 需要 Xcode 15+** —— 假定开发环境满足
- **`Locale.autoupdatingCurrent` 在 App 运行中变化系统语言时**会触发更新，符合预期
- **持久化的语言偏好与系统不同步**是用户预期行为（用户主动选择固定语言后，不应该被系统设置覆盖）
- **第三方组件 / 系统弹框**（如系统的"允许通知"对话框）的语言由系统控制，不受我们设置影响 —— 这是 iOS 限制，不在本设计范围
- **图片资源**目前未涉及多语言图片，不需要 `.lproj` 资产分组

## 7. 不在本期范围

- 翻译 Phase 1 范围外的任何页面
- RTL 语言支持（阿拉伯语等）
- 应用内"重启 App 应用语言变更"的强制流程（我们用环境注入避免了这个需求）
- 字体随语言切换（中文用一种字体、英文用另一种）—— 后续设计如有需要再讨论
