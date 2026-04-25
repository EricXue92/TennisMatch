# i18n Phase 6 — Login/Register + 移除 English

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把登录/注册流程全部纳入 繁↔简 切换，同时从 `LocaleManager` 和 Settings Picker 下线 English 选项（保留 xcstrings 中的 en 翻译数据作为休眠资产）。

**Architecture:** 沿用 Phase 1 模式 —— SwiftUI `Text("繁中字面量")` 自动本地化，非 SwiftUI 场景（toast、state 赋值、helper 参数）走 `L10n.string(_:)`。

**Tech Stack:** Swift 5.9+ / SwiftUI / iOS 17+ `@Observable` / Xcode 15+ String Catalog

**Spec:** `docs/superpowers/specs/2026-04-24-i18n-phase6-11-design.md`

**注意：项目无 XCTest target** —— 每个 task 的"验证"采用 **build + Xcode preview + Simulator 手动检查**，不写单元测试。

---

## 文件结构

**修改的文件：**
- `TennisMatch/Models/LocaleManager.swift` — 移除 `.en` case 和 switch 分支
- `TennisMatch/Views/SettingsView.swift` — 移除 Picker 中的 English 行
- `TennisMatch/Views/LoginView.swift` — 登录入口文案
- `TennisMatch/Views/PhoneInputView.swift` — 手机号输入
- `TennisMatch/Views/PhoneVerificationView.swift` — OTP 验证
- `TennisMatch/Views/EmailRegisterView.swift` — 邮箱注册（验证码+密码）
- `TennisMatch/Views/RegisterView.swift` — 个人资料设置（1330 行，最大）
- `TennisMatch/Views/HelpView.swift` — FAQ + 联系客服
- `TennisMatch/Localizable.xcstrings` — 自动由 Xcode 扫描追加新 key，手工填 zh-Hans 翻译

**不创建新文件。**

---

## Task 0: 预检查与 baseline build

**Files:** 无

- [ ] **Step 1: 确认在正确 branch**

Run: `git branch --show-current`
Expected: `feat/i18n-phase6-login-register`

如非，执行 `git checkout feat/i18n-phase6-login-register`（此 branch 已由 brainstorming 阶段创建并基于 main）。

- [ ] **Step 2: Baseline build**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -30`
Expected: `** BUILD SUCCEEDED **`

如果 baseline build 已经失败（非本 Phase 引起），暂停，先修 baseline 再继续。

- [ ] **Step 3: 确认无未提交改动**

Run: `git status`
Expected: 干净（无 unstaged / untracked）

如果有残留（如 Phase 5 branch stash），先处理掉再开始。

---

## Task 1: 从 LocaleManager 移除 `.en`

**Files:**
- Modify: `TennisMatch/Models/LocaleManager.swift`

- [ ] **Step 1: 编辑 `LocaleManager.swift`**

将 enum 从：

```swift
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHans
    case zhHant
    case en

    var id: String { rawValue }
}
```

改为：

```swift
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHans
    case zhHant

    var id: String { rawValue }
}
```

将 `currentLocale` 从：

```swift
var currentLocale: Locale {
    switch selectedLanguage {
    case .system: return .autoupdatingCurrent
    case .zhHans: return Locale(identifier: "zh-Hans")
    case .zhHant: return Locale(identifier: "zh-Hant")
    case .en:     return Locale(identifier: "en")
    }
}
```

改为：

```swift
var currentLocale: Locale {
    switch selectedLanguage {
    case .system: return .autoupdatingCurrent
    case .zhHans: return Locale(identifier: "zh-Hans")
    case .zhHant: return Locale(identifier: "zh-Hant")
    }
}
```

- [ ] **Step 2: 处理已存储为 `"en"` 的 UserDefaults 值**

`AppLanguage.init(rawValue:)` 对于旧值 `"en"` 会返回 `nil`，然后 fallback 到 `.system`。这是正确的迁移行为（老用户如果之前选的是 English，现在自动变成「跟隨系統」）。**无需额外代码**。

在 `LocaleManager.swift` 的 `private init()` 里确认此 fallback 逻辑仍在：

```swift
private init() {
    let raw = UserDefaults.standard.string(forKey: Self.storageKey) ?? AppLanguage.system.rawValue
    self.selectedLanguage = AppLanguage(rawValue: raw) ?? .system
}
```

这段不需要改，但要在 diff 审阅时确认没被误删。

- [ ] **Step 3: Build 验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -30`
Expected: `** BUILD SUCCEEDED **`

如果有编译错误指向 `SettingsView.swift` 的 `.en` 引用 —— 正常，Task 2 会修。本 step 用 `xcodebuild` 验证 `LocaleManager.swift` 自身语法 OK 即可；允许 SettingsView 暂时编译失败（不要 commit 失败状态）。

实际上：移除 enum case 会让 SettingsView 编译失败，无法单独验证 Task 1。**因此把 Task 1 和 Task 2 的 commit 合并为一个** —— 分 step 实施，最后一起 commit。

---

## Task 2: 从 SettingsView 移除 English Picker 行

**Files:**
- Modify: `TennisMatch/Views/SettingsView.swift`

- [ ] **Step 1: 编辑 Picker**

在 `SettingsView.swift` 的 `generalSection` 里，找到：

```swift
Picker(selection: $manager.selectedLanguage) {
    Text("跟隨系統").tag(LocaleManager.AppLanguage.system)
    Text("简体中文").tag(LocaleManager.AppLanguage.zhHans)
    Text("繁體中文").tag(LocaleManager.AppLanguage.zhHant)
    Text("English").tag(LocaleManager.AppLanguage.en)
} label: {
    Label("語言", systemImage: "globe")
        .font(Typography.fieldValue)
        .foregroundColor(Theme.textPrimary)
}
```

