# App 多语言切换 — Phase 1 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在设置页加入"语言"行，支持系统/简中/繁中/英文切换，并完成 SettingsView 与 Tab Bar 的字符串本地化（infrastructure + Phase 1 翻译范围）。

**Status:** ✅ Phase 1 complete (2026-04-24)

**Architecture:** SwiftUI `.environment(\.locale, …)` 注入 + `Localizable.xcstrings`（source = zh-Hant，target = zh-Hans/en）+ `@Observable LocaleManager` 管理偏好；动态字符串通过 `L10n.string(_:)` 辅助方法显式传 locale。

**Tech Stack:** Swift 5.9+ / SwiftUI / iOS 17+ `@Observable` / Xcode 15+ String Catalog

**Spec：** `docs/superpowers/specs/2026-04-24-app-localization-design.md`

**注意 — 本项目无单元测试 target**，每个任务的"验证"采用 **build + 手动 preview/simulator 检查**，不写 XCTest。

---

## 文件结构

**新建：**
- `TennisMatch/Models/LocaleManager.swift` — 语言偏好 `@Observable` 管理器
- `TennisMatch/Models/L10n.swift` — 非 SwiftUI 场景下显式传 locale 的辅助函数
- `TennisMatch/Localizable.xcstrings` — String Catalog（source = zh-Hant；含 zh-Hans/en 翻译）

**修改：**
- `TennisMatch/TennisMatchApp.swift` — 注入 `LocaleManager` 到环境、注入 `\.locale`
- `TennisMatch/Views/SettingsView.swift` — 新增"通用 / 语言"section，迁移动态字符串到 `L10n`
- `TennisMatch.xcodeproj/project.pbxproj` — `developmentRegion` 改为 `zh-Hant`、`knownRegions` 添加 `zh-Hans`、`zh-Hant`

**不改代码、仅靠 xcstrings 自动本地化：**
- `TennisMatch/Views/Home/CustomTabBar.swift` — 已使用 `Text("首頁")` 等 `LocalizedStringKey`，xcstrings 中注册对应翻译即可

---

## Task 1: 创建 `LocaleManager`

**Files:**
- Create: `TennisMatch/Models/LocaleManager.swift`

- [ ] **Step 1: 创建文件**

写入 `TennisMatch/Models/LocaleManager.swift`：

```swift
//
//  LocaleManager.swift
//  TennisMatch
//
//  全域語言偏好管理 — @Observable，持久化於 UserDefaults
//

import Foundation
import SwiftUI

@Observable
final class LocaleManager {
    static let shared = LocaleManager()

    enum AppLanguage: String, CaseIterable, Identifiable {
        case system
        case zhHans
        case zhHant
        case en

        var id: String { rawValue }
    }

    /// 用戶選擇的語言偏好（持久化）
    var selectedLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: Self.storageKey)
        }
    }

    /// 當前生效的 Locale —— 注入到 SwiftUI \.locale 環境
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

- [ ] **Step 2: 把文件加入 Xcode target**

在 Xcode 中：右键 `Models` 群组 → Add Files to "TennisMatch"… → 选 `LocaleManager.swift` → 勾选 target "TennisMatch" → Add。

（或：拖动 Finder 中的文件到 Xcode `Models` 群组下，弹窗中勾选 target。）

- [ ] **Step 3: Build 验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 15' build` （或 Xcode 中 ⌘B）
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Models/LocaleManager.swift TennisMatch.xcodeproj/project.pbxproj
git commit -m "feat(i18n): add LocaleManager for app language preference"
```

---

## Task 2: 配置项目 localizations（pbxproj）

**Files:**
- Modify: `TennisMatch.xcodeproj/project.pbxproj` — `developmentRegion` 与 `knownRegions`

**说明：** Xcode 把"项目支持的语言"存在 `project.pbxproj` 里。最稳的做法是**在 Xcode 里点 UI 改**（避免直接编辑 .pbxproj 出错）。

- [ ] **Step 1: 在 Xcode 改 Development Language**

打开 Xcode → 点 project root（顶层蓝色图标）→ Project（不是 Target）→ Info tab → "Localization Native Development Region" → 选 `Chinese, Traditional (zh-Hant)`。

（如果下拉里没有，先做 Step 2 再回来。）

- [ ] **Step 2: 在 Xcode 添加 Localizations**

同 Project → Info tab → "Localizations" 区块 → 点 `+` →
- 选 `Chinese, Simplified (zh-Hans)` → Finish（暂时无文件需要本地化，直接 OK）
- 再点 `+` → 选 `English (en)` → Finish

- [ ] **Step 3: 验证 pbxproj 已更新**

Run: `grep -A 5 "knownRegions" TennisMatch.xcodeproj/project.pbxproj`
Expected 输出包含：
```
knownRegions = (
    en,
    Base,
    "zh-Hans",
    "zh-Hant",
);
```
且
```
developmentRegion = "zh-Hant";
```

- [ ] **Step 4: Build 验证**

Run: ⌘B in Xcode（或 `xcodebuild ... build`）
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add TennisMatch.xcodeproj/project.pbxproj
git commit -m "build(i18n): add zh-Hans + zh-Hant + en localizations to project"
```