删除 `Text("English").tag(LocaleManager.AppLanguage.en)` 这一整行。改后：

```swift
Picker(selection: $manager.selectedLanguage) {
    Text("跟隨系統").tag(LocaleManager.AppLanguage.system)
    Text("简体中文").tag(LocaleManager.AppLanguage.zhHans)
    Text("繁體中文").tag(LocaleManager.AppLanguage.zhHant)
} label: {
    Label("語言", systemImage: "globe")
        .font(Typography.fieldValue)
        .foregroundColor(Theme.textPrimary)
}
```

- [ ] **Step 2: Build 验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build 2>&1 | tail -30`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Simulator 验证**

Run: Xcode ⌘R → 进入 App → 我的 Tab → 設定 → 通用 → 語言
Expected: Picker 弹出后只看到 3 项：跟隨系統 / 简体中文 / 繁體中文。

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Models/LocaleManager.swift TennisMatch/Views/SettingsView.swift
git commit -m "feat(i18n): remove English from language picker + LocaleManager enum

Per Phase 6 spec: soft-deprecate English. Removing .en case drops
the option from the Settings picker. Existing en translations in
xcstrings are retained for potential future re-enablement
(see Phase 11.5 checklist in spec)."
```

---

## Task 3: 本地化 LoginView.swift

**Files:**
- Modify: `TennisMatch/Views/LoginView.swift`

**背景：** LoginView 源码中混用了简繁字符（例如「登陆」「登录」），这是历史遗留。本 Phase 借机统一为**繁中源**（因为 xcstrings source = zh-Hant）。翻译到 zh-Hans 时再做繁→简转换。

### 3.1 统一源串为繁中 + 转 L10n

- [ ] **Step 1: 逐行修改 `LoginView.swift`**

定位到 `buttonsSection` 以下，应用以下替换（精确到字符）：

**第 149 行** `title: "手機號碼登陆",`（"登陆"简中）→
```swift
title: "手機號碼登入",
```

**第 159 行** `title: "微信登录",` → `title: "微信登入",`

**第 164 行** `action: { toastMessage = "微信登录即將支持" }` →
```swift
action: { toastMessage = L10n.string("微信登入即將支持") }
```

**第 168 行** `Button(action: { toastMessage = "Apple 登录即將支持" }) {` →
```swift
Button(action: { toastMessage = L10n.string("Apple 登入即將支持") }) {
```

**第 172 行** `Text("Apple 登录")` → `Text("Apple 登入")`

- [ ] **Step 2: 处理 `loginButton` helper 的 `title: String` 参数**

当前 helper 签名：
```swift
private func loginButton(
    title: String, icon: String,
    bg: Color, fg: Color, delay: Double,
    action: @escaping () -> Void = {}
) -> some View {
```

内部 `Text(title)` 用的是 `String` 而非 `LocalizedStringKey`，**不会自动本地化**。

修改签名与使用点：

```swift
private func loginButton(
    title: LocalizedStringKey, icon: String,
    bg: Color, fg: Color, delay: Double,
    action: @escaping () -> Void = {}
) -> some View {
    Button(action: action) {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(Typography.button)
            Text(title)  // 已经接受 LocalizedStringKey
                .font(Typography.button)
        }
        .foregroundColor(fg)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    .opacity(appeared ? 1 : 0)
    .offset(y: appeared ? 0 : 24)
    .animation(.easeOut(duration: 0.6).delay(delay), value: appeared)
}
```

调用点（Step 1 已经把字面量改对）无需再变 —— Swift 会把字符串字面量隐式转成 `LocalizedStringKey`。

- [ ] **Step 3: 其他 SwiftUI `Text(...)` 保持不变**

以下位置已经是 `Text("繁中字面量")`，无需改代码 —— Xcode 扫描后会自动注册到 xcstrings：

- 第 133: `Text("找 到 你 的 網 球 搭 檔")`
- 第 220: `Text("登入即表示您同意 ")`
- 第 223: `Text("服務條款")`
- 第 227: `Text(" 和 ")`
- 第 230: `Text("隱私政策")`
- 第 238: `Text("還沒有帳號？")`
- 第 241: `Text("立即註冊")`
- 第 249: `Text("需要幫助？")`
- 第 252: `Text("聯繫客服")`

第 129 `Text("Let's Tennis")` 是品牌名，需标记 `shouldTranslate: false`（Step 5 做）。

- [ ] **Step 4: Build + 让 Xcode 扫描新 key**

Run: Xcode ⌘B
Expected: BUILD SUCCEEDED

Build 过程中 Xcode 会把 `Text("手機號碼登入")` 等新 key 自动追加到 `Localizable.xcstrings`（state = new）。

- [ ] **Step 5: 在 Xcode 打开 `Localizable.xcstrings` 补 zh-Hans 翻译**

双击 `Localizable.xcstrings` 打开 String Catalog 编辑器。

**第一步 - 标记品牌名不翻译：**
- 搜索 `Let's Tennis`
- 右键 → Mark as Don't Translate（等价于设 `shouldTranslate: false`）

**第二步 - 填所有新 key 的 zh-Hans 翻译：**
按繁→简字符映射逐条填写（如果 Xcode 有 translation suggestion 可直接 accept）。以下是本 task 引入的新 key 清单及对应 zh-Hans：

| 繁中 key | zh-Hans 翻译 |
|---|---|
| `手機號碼登入` | `手机号码登入` |
| `微信登入` | `微信登入` |
| `微信登入即將支持` | `微信登入即将支持` |
| `Apple 登入` | `Apple 登入` |
| `Apple 登入即將支持` | `Apple 登入即将支持` |
| `找 到 你 的 網 球 搭 檔` | `找 到 你 的 网 球 搭 档` |
| `登入即表示您同意 ` | `登入即表示您同意 `（注意末尾空格保留） |
| `服務條款` | `服务条款` |
| ` 和 ` | ` 和 `（可能已存在） |
| `隱私政策` | `隐私政策` |
| `還沒有帳號？` | `还没有账号？` |
| `立即註冊` | `立即注册` |
| `需要幫助？` | `需要帮助？` |
| `聯繫客服` | `联系客服` |

填完后，每个 key 的 zh-Hans 列应显示为 "Translated" 状态。

- [ ] **Step 6: Build 验证**

Run: Xcode ⌘B
Expected: BUILD SUCCEEDED，没有关于 "missing translation" 的 warning

- [ ] **Step 7: Simulator 走查**

Run: Xcode ⌘R
- 确认 Login 页在当前语言下显示正常（默认繁中）
- 进入「我的」→ 設定 → 通用 → 語言 → 选 `简体中文`
- 返回 Login（需要先退出登录：測試账号 → 退出登錄）
- Expected: Login 页的按钮文字、footer 文案、品牌副标题「找 到 你 的 网 球 搭 档」全为简中；品牌主标题「Let's Tennis」不变
- 切回「繁體中文」再验证一遍

- [ ] **Step 8: Commit**

```bash
git add TennisMatch/Views/LoginView.swift TennisMatch/Localizable.xcstrings
git commit -m "feat(i18n): Phase 6 — LoginView localization

- Normalize source literals to zh-Hant (登陆→登入, 登录→登入)
- Change loginButton title param: String → LocalizedStringKey
- Route toast messages through L10n.string
- Mark 'Let's Tennis' as do-not-translate
- Add zh-Hans translations for Login surface strings"
```

---

## Task 4: 本地化 PhoneInputView.swift

**Files:**
- Modify: `TennisMatch/Views/PhoneInputView.swift`

- [ ] **Step 1: 扫描硬编码繁中字符串位置**

以下是需要本地化的所有位置（以文件中的行号为准；如果 Task 3 之后行号偏移，以字符串内容匹配）：

| 位置类型 | 内容 | 现有代码形式 |
|---|---|---|
| Title | `手機號碼登入` | `Text(...)` 自动本地化 |
| Subtitle | `請輸入您的手機號碼，我們將發送驗證碼` | `Text(...)` 自动本地化 |
| TextField placeholder | `請輸入手機號碼` | `TextField("...", text: $...)` 自动本地化 |
| Hint label（插值） | `請輸入 %@ 數字的手機號碼` | `Text("請輸入 \(lengthHint) 數字的手機號碼")` |
| Hint sub（插值） | 见 `lengthHint` computed property | `"\(n) 位"` 或 `"\(a)-\(b) 位"` → **需改** |
| Validation error（赋值给 String） | `請輸入手機號碼` | `errorMessage = "..."` → **需改** |
| Validation error（插值） | `手機號碼長度不正確，%@ 號碼應為 %@ 數字` | `errorMessage = "手機號碼長度不正確，\(countryCode) 號碼應為 \(lengthHint) 數字"` → **需改** |
| Button label | `獲取驗證碼` | `Text(...)` 自动本地化 |
| Nav principal | `手機登入` | `Text(...)` 自动本地化 |

- [ ] **Step 2: 修改 `lengthHint` computed property**

`lengthHint` 当前返回 `String`，被直接拼接进 `errorMessage`。因为它被赋值到 `@State String` 变量，必须用 `L10n.string`。

改前：
```swift
private var lengthHint: String {
    let lengths = expectedLengths
    if lengths.count == 1 {
        return "\(lengths[0]) 位"
    }
    return "\(lengths.min()!)-\(lengths.max()!) 位"
}
```

改后：
```swift
private var lengthHint: String {
    let lengths = expectedLengths
    if lengths.count == 1 {
        return L10n.string("\(lengths[0]) 位")
    }
    return L10n.string("\(lengths.min()!)-\(lengths.max()!) 位")
}
```

注意：`L10n.string("\(n) 位")` 和 `L10n.string("\(a)-\(b) 位")` 编译后对应 xcstrings 里 `"%lld 位"` 和 `"%lld-%lld 位"` 两个 key（Int 插值映射为 `%lld`）。

- [ ] **Step 3: 修改按钮 action 中的 `errorMessage` 赋值**

找到 Button action 里的两个 `errorMessage = "..."`：

改前：
```swift
if digits.isEmpty {
    errorMessage = "請輸入手機號碼"
    withAnimation { showError = true }
} else if !expectedLengths.contains(digits.count) {
    errorMessage = "手機號碼長度不正確，\(countryCode) 號碼應為 \(lengthHint) 數字"
    withAnimation { showError = true }
} else {
    // ...
}
```

改后：
```swift
if digits.isEmpty {
    errorMessage = L10n.string("請輸入手機號碼")
    withAnimation { showError = true }
} else if !expectedLengths.contains(digits.count) {
    errorMessage = L10n.string("手機號碼長度不正確，\(countryCode) 號碼應為 \(lengthHint) 數字")
    withAnimation { showError = true }
} else {
    // ...
}
```

- [ ] **Step 4: 其余 SwiftUI `Text(...)` / `TextField("...")` 保持原样**