---

## Task 3: 创建 `Localizable.xcstrings`（含完整 SettingsView + TabBar 翻译）

**Files:**
- Create: `TennisMatch/Localizable.xcstrings`

**说明：** String Catalog 是 JSON 文件。直接写入完整的 source + zh-Hans + en 翻译，免去后续在 Xcode UI 里逐个填的工作量。Xcode build 时会校验格式并把代码里新出现的 `Text("…")` key 自动追加进来。

- [ ] **Step 1: 创建文件**

写入 `TennisMatch/Localizable.xcstrings`（完整内容）：

```json
{
  "sourceLanguage" : "zh-Hant",
  "version" : "1.0",
  "strings" : {
    "Apple" : {
      "shouldTranslate" : false
    },
    "English" : {
      "shouldTranslate" : false
    },
    "Google" : {
      "shouldTranslate" : false
    },
    "v0.1.0" : {
      "shouldTranslate" : false
    },
    "微信、Apple" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "WeChat, Apple" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "微信、Apple" } }
      }
    },
    "微信" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "WeChat" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "微信" } }
      }
    },
    "設定" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Settings" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "设置" } }
      }
    },
    "退出登錄" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Log Out" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "退出登录" } }
      }
    },
    "取消" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Cancel" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "取消" } }
      }
    },
    "確認退出" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Log Out" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "确认退出" } }
      }
    },
    "確定要退出登錄嗎？" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Are you sure you want to log out?" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "确定要退出登录吗？" } }
      }
    },
    "帳號與安全" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Account & Security" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "账号与安全" } }
      }
    },
    "通知偏好" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Notifications" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "通知偏好" } }
      }
    },
    "隱私設置" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Privacy" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "隐私设置" } }
      }
    },
    "關於我們" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "About" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "关于我们" } }
      }
    },
    "通用" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "General" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "通用" } }
      }
    },
    "手機號碼" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Phone Number" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "手机号码" } }
      }
    },
    "未綁定" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Not linked" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "未绑定" } }
      }
    },
    "修改密碼" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Change Password" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "修改密码" } }
      }
    },
    "關聯帳號" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Linked Accounts" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "关联账号" } }
      }
    },
    "約球提醒" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Match Reminders" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "约球提醒" } }
      }
    },
    "聊天消息" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Chat Messages" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "聊天消息" } }
      }
    },
    "賽事更新" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Tournament Updates" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "赛事更新" } }
      }
    },
    "誰能看到我的資料" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Who can see my profile" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "谁能看到我的资料" } }
      }
    },
    "誰能私信我" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Who can message me" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "谁能私信我" } }
      }
    },
    "所有人" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Everyone" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "所有人" } }
      }
    },
    "僅關注者" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Followers only" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "仅关注者" } }
      }
    },
    "僅自己" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Only me" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "仅自己" } }
      }
    },
    "關閉" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Off" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "关闭" } }
      }
    },
    "版本" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Version" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "版本" } }
      }
    },
    "用戶協議" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Terms of Service" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "用户协议" } }
      }
    },
    "隱私政策" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Privacy Policy" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "隐私政策" } }
      }
    },
    "語言" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Language" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "语言" } }
      }
    },
    "跟隨系統" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "System" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "跟随系统" } }
      }
    },
    "简体中文" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Simplified Chinese" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "简体中文" } }
      }
    },
    "繁體中文" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Traditional Chinese" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "繁体中文" } }
      }
    },
    "請輸入當前密碼並設定新密碼" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Enter your current password and set a new one" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "请输入当前密码并设置新密码" } }
      }
    },
    "當前密碼" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Current Password" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "当前密码" } }
      }
    },
    "新密碼（至少 6 位）" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "New Password (min 6 characters)" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "新密码（至少 6 位）" } }
      }
    },
    "確認新密碼" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Confirm New Password" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "确认新密码" } }
      }
    },
    "兩次輸入的密碼不一致" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Passwords don't match" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "两次输入的密码不一致" } }
      }
    },
    "請輸入目前的密碼" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Please enter your current password" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "请输入当前密码" } }
      }
    },
    "新密碼至少需要 6 位" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "New password must be at least 6 characters" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "新密码至少需要 6 位" } }
      }
    },
    "兩次新密碼不一致" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "New passwords don't match" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "两次新密码不一致" } }
      }
    },
    "密碼修改成功" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Password changed successfully" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "密码修改成功" } }
      }
    },
    "確認修改" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Confirm" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "确认修改" } }
      }
    },
    "管理第三方登錄方式" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Manage third-party sign-in methods" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "管理第三方登录方式" } }
      }
    },
    "已關聯" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Linked" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "已关联" } }
      }
    },
    "關聯" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Link" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "关联" } }
      }
    },
    "至少需要保留一種登錄方式" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "You must keep at least one sign-in method" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "至少需要保留一种登录方式" } }
      }
    },
    "已關聯 %@" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Linked %@" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "已关联 %@" } }
      }
    },
    "已取消關聯 %@" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Unlinked %@" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "已取消关联 %@" } }
      }
    },
    "完成" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Done" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "完成" } }
      }
    },
    "首頁" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Home" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "首页" } }
      }
    },
    "我的約球" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "My Matches" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "我的约球" } }
      }
    },
    "一鍵約球" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Quick Match" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "一键约球" } }
      }
    },
    "聊天" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Chat" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "聊天" } }
      }
    },
    "我的" : {
      "localizations" : {
        "en" : { "stringUnit" : { "state" : "translated", "value" : "Profile" } },
        "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "我的" } }
      }
    }
  }
}
```