这些位置会被 Xcode 自动扫描：
- `Text("手機號碼登入")`
- `Text("請輸入您的手機號碼，我們將發送驗證碼")`
- `TextField("請輸入手機號碼", text: $phoneNumber)`
- `Text("請輸入 \(lengthHint) 數字的手機號碼")` —— 插值的 `Text` 也会自动本地化，key 变成 `請輸入 %@ 數字的手機號碼`
- `Text("獲取驗證碼")`
- `Text("手機登入")`

- [ ] **Step 5: Build + 扫描新 key**

Run: Xcode ⌘B
Expected: BUILD SUCCEEDED

- [ ] **Step 6: 在 xcstrings 补 zh-Hans**

新 key 及其 zh-Hans：

| 繁中 key | zh-Hans 翻译 |
|---|---|
| `手機號碼登入` | `手机号码登入`（可能已在 Task 3 填过） |
| `請輸入您的手機號碼，我們將發送驗證碼` | `请输入您的手机号码，我们将发送验证码` |
| `請輸入手機號碼` | `请输入手机号码` |
| `請輸入 %@ 數字的手機號碼` | `请输入 %@ 数字的手机号码` |
| `%lld 位` | `%lld 位` |
| `%lld-%lld 位` | `%lld-%lld 位` |
| `手機號碼長度不正確，%@ 號碼應為 %@ 數字` | `手机号码长度不正确，%@ 号码应为 %@ 数字` |
| `獲取驗證碼` | `获取验证码` |
| `手機登入` | `手机登入` |

- [ ] **Step 7: Simulator 验证**

Run: Xcode ⌘R
- 切到简中，进入 Login → 手机号码登入
- Expected: 整页文案简中；故意清空手机号点「获取验证码」应 toast/显示简中 error；故意输入错位数应显示简中 error 并带占位符
- 切到繁中再走一遍，应全繁中

- [ ] **Step 8: Commit**

```bash
git add TennisMatch/Views/PhoneInputView.swift TennisMatch/Localizable.xcstrings
git commit -m "feat(i18n): Phase 6 — PhoneInputView localization

Route lengthHint and errorMessage through L10n.string for correct
locale resolution. Auto-scanned Text/TextField literals picked up
by Xcode; zh-Hans translations added to xcstrings."
```

---

## Task 5: 本地化 PhoneVerificationView.swift

**Files:**
- Modify: `TennisMatch/Views/PhoneVerificationView.swift`

- [ ] **Step 1: 扫描本地化目标**

Run: `grep -n '"[^"]*[\u4e00-\u9fff][^"]*"' TennisMatch/Views/PhoneVerificationView.swift` （如果 grep 不支持 Unicode 区间，用 Grep 工具或直接目视扫 `Text("` / `= "` / `"……"`）

识别所有含中文的字符串字面量：
- Nav title `Text("驗證碼")`
- 任何 `Text("...")` 包括说明文本、倒计时文案
- `toastMessage = "..."` 赋值（将 OTP 错误提示等路由到 `L10n.string`）

- [ ] **Step 2: 通用模式应用**

对每个找到的位置：
- 在 SwiftUI View body 中的 `Text("繁中")`、`Button("繁中")`、`navigationTitle("繁中")` 等 —— 无需改代码，Xcode 自动扫描
- 赋值给 `@State String` 变量（如 `toastMessage = "..."`）—— 改为 `L10n.string("...")`
- 带插值的 `toastMessage = "...\(var)..."` —— 改为 `L10n.string("...\(var)...")`

Read file: `TennisMatch/Views/PhoneVerificationView.swift`

对每个匹配项套用上述规则。示例（以文件中已知的 `toastMessage` 赋值为例，具体行号以读到时为准）：

```swift
// 改前
toastMessage = "驗證碼已重新發送"
// 改后
toastMessage = L10n.string("驗證碼已重新發送")
```

- [ ] **Step 3: Build + 扫描**

Run: Xcode ⌘B
Expected: BUILD SUCCEEDED

- [ ] **Step 4: 在 xcstrings 补 zh-Hans**

打开 `Localizable.xcstrings`，筛选 state = "New"，为每个新 key 填 zh-Hans 翻译。字符映射原则见 spec Section 5.1。

常见映射参考（本 View 可能会有）：
| 繁中 | zh-Hans |
|---|---|
| `驗證碼` | `验证码` |
| `已發送至 %@` | `已发送至 %@` |
| `重新發送` | `重新发送` |
| `%lld 秒後可重發` | `%lld 秒后可重发` |
| `驗證碼錯誤，請重新輸入` | `验证码错误，请重新输入` |
| `驗證中…` | `验证中…` |
| `驗證成功` | `验证成功` |
| `驗證碼已重新發送` | `验证码已重新发送` |

（实际新 key 以 Xcode 扫描结果为准，以上仅为示例。）

- [ ] **Step 5: Simulator 验证**

Run: Xcode ⌘R
- 切到简中，走一遍手机号 → 验证码流程
- Expected: 倒计时文案、重发按钮、错误提示全为简中
- 切繁中再走一遍

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/PhoneVerificationView.swift TennisMatch/Localizable.xcstrings
git commit -m "feat(i18n): Phase 6 — PhoneVerificationView localization"
```

---

## Task 6: 本地化 EmailRegisterView.swift

**Files:**
- Modify: `TennisMatch/Views/EmailRegisterView.swift`

- [ ] **Step 1: 识别需要本地化的字符串**

以下位置在 `EmailRegisterView.swift` 中已识别：

**SwiftUI Text / TextField / SecureField（自动本地化，无需改代码）：**
- `Text("郵箱註冊")` × 2（title + nav principal）
- `Text("使用郵箱地址建立帳號")`
- `Text("郵箱地址")`
- `TextField("請輸入郵箱", text: $email)`
- `Text("發送驗證碼")` / `Text("重新發送")`
- `Text("驗證碼")`
- `TextField("請輸入 6 位驗證碼", text: $verificationCode)`
- `Text("設定密碼")`
- `TextField("請輸入密碼（至少 6 位）", text: $password)` 和对应 `SecureField`
- `Text("確認密碼")`
- `TextField("請再次輸入密碼", text: $confirmPassword)` 和 `SecureField`
- `Text("註冊")`

**特殊 —— 倒计时按钮文案（Text 里的插值表达式）：**
```swift
Text(codeSent ? (canResend ? "重新發送" : "\(countdown)s") : "發送驗證碼")
```
这里 `"\(countdown)s"` 是纯数字+"s"，不需要本地化（繁简都一样）。`"重新發送"` 和 `"發送驗證碼"` 在 `Text(...)` 里会自动本地化。

**String 赋值（需要 L10n.string）：**
- `validationMessage = "請輸入有效的郵箱地址"`（`sendCode` 中）
- `validationMessage = "請輸入郵箱地址"`、`"請輸入有效的郵箱地址"`、`"請輸入 6 位驗證碼"`、`"密碼至少需要 6 位"`、`"兩次密碼不一致"`（`validate()` 中）

- [ ] **Step 2: 改 `sendCode()` 里的赋值**

改前：
```swift
private func sendCode() {
    guard isValidEmail(email) else {
        validationMessage = "請輸入有效的郵箱地址"
        withAnimation { showValidationError = true }
        return
    }
    // ...
}
```

改后：
```swift
private func sendCode() {
    guard isValidEmail(email) else {
        validationMessage = L10n.string("請輸入有效的郵箱地址")
        withAnimation { showValidationError = true }
        return
    }
    // ...
}
```

- [ ] **Step 3: 改 `validate()` 里的 5 处赋值**

改前：
```swift
private func validate() {
    if email.isEmpty {
        validationMessage = "請輸入郵箱地址"
    } else if !isValidEmail(email) {
        validationMessage = "請輸入有效的郵箱地址"
    } else if verificationCode.count != 6 {
        validationMessage = "請輸入 6 位驗證碼"
    } else if password.count < 6 {
        validationMessage = "密碼至少需要 6 位"
    } else if password != confirmPassword {
        validationMessage = "兩次密碼不一致"
    } else {
        showProfileSetup = true
        return
    }
    withAnimation { showValidationError = true }
}
```

改后：
```swift
private func validate() {
    if email.isEmpty {
        validationMessage = L10n.string("請輸入郵箱地址")
    } else if !isValidEmail(email) {
        validationMessage = L10n.string("請輸入有效的郵箱地址")
    } else if verificationCode.count != 6 {
        validationMessage = L10n.string("請輸入 6 位驗證碼")
    } else if password.count < 6 {
        validationMessage = L10n.string("密碼至少需要 6 位")
    } else if password != confirmPassword {
        validationMessage = L10n.string("兩次密碼不一致")
    } else {
        showProfileSetup = true
        return
    }
    withAnimation { showValidationError = true }
}
```

- [ ] **Step 4: Build + 扫描**

Run: Xcode ⌘B
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 在 xcstrings 补 zh-Hans**

新 key 及 zh-Hans 映射：

| 繁中 key | zh-Hans 翻译 |
|---|---|
| `郵箱註冊` | `邮箱注册` |
| `使用郵箱地址建立帳號` | `使用邮箱地址建立账号` |
| `郵箱地址` | `邮箱地址` |
| `請輸入郵箱` | `请输入邮箱` |
| `發送驗證碼` | `发送验证码` |
| `重新發送` | `重新发送`（可能已存在） |
| `驗證碼` | `验证码`（可能已存在） |
| `請輸入 6 位驗證碼` | `请输入 6 位验证码` |
| `設定密碼` | `设定密码` |
| `請輸入密碼（至少 6 位）` | `请输入密码（至少 6 位）` |
| `確認密碼` | `确认密码` |
| `請再次輸入密碼` | `请再次输入密码` |
| `註冊` | `注册` |
| `請輸入有效的郵箱地址` | `请输入有效的邮箱地址` |
| `請輸入郵箱地址` | `请输入邮箱地址` |
| `密碼至少需要 6 位` | `密码至少需要 6 位` |
| `兩次密碼不一致` | `两次密码不一致` |

- [ ] **Step 6: Simulator 验证**

Run: Xcode ⌘R → 切简中 → Login → 立即注册 → 邮箱注册
- 各字段占位符、label、按钮、验证错误消息全为简中
- 切繁中验证一遍

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/EmailRegisterView.swift TennisMatch/Localizable.xcstrings
git commit -m "feat(i18n): Phase 6 — EmailRegisterView localization

Route all validationMessage String assignments through L10n.string.
Text/TextField/SecureField literals auto-scanned by Xcode with
zh-Hans translations added to xcstrings."
```

---

## Task 7: 本地化 HelpView.swift（含 FAQ 数据）

**Files:**
- Modify: `TennisMatch/Views/HelpView.swift`

**难点：** FAQ 数组 `faqItems` 存的是 `String`（不是 `LocalizedStringKey`），当前在 `Text(item.question)` 时走 `Text(verbatim:)` 路径 —— **不会**自动本地化。

### 7.1 把 FAQItem 的字段改成 LocalizedStringKey

- [ ] **Step 1: 修改 `FAQItem` 结构体**