- [ ] **Step 2: 把文件加入 Xcode target**

在 Xcode：右键 `TennisMatch` 群组（顶层 source 目录）→ Add Files to "TennisMatch"… → 选 `Localizable.xcstrings` → 勾选 target "TennisMatch" → Add。

- [ ] **Step 3: Build 验证**

Run: ⌘B in Xcode（或 `xcodebuild ... build`）
Expected: BUILD SUCCEEDED。Build log 中可见 `compile xcstrings`。

如果有 warning 提示某个 key 在代码里"missing"或 unused，先忽略 —— 后续 Task 5/6 会消化。

- [ ] **Step 4: 在 Xcode 打开 xcstrings 目视检查**

双击 `Localizable.xcstrings` 在 Xcode 编辑器中打开。检查左侧语言列表显示 `Chinese (Traditional)` / `Chinese (Simplified)` / `English`，且每个 key 在 zh-Hans 和 en 列都已"translated"（绿色对勾）。

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Localizable.xcstrings TennisMatch.xcodeproj/project.pbxproj
git commit -m "feat(i18n): add Localizable.xcstrings with zh-Hant source + zh-Hans/en translations"
```

---

## Task 4: 在 App 根节点注入 LocaleManager 与 \.locale

**Files:**
- Modify: `TennisMatch/TennisMatchApp.swift`

- [ ] **Step 1: 修改 `TennisMatchApp.swift`**

完整替换文件内容为：

```swift
//
//  TennisMatchApp.swift
//  TennisMatch
//
//  Created by XUE on 18/4/2026.
//

import SwiftUI