改前：
```swift
private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}
```

改后：
```swift
private struct FAQItem: Identifiable {
    let id = UUID()
    let question: LocalizedStringKey
    let answer: LocalizedStringKey
}
```

- [ ] **Step 2: 验证使用点**

在 `faqRow(_ item: FAQItem)` 里：
- `Text(item.question)` —— 现在接受 `LocalizedStringKey`，自动本地化 ✓
- `Text(item.answer)` —— 同理 ✓

无需改 view 代码。

- [ ] **Step 3: `faqItems` 字面量初始化保持不变**

Swift 会把 `FAQItem(question: "如何發布約球？", ...)` 里的字符串字面量隐式转为 `LocalizedStringKey`。**代码形式不变，行为变成本地化。**

### 7.2 其他 Text / Button

- [ ] **Step 4: 无需改动的 `Text(...)` 自动本地化**

- `Text("幫助")`（nav principal）
- `Text("找不到答案？")`
- `Text("聯繫客服")`

### 7.3 Build + 翻译

- [ ] **Step 5: Build + 扫描**

Run: Xcode ⌘B
Expected: BUILD SUCCEEDED

- [ ] **Step 6: 在 xcstrings 补 zh-Hans**

**FAQ 相关 key（问题 + 答案，较长文本，逐条填写）：**

| 繁中 key | zh-Hans 翻译 |
|---|---|
| `如何發布約球？` | `如何发布约球？` |
| `點擊底部 Tab 欄中間的「+」按鈕，填寫約球信息後點擊「發布約球」即可。` | `点击底部 Tab 栏中间的「+」按钮，填写约球信息后点击「发布约球」即可。` |
| `如何報名別人的約球？` | `如何报名别人的约球？` |
| `在首頁瀏覽約球列表，點擊感興趣的約球卡片進入詳情頁，點擊「報名」按鈕確認即可。` | `在首页浏览约球列表，点击感兴趣的约球卡片进入详情页，点击「报名」按钮确认即可。` |
| `什麼是 NTRP？` | `什么是 NTRP？` |
| `NTRP（National Tennis Rating Program）是國際通用的網球技術分級標準，從 1.0（初學者）到 7.0（世界級），幫助你找到水平匹配的對手。` | `NTRP（National Tennis Rating Program）是国际通用的网球技术分级标准，从 1.0（初学者）到 7.0（世界级），帮助你找到水平匹配的对手。` |
| `如何取消已報名的約球？` | `如何取消已报名的约球？` |
| `進入「我的約球」頁面，找到你要取消的約球，點擊「取消」按鈕確認即可。取消後會通知所有參與者。` | `进入「我的约球」页面，找到你要取消的约球，点击「取消」按钮确认即可。取消后会通知所有参与者。` |
| `如何創建賽事？` | `如何创建赛事？` |
| `從側邊欄進入「賽事」頁面，點擊右上角「+ 建立賽事」按鈕，填寫賽事信息後發布。` | `从侧边栏进入「赛事」页面，点击右上角「+ 建立赛事」按钮，填写赛事信息后发布。` |
| `如何封鎖其他用戶？` | `如何封锁其他用户？` |
| `進入對方的個人主頁，點擊「封鎖」按鈕即可。被封鎖的用戶無法查看你的資料和約球，也無法向你發送私信。` | `进入对方的个人主页，点击「封锁」按钮即可。被封锁的用户无法查看你的资料和约球，也无法向你发送私信。` |
| `幫助` | `帮助` |
| `找不到答案？` | `找不到答案？` |
| `聯繫客服` | `联系客服`（可能已存在） |

- [ ] **Step 7: Simulator 验证**

Run: Xcode ⌘R → 切简中 → Login footer 点「需要帮助？联系客服」→ 进入 HelpView
- 所有 6 条 FAQ 问题+答案均为简中（点击展开验证 answer）
- 底部「找不到答案？」「联系客服」按钮简中

- [ ] **Step 8: Commit**

```bash
git add TennisMatch/Views/HelpView.swift TennisMatch/Localizable.xcstrings
git commit -m "feat(i18n): Phase 6 — HelpView + FAQ localization

Change FAQItem.question/answer from String to LocalizedStringKey
so that Text(item.question) auto-localizes via env locale.
Added zh-Hans translations for all 6 FAQ entries."
```

---

## Task 8: 本地化 RegisterView.swift（大文件，分 3 pass）

**Files:**
- Modify: `TennisMatch/Views/RegisterView.swift` (1330 行)

RegisterView 是最大的 View，分 3 个 pass 处理 + 1 个 commit。

### Pass A —— 扫描并记录所有需要本地化的字符串

- [ ] **Step 1: 生成字符串清单**

Run (在 repo 根目录):
```bash
grep -n '"[^"]*[\u4e00-\u9fff][^"]*"' TennisMatch/Views/RegisterView.swift > /tmp/register_i18n_targets.txt
wc -l /tmp/register_i18n_targets.txt
```

（如果 grep 不支持 Unicode 区间，改用 Grep tool: `pattern: "\"[^\"]*[一-龥][^\"]*\""`, `path: TennisMatch/Views/RegisterView.swift`, `output_mode: content`）

Expected: 通常 ~60–100 条（包括每个 form field label、placeholder、validation message、section header、按钮文字等）。

- [ ] **Step 2: 分类**

对清单中每行，用下列分类打标签（可用注释形式记在 txt 中）：