@main
struct TennisMatchApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var localeManager = LocaleManager.shared
    @State private var followStore = FollowStore()
    @State private var userStore = UserStore()
    @State private var bookedSlotStore = BookedSlotStore()
    @State private var notificationStore = NotificationStore()
    @State private var creditScoreStore = CreditScoreStore()
    @State private var ratingFeedbackStore = RatingFeedbackStore()
    @State private var tournamentStore = TournamentStore()

    var body: some Scene {
        WindowGroup {
            Group {
                if isLoggedIn {
                    NavigationStack {
                        HomeView()
                        //LoginView()
                    }
                } else {
                    NavigationStack {
                        LoginView()
                    }
                }
            }
            .preferredColorScheme(.light)
            .environment(\.locale, localeManager.currentLocale)
            .environment(localeManager)
            .environment(followStore)
            .environment(userStore)
            .environment(bookedSlotStore)
            .environment(notificationStore)
            .environment(creditScoreStore)
            .environment(ratingFeedbackStore)
            .environment(tournamentStore)
        }
    }
}
```

变更说明：
- 新增 `@State private var localeManager = LocaleManager.shared`
- 新增 `.environment(\.locale, localeManager.currentLocale)`（必须在其他 environment 调用之前或之后均可，但**放在 `.preferredColorScheme` 之后、其他 store environment 之前**便于阅读）
- 新增 `.environment(localeManager)` —— 让子 View 能拿到 `@Environment(LocaleManager.self)` 修改语言

- [ ] **Step 2: Build 验证**

Run: ⌘B in Xcode
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add TennisMatch/TennisMatchApp.swift
git commit -m "feat(i18n): inject LocaleManager + locale into root environment"
```

---

## Task 5: 创建 `L10n` 辅助函数

**Files:**
- Create: `TennisMatch/Models/L10n.swift`

**说明：** SwiftUI 的 `Text("…")` 会自动用 env locale 查 String Catalog。但**非 SwiftUI 的字符串赋值**（toast message、alert message 等）需要显式传 locale，否则会用系统默认 locale 而忽略用户偏好。

- [ ] **Step 1: 创建文件**

写入 `TennisMatch/Models/L10n.swift`：

```swift
//
//  L10n.swift
//  TennisMatch
//
//  非 SwiftUI 場景下的本地化字串輔助 —— 顯式傳入當前 LocaleManager 的 locale。
//
//  使用示例：
//      toastMessage = L10n.string("已關聯 \(title)")
//

import Foundation

enum L10n {
    /// 用當前 App 語言（LocaleManager.shared.currentLocale）解析 LocalizationValue
    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: LocaleManager.shared.currentLocale)
    }
}
```

- [ ] **Step 2: 把文件加入 Xcode target**

在 Xcode：右键 `Models` 群组 → Add Files to "TennisMatch"… → 选 `L10n.swift` → 勾选 target → Add。

- [ ] **Step 3: Build 验证**

Run: ⌘B in Xcode
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Models/L10n.swift TennisMatch.xcodeproj/project.pbxproj
git commit -m "feat(i18n): add L10n helper for non-SwiftUI dynamic strings"
```

---

## Task 6: 在 SettingsView 加"通用 / 语言" section

**Files:**
- Modify: `TennisMatch/Views/SettingsView.swift`

- [ ] **Step 1: 在 SettingsView 顶部添加 LocaleManager 环境引用**

在 `SettingsView` struct 的属性区域，紧跟 `@Environment(\.dismiss) private var dismiss` 之后插入：

```swift
@Environment(LocaleManager.self) private var localeManager
```

- [ ] **Step 2: 在 List 中添加 generalSection（位于 aboutSection 之前）**

将 `body` 中的：

```swift
List {
    accountSection
    notificationSection
    privacySection
    aboutSection
    logoutSection
}
```

改为：

```swift
List {
    accountSection
    notificationSection
    privacySection
    generalSection
    aboutSection
    logoutSection
}
```

- [ ] **Step 3: 在 `// MARK: - Sections` 区块内、`aboutSection` 之前，新增 `generalSection`**

```swift
private var generalSection: some View {
    @Bindable var manager = localeManager
    return Section {
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
    } header: {
        Text("通用")
    }
}
```

**关键点**：
- 因为 `LocaleManager` 是 `@Observable`，需要用 `@Bindable` 在局部生成 `Binding`
- Picker 选项用 `Text("…")` 直接传中文 key（已经在 xcstrings 中注册）
- "English" 在 xcstrings 中标记 `shouldTranslate: false`，三种语言下都显示 "English"

- [ ] **Step 4: 更新 Preview 注入 `LocaleManager`**

文件底部的 `#Preview` 块：

```swift
#Preview("iPhone SE") {
    NavigationStack {
        SettingsView()
    }
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        SettingsView()
    }
}
```

替换为：

```swift
#Preview("iPhone SE") {
    NavigationStack {
        SettingsView()
    }
    .environment(LocaleManager.shared)
}

#Preview("iPhone 15 Pro") {
    NavigationStack {
        SettingsView()
    }
    .environment(LocaleManager.shared)
}
```

- [ ] **Step 5: Build 验证**

Run: ⌘B in Xcode
Expected: BUILD SUCCEEDED

- [ ] **Step 6: Preview 验证**

在 Xcode 打开 SettingsView.swift，等 preview 加载。Expected：能看到新 section "通用"，里面有"語言"行，点击展开有 4 个选项。切换到"English"后，preview 中**整个 Settings 页**（设定标题、所有 section header、所有 row 文字、退出登錄按钮）切换为英文。切到"简体中文"切换为简中。

如果 preview 中切换无效（仍显示繁中），是因为 SwiftUI Picker 写回 `@Bindable` 触发了变更，但环境还停留在 preview 启动时的 locale。这种情况下：
- 跑模拟器（⌘R）做更可靠的验证 —— 环境会随 `LocaleManager.shared.selectedLanguage` 真正变化
- 如果模拟器切换也无效，去 TennisMatchApp.swift 检查 `.environment(\.locale, localeManager.currentLocale)` 是否在 `if isLoggedIn` 的 `Group` 之外（应该在外，作用于整个 Group）

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/SettingsView.swift
git commit -m "feat(i18n): add language picker (general section) to SettingsView"
```

---

## Task 7: 迁移 SettingsView 内的动态字符串到 L10n

**Files:**
- Modify: `TennisMatch/Views/SettingsView.swift`

**说明：** SettingsView 中有几处字符串赋值（不是 `Text("…")`）需要显式用 `L10n.string(_:)` 才能跟随 LocaleManager 切换。识别出的位置：

1. `LinkedAccountsSheet.accountRow` 中：
   ```swift
   toastMessage = isLinked.wrappedValue ? "已關聯\(title)" : "已取消關聯\(title)"
   ```
2. `LinkedAccountsSheet.accountRow` 中：
   ```swift
   withAnimation { toastMessage = "至少需要保留一種登錄方式" }
   ```
3. `ChangePasswordSheet` 按钮 action 中：
   ```swift
   withAnimation { toastMessage = "請輸入目前的密碼" }
   withAnimation { toastMessage = "新密碼至少需要 6 位" }
   withAnimation { toastMessage = "兩次新密碼不一致" }
   withAnimation { toastMessage = "密碼修改成功" }
   ```

注意 `title` 在 LinkedAccountsSheet 中是 `String` 参数（如 "微信"），它本身是 SwiftUI 的 `Text("微信")` 翻译过来的吗？不是 —— `title` 是 Swift String 字面量传入的，需要单独把它本地化。

最简方案：把 `title` 改成 `LocalizedStringResource`，调用方传 key，row 内显示用 `Text(title)` 自动本地化，toast 拼接时用 `L10n.string("已關聯 \(String(localized: title))")`。

**但**为最小改动，本任务保持 `title: String` 不变，直接把 row 的 3 个调用点的 `title` 字面量传**繁中 key**，toast 用 `L10n.string("已關聯 \(title)")` —— 这要求 xcstrings 中 toast key 用 `%@` 占位符（已在 Task 3 中提供：`已關聯 %@`、`已取消關聯 %@`）。

- [ ] **Step 1: 修改 `LinkedAccountsSheet.accountRow` 的 toast 赋值**

找到：
```swift
withAnimation {
    isLinked.wrappedValue.toggle()
    toastMessage = isLinked.wrappedValue ? "已關聯\(title)" : "已取消關聯\(title)"
}
```

替换为：
```swift
withAnimation {
    isLinked.wrappedValue.toggle()
    toastMessage = isLinked.wrappedValue
        ? L10n.string("已關聯 \(title)")
        : L10n.string("已取消關聯 \(title)")
}
```

注意：`L10n.string("已關聯 \(title)")` 中的字面量在 String Catalog 中会被 Xcode 编译为 `已關聯 %@` 这个 key（Xcode 自动把插值变成 `%@`）。Task 3 的 xcstrings 已预填好 `已關聯 %@` 和 `已取消關聯 %@`。

- [ ] **Step 2: 修改 `LinkedAccountsSheet.accountRow` 中"至少保留"提示**

找到：
```swift
withAnimation { toastMessage = "至少需要保留一種登錄方式" }
```

替换为：
```swift
withAnimation { toastMessage = L10n.string("至少需要保留一種登錄方式") }
```

- [ ] **Step 3: 修改 `ChangePasswordSheet` 按钮 action 中 4 处 toast**

找到：
```swift
guard !currentPassword.isEmpty else {
    withAnimation { toastMessage = "請輸入目前的密碼" }
    return
}
guard newPassword.count >= 6 else {
    withAnimation { toastMessage = "新密碼至少需要 6 位" }
    return
}
guard newPassword == confirmPassword else {
    withAnimation { toastMessage = "兩次新密碼不一致" }
    return
}
withAnimation { toastMessage = "密碼修改成功" }
```

替换为：
```swift
guard !currentPassword.isEmpty else {
    withAnimation { toastMessage = L10n.string("請輸入目前的密碼") }
    return
}
guard newPassword.count >= 6 else {
    withAnimation { toastMessage = L10n.string("新密碼至少需要 6 位") }
    return
}
guard newPassword == confirmPassword else {
    withAnimation { toastMessage = L10n.string("兩次新密碼不一致") }
    return
}
withAnimation { toastMessage = L10n.string("密碼修改成功") }
```

- [ ] **Step 4: Build 验证**

Run: ⌘B in Xcode
Expected: BUILD SUCCEEDED

- [ ] **Step 5: 在 Xcode 打开 xcstrings，确认插值 key 已存在**

双击 `Localizable.xcstrings`。确认有 `已關聯 %@` 和 `已取消關聯 %@` 两条 key（Task 3 已预填）。如果 Xcode 自动追加了类似 `已關聯 %1$@` 或纯 `已關聯 ` 的 key（重复），手动删除多余条目，保留 `已關聯 %@`。

- [ ] **Step 6: 模拟器手动验证**

跑模拟器（⌘R），切到"我的" → 设置 → 切换语言为 English → 进入"關聯帳號" → 点 Google "Link" 按钮 → 弹出 toast 应显示 "Linked Google"。再次点击应显示 "Unlinked Google"。

- [ ] **Step 7: Commit**

```bash
git add TennisMatch/Views/SettingsView.swift
git commit -m "refactor(i18n): route SettingsView toasts through L10n.string"
```

---

## Task 8: 端到端验收测试

**Files:** 无（手动验证）

执行 spec 中的验收清单。本任务全部步骤都是手动 simulator 操作。

- [ ] **Step 1: 默认跟随系统 — zh-Hans 系统**

模拟器 → Settings → General → Language & Region → iPhone Language 改为"简体中文"。重新跑 App。
Expected：进入 SettingsView，看到 section header 为"通用 / 账号与安全 / ..."（简中），Tab Bar 标签为"首页 / 我的约球 / ..."。

- [ ] **Step 2: 默认跟随系统 — en 系统**

模拟器 iPhone Language 改为"English"。重跑 App。
Expected：SettingsView 显示英文，Tab Bar 显示英文。

- [ ] **Step 3: 默认跟随系统 — zh-Hant fallback**

模拟器 iPhone Language 改回 "繁體中文"（或选一个未支持的语言如 "Français"，应 fallback 到 source = zh-Hant）。重跑 App。
Expected：显示繁中。

- [ ] **Step 4: 切换后立即生效**

App 内进入设置 → 通用 → 语言 → 切到 "English"。
Expected：当前页面（设置页）所有文字立刻变英文，无需返回，无需重启。返回首页，Tab Bar 也是英文。

- [ ] **Step 5: 持久化（固定语言）**

承上，杀掉 App（从 multitasking 划掉），重新启动。
Expected：仍是英文（不会被系统语言覆盖）。

- [ ] **Step 6: 持久化（跟随系统）**

设置 → 通用 → 语言 → 切回"跟随系统"。杀掉 App 重启。
Expected：跟随系统当前语言（如系统是繁中则显示繁中）。

- [ ] **Step 7: 未翻译页面 fallback 检查**

设置语言为 English。返回首页（HomeView 内文字未翻译）、进入 ProfileView、MyMatchesView 等其他页面。
Expected：这些页面**仍正常显示繁中**，不出现 key 名、??? 占位、白屏或崩溃。

- [ ] **Step 8: 设置页内动态 toast 检查**

承 Task 7 已验证，再次确认：English 模式下 → 设置 → 关联账号 → 点 Google "Link" → toast = "Linked Google"。

- [ ] **Step 9: 切回繁中确认所有功能仍正常**

切到"繁體中文" → 走一遍：修改密碼弹窗 → 关联账号弹窗 → 退出登錄弹窗。
Expected：所有按钮、提示、错误信息均为繁中且功能正常。

- [ ] **Step 10: Commit（如有任何修复）**

如果 Step 1–9 中发现问题、修复后：
```bash
git add <fixed files>
git commit -m "fix(i18n): <describe fix>"
```
否则跳过。

---

## Task 9: 更新 plan 完成状态 + push

- [ ] **Step 1: 在本 plan 文件顶部追加完成状态**

在 `**Goal:**` 行下方追加一行：
```markdown
**Status:** ✅ Phase 1 complete (2026-04-24)
```

- [ ] **Step 2: 列出 Phase 2+ 待办（不实施）**

在文件末尾追加一段说明，列出 spec Section 4 中 Phase 2~N 的优先级清单（HomeView → MyMatchesView → ... → Models 内动态字符串），方便后续 PR 直接领取。

- [ ] **Step 3: Commit**

```bash
git add docs/superpowers/plans/2026-04-24-app-localization-phase1.md
git commit -m "docs(i18n): mark Phase 1 plan as complete + queue Phase 2 priorities"
```

- [ ] **Step 4: （可选）push 到 remote**

询问用户是否 push。如果 yes：
```bash
git push origin main
```

---

## 完成定义（Definition of Done）

Phase 1 完工时应满足：

1. 所有 9 个 task 的所有 step 已勾选完成
2. Spec Section 5 的 8 条验收标准全部通过（Task 8 已覆盖）
3. 所有改动已 commit（无 unstaged 文件）
4. 代码 build 无 error，xcstrings 在 Xcode 中显示 100% translated for SettingsView + Tab Bar 范围内的 key

---

## Phase 2+ 待办（follow-up PRs）

Phase 1 仅覆盖 SettingsView + Tab Bar。按优先级列出后续翻译范围：

1. **HomeView** — 首页卡片、推荐区、天气、信譽積分/場次/NTRP 统计、筛选按钮（全部/單打/雙打/拉球）、空状态
2. **MyMatchesView** — 我的约球列表、空状态、所有卡片字段、报名/取消按钮
3. **ChatView / ChatDetailView** — 聊天列表、消息时间戳格式、系统消息文案、邀请卡片
4. **ProfileView** — 個人資料、關注/粉絲、成就、記錄
5. **CreateMatchView / QuickMatchView** — 发布流程、日期/时间选择器 label、水平/人数/球场字段
6. **TournamentView 系列** — 赛事列表、详情、报名、取消通知
7. **LoginView / SignUpView** — 登录、注册、验证码、错误提示
8. **Onboarding / NTRP 自评** — NTRP 分级说明、引导文案
9. **Models 内动态字符串** — 通知文案模板（`NotificationStore` / `CalendarService`）、评论提示、时间相对描述
10. **日期/数字格式** — 统一改用 `Date.FormatStyle` / `NumberFormatter` 配合当前 locale（现在多为硬编码格式）

每批 PR 建议：选一个 View，扫全部 `Text("…")` + 硬编码 `String` 赋值 → 添加 xcstrings key 和 en/zh-Hans 翻译 → 检查所有 row/helper 函数的 `String` 参数是否需要改成 `LocalizedStringKey`（Phase 1 已修 SettingsView 的 `settingsRow`/`tappableRow`/`accountRow` 和 CustomTabBar 的 `tabBarItem`，同一模式在其他 View 可能复现）。