| 分类 | 判定依据 | 处理方式 |
|---|---|---|
| SwiftUI Text/Label/Button literal | 在 `Text("...")`, `Label("...", systemImage: ...)`, `Button("...")`, `.navigationTitle("...")` 等位置 | 无需改代码 |
| TextField / SecureField placeholder | `TextField("...", text: ...)` | 无需改代码（第一个参数接受 `LocalizedStringKey`） |
| Helper func 接受 `String` 参数 | 例如 `fieldLabel(title: String, ...)` 且内部 `Text(title)` | **改签名为 `LocalizedStringKey`** |
| `String` 赋值（state、toast、validation） | `validationMessage = "..."`、`toastMessage = "..."` | **改为 `L10n.string("...")`** |
| 插值 String 赋值 | `"... \(var) ..."` 赋给 String 变量 | **改为 `L10n.string("... \(var) ...")`** |
| 枚举 raw value / model 层 String | 例如 `Gender.male.label == "男"` | 需要 case-by-case 决定 —— 见下文 |

- [ ] **Step 3: 特别识别 —— 枚举 label**

`RegisterView` 使用了 `Gender`, `AgeRange`, `MatchType`, `TennisCourt`, `TimeSlot`, `WeeklySlot` 等模型。它们的 `label` / `displayName` 属性如果返回繁中字符串且被 View 里直接 `Text(someModel.label)` 展示 —— 就**不会**自动本地化。

Run: 
```bash
grep -rn 'var label' TennisMatch/Models/ | grep -E '"[一-龥]' 
```
或对 `Gender`, `AgeRange` 等具体 model 文件读取。

如果发现 model 层有 `var label: String { "男" }` 这种代码：
- **本 Phase 处理原则**：model 层字符串是 Phase 10 的范畴。如果只是 `Text(model.label)` 用法，先用**临时 workaround**：把 View 里 `Text(model.label)` 改成 `Text(LocalizedStringKey(model.label))`，这样 `"男"` 作为 key 触发 xcstrings 注册 + 翻译查找。
- Phase 10 再统一用 `LocalizedStringResource` 重构 model。

### Pass B —— 修改代码

- [ ] **Step 4: 应用 Pass A 清单中的代码改动**

系统地从文件顶到底过一遍，对每条清单项应用 step 2 分类的处理方式。注意事项：

1. **Helper function 签名改动**：如果 RegisterView 内有 `private func someRow(title: String, ...)` 且传入的 title 是中文字面量，把 `title: String` 改成 `title: LocalizedStringKey`，调用点无需改。
2. **`validationMessage` / toast 类**：全文 search `validationMessage = "`、`toastMessage = "`、`errorMessage = "`，把值包进 `L10n.string(...)`
3. **`Text(LocalizedStringKey(...))` 桥接**：对 model.label 等 String 属性用法，临时桥接。示例：
   ```swift
   // 改前
   Text(gender.label)
   // 改后（临时）
   Text(LocalizedStringKey(gender.label))
   ```

- [ ] **Step 5: Build**

Run: Xcode ⌘B
Expected: BUILD SUCCEEDED

如果 build 失败，常见原因：
- `loginButton` 类 helper 的 title 参数仍是 `String` —— 检查类型冲突
- `L10n.string("...\(var)...")` 的插值变量类型需要是 `String` / `Int` / `Double` 之一，不接受自定义类型的 `description`

### Pass C —— 补翻译 + 验证

- [ ] **Step 6: 在 xcstrings 补 zh-Hans 翻译**

打开 `Localizable.xcstrings` → 筛选 state = "New"（左上角过滤器）→ 逐条填 zh-Hans。

**提示**：RegisterView 的 key 可能数量很多（80+）。做法：
- 逐行填繁→简字符映射
- 参考 spec Section 5.1 的映射表
- Xcode String Catalog 提供 auto-suggest（会用已有翻译的词汇作为提示）

**重要字段对照参考**（覆盖 RegisterView 的高频字段，按命中率估算）：

| 繁中 | zh-Hans |
|---|---|
| `設定個人資料` | `设定个人资料` |
| `基本資料（必填）` | `基本资料（必填）` |
| `更多資料（選填）` | `更多资料（选填）` |
| `姓名` | `姓名` |
| `性別` | `性别` |
| `男` | `男` |
| `女` | `女` |
| `其他` | `其他` |
| `年齡段` | `年龄段` |
| `NTRP 水平` | `NTRP 水平` |
| `個人簡介` | `个人简介` |
| `打球類型` | `打球类型` |
| `常用球場` | `常用球场` |
| `空閒時段` | `空闲时段` |
| `請輸入姓名` | `请输入姓名` |
| `請選擇性別` | `请选择性别` |
| `請選擇年齡段` | `请选择年龄段` |
| `請選擇 NTRP 分數` | `请选择 NTRP 分数` |
| `完成` | `完成`（已存在） |
| `建立帳號` | `建立账号` |
| `建議` | `建议` |
| `單打` | `单打` |
| `雙打` | `双打` |
| `拉球` | `拉球` |

（具体清单以 Xcode 扫描到的 state=New 为准。）

- [ ] **Step 7: Build 再次验证**

Run: Xcode ⌘B
Expected: BUILD SUCCEEDED

- [ ] **Step 8: Simulator 走查**

Run: Xcode ⌘R
- 切到简中，完整走一遍注册流程：邮箱注册 → 点「注册」进入设置个人资料页
- Expected: 所有字段 label、placeholder、section header、必填/选填提示、性别/年龄段/NTRP picker 选项、验证错误消息、提交按钮全为简中
- 故意留空必填字段提交，检查错误提示简中
- 切繁中再走一遍

- [ ] **Step 9: Commit**

```bash
git add TennisMatch/Views/RegisterView.swift TennisMatch/Localizable.xcstrings
git commit -m "feat(i18n): Phase 6 — RegisterView localization

- Switch helper function String params to LocalizedStringKey
- Route validationMessage / toast assignments through L10n.string
- Bridge model.label String values via Text(LocalizedStringKey(...))
  as a temporary until Phase 10 refactors models to LocalizedStringResource
- Add zh-Hans translations for profile-setup surface strings"
```

---

## Task 9: 验收走查（端到端 Simulator 测试）

**Files:** 无（手动 simulator 验证）

- [ ] **Step 1: 冷启动，系统 locale = en-US**

在 Simulator: Settings → General → Language & Region → iPhone Language → English。
Kill & 重启 App。

Expected: App 显示繁体中文（source fallback），无崩溃。

- [ ] **Step 2: 冷启动，系统 locale = zh-Hans**

Simulator 系统语言切到 `简体中文`。Kill & 重启 App。

Expected: Login 页 + 整个注册流程全为简中。

- [ ] **Step 3: 冷启动，系统 locale = zh-Hant**

Simulator 系统语言切到 `繁體中文`。Kill & 重启 App。

Expected: Login 页 + 整个注册流程全为繁中。

- [ ] **Step 4: 热切换（App 内切语言）**

已登录状态 → 我的 → 設定 → 通用 → 語言 → 切 `简体中文`
Expected: Settings 页立即变简中；返回其他 Tab 也都简中

切 `繁體中文` → 立即变繁中。

- [ ] **Step 5: Picker 仅 3 项**

设定 → 语言 → 确认 Picker 只有：跟隨系統 / 简体中文 / 繁體中文（**无 English**）

- [ ] **Step 6: 旧 UserDefaults 值迁移**

如果之前在测试中把语言选为 English（`UserDefaults` 存 `"en"`）：

Run (在 terminal):
```bash
xcrun simctl spawn booted defaults write com.lets.tennis appLanguage en
# 或用 Xcode 的 console 写入
```

然后重启 App。
Expected: App 读到 `"en"` 找不到匹配 enum case → fallback 到 `.system`，不崩溃。

（此 step 是回归测试；如无法方便注入 UserDefaults，可跳过但记一条 note。）

- [ ] **Step 7: 未本地化页面不崩溃**

切到简中 → 进入 CreateMatchView / TournamentView 等 Phase 7+ 尚未本地化的页面。
Expected: 页面以繁中显示（source fallback），不出现空白、key 名、??? 占位或崩溃。

- [ ] **Step 8: Clean build 无 warning**

Run: Xcode Product → Clean Build Folder → Build
Expected: BUILD SUCCEEDED，无关于 missing translation 的 warning（zh-Hant 列有 "New" state 的 key 也 OK，那是 source，不算 missing）。

- [ ] **Step 9: 如发现遗漏，补 commit**

如果 Step 1–8 有发现遗漏（某处字符串没翻译、或 toast 没走 L10n），修复后：
```bash
git add <fixed files> TennisMatch/Localizable.xcstrings
git commit -m "fix(i18n): Phase 6 — <describe what was missed>"
```
否则跳过。

---

## Task 10: Push + PR

- [ ] **Step 1: Push branch**

Run: `git push -u origin feat/i18n-phase6-login-register`
Expected: branch 推送成功

- [ ] **Step 2: 建 PR**

Run:
```bash
gh pr create --title "feat(i18n): Phase 6 — Login/Register localization + drop English" --body "$(cat <<'EOF'
## Summary

- Drop English from language picker + `LocaleManager.AppLanguage` (soft deprecation — en translations retained in xcstrings as dormant data per Phase 11.5 checklist)
- Localize Login flow: LoginView, PhoneInputView, PhoneVerificationView, EmailRegisterView, RegisterView, HelpView
- Normalize source literals to consistent zh-Hant (fix mixed 登陆/登录/登入 in LoginView)
- Route validation / toast String assignments through `L10n.string`
- Change helper `String` params to `LocalizedStringKey` where appropriate
- Bridge model.label values via `Text(LocalizedStringKey(...))` (temporary until Phase 10)

Spec: `docs/superpowers/specs/2026-04-24-i18n-phase6-11-design.md`

## Test plan

- [ ] Cold start with system locale = zh-Hans → simp Chinese UI through entire login/register flow
- [ ] Cold start with system locale = zh-Hant → trad Chinese UI
- [ ] Cold start with system locale = en-US → fallback to trad Chinese source
- [ ] In-app hot switch from 繁 to 简 immediately re-renders Settings
- [ ] Language picker shows exactly 3 options (no English)
- [ ] Legacy `UserDefaults` value `"en"` falls back to `.system` without crash
- [ ] Unlocalized views (CreateMatch, Tournament) still render as 繁 without crashes

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

Expected: PR URL 打印出来

- [ ] **Step 3: 返回 PR URL 给用户**

---

## 完成定义（Definition of Done）

Phase 6 完工时应满足：

1. 所有 10 个 task 的所有 step 已勾选完成
2. Spec Section 4.Phase 6 所有范围项已实现
3. 所有改动已 commit 并 push
4. PR 已创建，URL 已提供给用户
5. Simulator 冷启动 + 热切换端到端走查通过（Task 9）
6. Build 无 error / i18n warning
7. Settings 语言 Picker 只剩 3 项

## 下一步

Phase 6 merge 后，切到 main 并 pull。然后：
1. 基于 main 建 `feat/i18n-phase7-creatematch-matchassistant-matchdetail` branch
2. 调用 `superpowers:writing-plans` skill，基于 spec Section 4.Phase 7 生成 Phase 7 plan
