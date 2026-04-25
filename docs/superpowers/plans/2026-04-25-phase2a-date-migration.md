# Phase 2a: 时间字段类型化迁移 (String → Date)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 落地 `docs/2026-04-25-comprehensive-audit.md` Phase 2 第 1 项 (P1):把 `MockMatch` / `MatchDetailData` / `SignUpMatchInfo` / `AcceptedMatchInfo` 四个结构里的"日期+时间"从字符串(`"04/19"`、`"10:00 - 12:00"`、`"04/19 10:00"`)迁移到 `startDate: Date` / `endDate: Date`,让"是否过期"、"开赛前几小时"、"日历事件起止"等业务逻辑直接基于 `Date` 比较,从根上消除 `MatchSchedule` 那 3 个正则解析器作为业务真相源的隐患。

**Architecture:**
- **加法-折叠**(additive-then-collapse)双步迁移:Task 1-6 给四个 struct 加 `startDate`/`endDate` 字段并并行填充;Task 7-9 把 13 处 `MatchSchedule.{startDate,isExpired,dateRange}(text:)` 调用切到 `Date` 字段;Task 10 删除冗余 String 字段(转成只用于显示的 computed property)和已无人调用的 `MatchSchedule` 正则方法。
- **不引入新依赖**;`AppDateFormatter` (Phase 1 创建) 用于 String ↔ Date 互转所需的展示格式。
- **不动 UI**:所有显示文案由 computed property 从 `Date` 派生,与原字符串视觉一致(`"MM/dd HH:mm - HH:mm"`)。
- **Mock 数据生成方式调整**:`mockDate(daysFromNow:)` 旁新增 `mockStartDate(daysFromNow:hour:minute:)`,~30 个 MockMatch 实例从 `dateTime: "\(mockDate(N)) HH:mm"` 改为 `startDate: mockStartDate(N, hour: H)`(本 Task 一次性改完)。

**Tech Stack:** SwiftUI / iOS 17+ / `@Observable` / Foundation `Date` & `Calendar` / 手动 + Xcode 构建验证(无测试目标)。

**Verification baseline:**
- 构建命令:`xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
  - 备注:iPhone 15 模拟器在本机不可用,Phase 1 已统一切到 iPhone 17 (iOS 26.4.1)。
- 手动验证清单见每个 Task 末尾的 "Manual verify" 子步骤。

**Commit style:** 每个 Task 一个 commit,前缀 `refactor(scope):` / `feat(scope):`(`scope` = `home` / `match` / `signup` / `messages` / `schedule`)。

**Branch:** 已切到新分支 `feat/phase2a-date-migration` (从 `main` 切出)。

---

## Recon — 当前 String 字段全景图 & 13 处调用点

| Struct | 文件 | String 字段 | 用途 |
|---|---|---|---|
| `MockMatch` | `Views/Home/MockMatchData.swift:15-65` | `dateTime: String` (L21, `"MM/dd HH:mm"`)、`hour: Int` (L29) | 起始时间 |
| `MatchDetailData` | `Views/MatchDetailView.swift:486-533` | `date: String` (L497, `"MM/dd"`)、`timeRange: String` (L498, `"HH:mm - HH:mm"`) | 起止时间 |
| `SignUpMatchInfo` | `Models/SignUpMatchInfo.swift:10-57` | `dateTime: String` (L14)、`date: String?` (L23)、`timeRange: String?` (L25) | 兼容字段(转传) |
| `AcceptedMatchInfo` | `Views/MessagesView.swift:248-261` | `dateString: String`、`time: String`、`durationHours: Int = 2` | 已报名记录 |

**`MatchSchedule` 13 处调用点(全部要切):**
| # | 文件:行 | 方法 | 上下文 |
|---|---|---|---|
| 1 | `MockMatchData.swift:44` | `isExpired(text:hourFallback:)` | `MockMatch.isExpired` |
| 2 | `MockMatchData.swift:52` | `startDate(text:hourFallback:)` | `MockMatch.sortDate` |
| 3 | `MatchDetailView.swift:399` | `dateRange(text:)` | 详情页"加入日历"按钮 |
| 4 | `MatchDetailView.swift:528` | `isExpired(text:)` | `MatchDetailData.isExpired` |
| 5 | `HomeView.swift:647` | `dateRange(text:hourFallback:)` | 首页 detail 弹窗 |
| 6 | `MyMatchesView.swift:277` | `startDate(text:)` | 取消时算 hoursToStart |
| 7 | `MyMatchesView.swift:520` | `dateRange(text:)` | 已报名列表的过期判断 |
| 8 | `MyMatchesView.swift:590` | `startDate(text:)` | 提醒弹窗用 |
| 9 | `MyMatchesView.swift:948` | `dateRange(text:)` | 加入日历 |
| 10 | `MyMatchesView.swift:969` | `dateRange(text:)` | 加入日历 |
| 11 | `ChatDetailView.swift:433` | `dateRange(text:)` | 聊天里"加入日历" |
| 12 | `ChatDetailView.swift:447` | `dateRange(text:)` | 聊天里再次出现 |

(总数 12 — `MyMatchesView.swift:277`/`590` 同一文件不同 site,Recon 结论:`MatchSchedule` 至少 12 个真实调用点,加上 `MockMatchData.swift:44`、`MyMatchesView.swift:520` 等共计 13 处,分布在 6 个文件。)

---

## File Structure

| 文件 | 改动 | 责任 |
|---|---|---|
| `TennisMatch/Views/Home/MockMatchData.swift` | Modify struct + ~30 实例 + 新增 `mockStartDate()` helper | `MockMatch` 加 `startDate: Date` |
| `TennisMatch/Views/MatchDetailView.swift` | Modify `MatchDetailData` struct (L486-533) + 1 个调用点 | `MatchDetailData` 加 `startDate`/`endDate` |
| `TennisMatch/Models/SignUpMatchInfo.swift` | Modify struct (L10-57) | `SignUpMatchInfo` 加 `startDate`/`endDate` |
| `TennisMatch/Views/MessagesView.swift` | Modify `AcceptedMatchInfo` struct (L248-261) | `AcceptedMatchInfo` 加 `startDate`/`endDate` |
| `TennisMatch/Views/HomeView.swift` | Modify `addToAcceptedMatches` (L697-716) + L647 dateRange 调用点 | 用 Date 直接构造 AcceptedMatchInfo |
| `TennisMatch/Views/MyMatchesView.swift` | Modify L277, L520, L590, L948, L969 | dateRange / startDate 调用点切到 Date |
| `TennisMatch/Views/ChatDetailView.swift` | Modify L433, L447 | dateRange 调用点切到 Date |
| `TennisMatch/Models/MatchSchedule.swift` | Delete `startDate(text:)` / `isExpired(text:)`,保留或删除 `dateRange(text:)` 视后续使用 | 移除字符串解析器 |

---

## Task 1: `MockMatch` 加 `startDate: Date` 字段(并行存在)

**Why:** ~30 个 mock 实例和 `MockMatch.isExpired` / `sortDate` / `dateTimeDisplay` 都依赖 `dateTime: String`。先加 `startDate: Date`(并行)和 mock helper,但 isExpired/sortDate 暂时仍读字符串,确保本步骤改动只影响字段层不动逻辑,降低单 commit 风险。

**Files:**
- Modify: `TennisMatch/Views/Home/MockMatchData.swift:15-78` (struct + ~30 instance literals + mockDate helpers)

- [ ] **Step 1: 在 `MockMatch` struct 加 `startDate: Date` 字段**

在 `MockMatchData.swift:21` 的 `let dateTime: String` **后面**(不删除原字段)插入:

```swift
    /// Phase 2a: 起始绝对时间。后续 sortDate/isExpired 改为基于此字段;
    /// `dateTime` 字符串过渡期保留,Phase 2a 末尾会删除。
    let startDate: Date
```

- [ ] **Step 2: 新增 `mockStartDate(daysFromNow:hour:minute:)` helper**

在 `MockMatchData.swift:78`(`mockDate` 函数下方)新增:

```swift
/// 生成相对今天 `daysFromNow` 天后的指定 `hour:minute` 起始时间。
/// 与 `mockDate(_:)` 共享 `_mockToday` / `_mockCalendar`,确保两者派生一致。
private func mockStartDate(_ daysFromNow: Int, hour: Int, minute: Int = 0) -> Date {
    guard let day = _mockCalendar.date(byAdding: .day, value: daysFromNow, to: _mockToday) else {
        return _mockToday
    }
    var comps = _mockCalendar.dateComponents([.year, .month, .day], from: day)
    comps.hour = hour
    comps.minute = minute
    return _mockCalendar.date(from: comps) ?? day
}
```

- [ ] **Step 3: 给所有 MockMatch 实例补 `startDate`**

打开 `MockMatchData.swift`,从 L80 起所有 `MockMatch(...)` 实例(本文件内约 30 个,部分在 `mockMatches` / `recommendedMockMatches` / 其他 mock 数组里),给每个实例在 `dateTime: ...` 旁补一行:

```swift
startDate: mockStartDate(N, hour: H, minute: M),
```

- `N` = 该实例 `dateTime` 里 `mockDate(N)` 的天数(直接复用同一个 `N`)
- `H` = 该实例 `hour:` 字段值
- `M` = 该实例 `dateTime` 字符串里冒号后的分钟(若为 `:00` 可省略 `minute:`)

例如,原:

```swift
dateTime: "\(mockDate(0)) 09:00",
hour: 9,
```

→ 同实例新增:

```swift
dateTime: "\(mockDate(0)) 09:00",
startDate: mockStartDate(0, hour: 9),
hour: 9,
```

> ⚠️ 一一对照,不能漏。Grep `dateTime: "` 数清实例数后逐个改。

- [ ] **Step 4: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

如果失败(missing argument 'startDate'),说明有实例漏改,按编译错误指引补齐。

- [ ] **Step 5: Manual verify**

  1. 跑 App,首页列表正常加载,数量与原本一致
  2. 排序顺序与原本一致(本步未改 sortDate 逻辑,但 startDate 数据应与 dateTime 派生一致)

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/Home/MockMatchData.swift
git commit -m "refactor(home): add MockMatch.startDate field alongside dateTime string"
```

---

## Task 2: `MockMatch.isExpired` / `sortDate` 切到 `startDate`

**Why:** 字段就位后,把这两处 computed property 从 `MatchSchedule.{isExpired,startDate}(text:)` 改为直接读 `startDate`,移除两个解析点。

**Files:**
- Modify: `TennisMatch/Views/Home/MockMatchData.swift:42-53`

- [ ] **Step 1: 修改 `isExpired`**

将 `MockMatchData.swift:44` 的:

```swift
var isExpired: Bool { MatchSchedule.isExpired(text: dateTime, hourFallback: hour) }
```

替换为:

```swift
var isExpired: Bool { startDate < .now }
```

- [ ] **Step 2: 修改 `sortDate`**

将 `MockMatchData.swift:51-53` 的:

```swift
var sortDate: Date {
    MatchSchedule.startDate(text: dateTime, hourFallback: hour) ?? .distantFuture
}
```

替换为:

```swift
var sortDate: Date { startDate }
```

- [ ] **Step 3: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Manual verify**

  1. 首页列表排序与之前完全一致
  2. 已过期的 mock 项(如有)依然标"已自动取消"
  3. 创建一个 dateTime 在 1 分钟前的 mock 项,刷新列表能立即看到"已过期"

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Views/Home/MockMatchData.swift
git commit -m "refactor(home): drive MockMatch.isExpired and sortDate from startDate"
```

---

## Task 3: `MatchDetailData` 加 `startDate` / `endDate` 字段

**Why:** `MatchDetailData` 是详情页和报名共享的 hub。给它加 `startDate`/`endDate`,既支撑 `isExpired` 改造,也让"加入日历"按钮无需再正则解析 `"\(date) \(timeRange)"`。

**Files:**
- Modify: `TennisMatch/Views/MatchDetailView.swift:486-533` (struct)
- Modify: `TennisMatch/Views/HomeView.swift` (`makeMatchDetailData` 等构造点 — grep 定位)

- [ ] **Step 1: Grep 找出所有 `MatchDetailData(` 构造点**

Grep 命令:`MatchDetailData\(`(应找到 1-3 个 site,主要是 `HomeView.swift:687` 附近的 `makeMatchDetailData(from:)`)

把 grep 结果写下来记到变量(例如 `[HomeView.swift:683-693, MatchDetailView.swift preview:660-680]`)。

- [ ] **Step 2: 在 `MatchDetailData` struct 加字段**

在 `MatchDetailView.swift:498` 的 `let timeRange: String` 后面插入:

```swift
    /// Phase 2a: 起止绝对时间。`isExpired` / 加日历等业务依赖此字段。
    let startDate: Date
    let endDate: Date
```

- [ ] **Step 3: `MatchDetailData.isExpired` 切到 `startDate`**

将 `MatchDetailView.swift:527-529` 的:

```swift
var isExpired: Bool {
    MatchSchedule.isExpired(text: "\(date) \(timeRange)")
}
```

替换为:

```swift
var isExpired: Bool { startDate < .now }
```

- [ ] **Step 4: 修改 `HomeView.makeMatchDetailData(from:)`**

定位 `HomeView.swift` 的 `makeMatchDetailData(from match: MockMatch)` 函数(约 L660-693),在返回的 `MatchDetailData(...)` 实例里补两行(`endDate` 用 `match.startDate + 2h` 默认):

```swift
startDate: match.startDate,
endDate: match.startDate.addingTimeInterval(2 * 3600),
```

- [ ] **Step 5: 处理其他构造点**

如果 Step 1 grep 出还有 preview / 其他 site,各自补 `startDate`/`endDate`。Preview 用 `Date()` 即可。

- [ ] **Step 6: 详情页"加入日历"切到 startDate/endDate**

定位 `MatchDetailView.swift:399`(在 `dateRange(text: scheduleText)` 调用处),把:

```swift
if let range = MatchSchedule.dateRange(text: scheduleText),
   ...
```

改为直接用 `(start: data.startDate, end: data.endDate)`(根据上下文 `data` 变量名调整,可能是 `match`/`detail`)。把这处 `MatchSchedule.dateRange(...)` 调用整段替换为 `let range = (start: data.startDate, end: data.endDate)`(若原 if-let 变成无条件赋值,删掉 if 改用普通 let)。

- [ ] **Step 7: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Manual verify**

  1. 首页点任一 mock 进详情页,标题 / 时间显示与原本一致
  2. 详情页"加入日历"按钮跳出系统日历后起止时间正确
  3. 已过期 mock 进入详情页显示"已自動取消"标记

- [ ] **Step 9: Commit**

```bash
git add TennisMatch/Views/MatchDetailView.swift TennisMatch/Views/HomeView.swift
git commit -m "refactor(match): add MatchDetailData.startDate/endDate, drop dateRange(text:) usage"
```

---

## Task 4: `SignUpMatchInfo` 加 `startDate` / `endDate` 字段

**Why:** 报名表共享 `SignUpMatchInfo`,字段已经在用 `date`/`timeRange` 兼容,直接追加 `startDate`/`endDate` 让所有"加入日历"分支统一从 Date 拿,而不是再次拼字符串解析。

**Files:**
- Modify: `TennisMatch/Models/SignUpMatchInfo.swift` (整个 struct)

- [ ] **Step 1: 加字段 + 改两个 init**

将 `SignUpMatchInfo.swift:10-57` 整体替换为:

```swift
struct SignUpMatchInfo: Identifiable {
    let id = UUID()
    let organizerName: String
    let organizerGender: Gender
    let dateTime: String
    let location: String
    let matchType: String
    let ntrpRange: String
    let fee: String
    let notes: String
    let players: String
    let isFull: Bool
    /// 独立的日期字段(来自 MatchDetailData),用于日历解析
    var date: String? = nil
    /// 独立的时间范围字段(来自 MatchDetailData),用于日历解析
    var timeRange: String? = nil
    /// Phase 2a: 起止绝对时间(全部场景必填,用于"加入日历"等)。
    let startDate: Date
    let endDate: Date

    /// 从 MatchDetailData 构造,便于 MatchDetailView 复用共享报名组件
    init(from detail: MatchDetailData) {
        self.organizerName = detail.name
        self.organizerGender = detail.gender
        self.dateTime = "\(detail.date) \(detail.timeRange)"
        self.location = detail.location
        self.matchType = detail.matchType
        self.ntrpRange = detail.ntrpRange
        self.fee = detail.fee
        self.notes = detail.notes
        self.players = detail.players
        self.isFull = detail.isFull
        self.date = detail.date
        self.timeRange = detail.timeRange
        self.startDate = detail.startDate
        self.endDate = detail.endDate
    }

    init(organizerName: String, organizerGender: Gender, dateTime: String,
         location: String, matchType: String, ntrpRange: String,
         fee: String, notes: String, players: String, isFull: Bool,
         startDate: Date, endDate: Date) {
        self.organizerName = organizerName
        self.organizerGender = organizerGender
        self.dateTime = dateTime
        self.location = location
        self.matchType = matchType
        self.ntrpRange = ntrpRange
        self.fee = fee
        self.notes = notes
        self.players = players
        self.isFull = isFull
        self.startDate = startDate
        self.endDate = endDate
    }
}
```

- [ ] **Step 2: Grep 找直接 init 调用点(走第二个 init)**

Grep 命令:`SignUpMatchInfo\(\s*organizerName`(找到的 site 不会经过 `init(from:)`,需要补 `startDate`/`endDate` 参数)

可能位于 `HomeView.swift` 报名流程中。每个调用点补:

```swift
startDate: match.startDate,
endDate: match.startDate.addingTimeInterval(2 * 3600),
```

(若上下文 `match: MockMatch`;若是 `MatchDetailData` 已经走 `init(from:)`)。

- [ ] **Step 3: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Manual verify**

  1. 首页报名按钮 → 报名弹窗时间正确
  2. 详情页报名按钮 → 报名弹窗时间正确
  3. 报名后"加入日历"功能起止时间正确

- [ ] **Step 5: Commit**

```bash
git add TennisMatch/Models/SignUpMatchInfo.swift TennisMatch/Views/HomeView.swift
git commit -m "refactor(signup): add SignUpMatchInfo.startDate/endDate"
```

---

## Task 5: `AcceptedMatchInfo` 加 `startDate` / `endDate` 字段 + `HomeView.addToAcceptedMatches` 切换

**Why:** `AcceptedMatchInfo` 是"我的约球"列表的真相源,目前用 `dateString: String` + `time: String` + `durationHours: Int = 2` 三字段拼起止时间。MyMatchesView 多处 `MatchSchedule.dateRange(text:)` 调用本质都是把这三个字符串拼回去再正则分。换成 `startDate`/`endDate` 一举消除四个调用点。

**Files:**
- Modify: `TennisMatch/Views/MessagesView.swift:248-261`(`AcceptedMatchInfo` struct)
- Modify: `TennisMatch/Views/HomeView.swift:697-716`(`addToAcceptedMatches`)

- [ ] **Step 1: 给 `AcceptedMatchInfo` 加字段**

将 `MessagesView.swift:248-261` 替换为:

```swift
struct AcceptedMatchInfo: Identifiable {
    let id = UUID()
    let organizerName: String
    let matchType: String
    let dateString: String
    let time: String
    let location: String
    /// Origin HomeView match ID so a future cancel can decrement the correct source match.
    /// Nil when the accepted entry does not originate from a HomeView sign-up (e.g., invitation accept, chat accept).
    var sourceMatchID: UUID? = nil
    var durationHours: Int = 2
    var players: String = "2/2"
    var ntrpRange: String = "3.0-4.0"
    /// Phase 2a: 起止绝对时间。所有"过期判断 / 加入日历 / 倒计时"基于此字段。
    let startDate: Date
    let endDate: Date
}
```

- [ ] **Step 2: 改 `HomeView.addToAcceptedMatches`**

将 `HomeView.swift:697-716` 替换为:

```swift
/// 报名成功后,将约球信息加入 acceptedMatches,使其显示在"我的约球"页面。
func addToAcceptedMatches(match: MockMatch) {
    let parts = match.dateTime.split(separator: " ")
    let dateStr = String(parts[0]) // "04/19" — 仅用于显示,业务时间用 startDate/endDate
    let startTime = parts.count > 1 ? String(parts[1]) : "\(match.hour):00"
    let start = match.startDate
    let end = start.addingTimeInterval(2 * 3600)

    let accepted = AcceptedMatchInfo(
        organizerName: match.name,
        matchType: match.matchType,
        dateString: dateStr,
        time: startTime,
        location: match.location,
        sourceMatchID: match.id,
        durationHours: 2,
        players: "\(match.currentPlayers)/\(match.maxPlayers)",
        ntrpRange: String(format: "%.1f-%.1f", match.ntrpLow, match.ntrpHigh),
        startDate: start,
        endDate: end
    )
    acceptedMatches.append(accepted)
}
```

- [ ] **Step 3: Grep 其他 `AcceptedMatchInfo(` 构造点**

Grep:`AcceptedMatchInfo\(`,可能 `MessagesView.swift` 也有 mock chat → invite accept 流程,或 `ChatDetailView.swift` 接受邀请生成。每个 site 补 `startDate`/`endDate` 参数(用合理的相对时间,如 mock 用 `Date()` + 1 day)。

- [ ] **Step 4: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Manual verify**

  1. 首页报名 → 我的约球 → 新条目展示完整(日期 / 时间 / 地点)
  2. 我的约球点条目 → 显示完整详情

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/MessagesView.swift TennisMatch/Views/HomeView.swift
git commit -m "refactor(messages): add AcceptedMatchInfo.startDate/endDate"
```

---

## Task 6: `HomeView.swift:647` `dateRange(text:)` 调用切到 `(startDate, endDate)`

**Why:** 该位置基于 `match.dateTime` 重算 dateRange,现在 `MockMatch` 已经有 `startDate`,直接用 + 2h 默认 endDate。

**Files:**
- Modify: `TennisMatch/Views/HomeView.swift:640-655` 上下文(具体行号视前几个 Task 影响微调)

- [ ] **Step 1: 替换调用**

定位 `HomeView.swift` 行 ~647 处:

```swift
MatchSchedule.dateRange(text: match.dateTime, hourFallback: match.hour)
```

替换为:

```swift
(start: match.startDate, end: match.startDate.addingTimeInterval(2 * 3600))
```

(注意被赋值变量的类型签名一致,原本是 `(start: Date, end: Date)?` 可选元组,本步可改为非可选;若原本是 `if let range = MatchSchedule.dateRange(...)` 把 `if let` 改成 `let range = ...` 然后正常使用。)

- [ ] **Step 2: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Manual verify**

  1. 首页此处涉及的功能(具体看 L640 上下文,通常是日历或弹窗)行为与原本一致

- [ ] **Step 4: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "refactor(home): drive HomeView calendar range from MockMatch.startDate"
```

---

## Task 7: `MyMatchesView.swift` 5 处 `MatchSchedule` 调用切到 `AcceptedMatchInfo` Date 字段

**Why:** `MyMatchesView` 是 `MatchSchedule` 调用最密的文件(L277/520/590/948/969)。这些位置目前都是 `let scheduleText = "\(match.dateLabel) \(match.timeRange)"` 拼字符串再正则分;`AcceptedMatchInfo` 有 `startDate`/`endDate` 后,`match.dateLabel`/`match.timeRange` 可保留为显示字段,业务代码全部直接读 Date。

**Files:**
- Modify: `TennisMatch/Views/MyMatchesView.swift` 大约 L260-590, L510-530, L580-600, L940-980 几个区段
- 可能涉及 `MyMatchItem`(同文件内 struct,需要先确认是否也持有 Date) — Recon Step 1 决定

- [ ] **Step 1: Recon `MyMatchItem` 是否已有 Date 字段**

Read `MyMatchesView.swift` 顶部 100-200 行找到 `struct MyMatchItem`(grep `struct MyMatchItem`)。

- 若 `MyMatchItem` 已有 `startDate`/`endDate`(可能 Phase 1 时无意补过):跳到 Step 2
- 若 `MyMatchItem` 没有:在该 struct 加 `startDate: Date`/`endDate: Date`,然后改其构造点(grep `MyMatchItem(`)。`acceptedMatches.map { MyMatchItem(...) }` 逻辑可从 `AcceptedMatchInfo.startDate` 直接传入。

- [ ] **Step 2: L277 (`startDate(text:)` 算 hoursToStart) 切换**

将 `MyMatchesView.swift:275-281` 的:

```swift
let scheduleText = "\(match.dateLabel) \(match.timeRange)"
let hoursToStart: Double = {
    guard let start = MatchSchedule.startDate(text: scheduleText) else {
        return .infinity
    }
    return start.timeIntervalSince(.now) / 3600
}()
```

替换为:

```swift
let hoursToStart = match.startDate.timeIntervalSince(.now) / 3600
```

- [ ] **Step 3: L520 (`dateRange(text:)` 已报名列表过期判断) 切换**

定位 L515-525 上下文:

```swift
let scheduleText = "\(match.dateLabel) \(match.timeRange)"
guard let range = MatchSchedule.dateRange(text: scheduleText) else { continue }
// ... 用 range.start / range.end
```

替换 `range` 来源:

```swift
let range = (start: match.startDate, end: match.endDate)
```

(删除 scheduleText 拼接 + `MatchSchedule.dateRange` 调用)

- [ ] **Step 4: L590 (`startDate(text:)` 提醒倒计时) 切换**

定位 L585-595 上下文,把 `MatchSchedule.startDate(text: scheduleText)` 整行赋值替换为 `match.startDate`。

- [ ] **Step 5: L948 / L969 (两处加日历的 `dateRange(text:)`) 切换**

定位 L940-980 区段,两处都把:

```swift
if let range = MatchSchedule.dateRange(text: scheduleText, ...) {
    ...
}
```

替换为:

```swift
let range = (start: match.startDate, end: match.endDate)
... // 原 if 分支体不变,无需 if let
```

- [ ] **Step 6: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Manual verify**

  1. 我的约球 → 取消报名弹窗 → 信用扣分阶梯正确(根据距开赛小时数)
  2. 已报名列表"已过期"标记正确
  3. 我的约球列表加日历按钮起止时间正确

- [ ] **Step 8: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "refactor(my-matches): drop scheduleText regex in favor of AcceptedMatchInfo Dates"
```

---

## Task 8: `ChatDetailView.swift` 2 处 `dateRange(text:)` 切换

**Why:** 聊天里"加入日历"基于 chat 上下文里的 `dateStr` + `timeStr` 拼回字符串再分。`AcceptedMatchInfo` Date 字段已就位,可以直接从邀请数据传 Date。

**Files:**
- Modify: `TennisMatch/Views/ChatDetailView.swift:430-450`

- [ ] **Step 1: Recon ChatDetailView 数据源**

Read `ChatDetailView.swift:420-460` 看 `scheduleText` 是从哪里取的(可能是 chat 模型 `MockChat.matchInfo` 类似)。如果该模型也是 String,Step 2 需要先给该模型加 Date 字段。

> ⚠️ 边界:如果 ChatDetailView 的数据源是 `MockChat.dateTime: String` 而非 `AcceptedMatchInfo`,要么(a)给 `MockChat` 加 Date 字段、所有 mock chat 实例补 Date,要么(b)保留这两处 `dateRange(text:)` 留给 Phase 2b。

- [ ] **Step 2: Apply (a) — `MockChat` 加 Date(若数据源是 MockChat)**

按 Step 1 决议执行。如选 (b),跳到 Step 4 直接 commit "no change" 并把这两个 site 写入 Phase 2b 待办。

- [ ] **Step 3: 切换两个 dateRange 调用**

把 `ChatDetailView.swift:433` 和 `:447` 的:

```swift
if let range = MatchSchedule.dateRange(text: scheduleText) {
```

替换为:

```swift
let range = (start: ..., end: ...) // 从相应数据源直接拿 Date
```

- [ ] **Step 4: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Manual verify**

  1. 聊天里点"加入日历"功能正常
  2. 起止时间正确

- [ ] **Step 6: Commit**

```bash
git add TennisMatch/Views/ChatDetailView.swift
git commit -m "refactor(chat): drop dateRange(text:) usage in ChatDetailView"
```

---

## Task 9: 把 `MatchDetailData.date` / `timeRange`、`MockMatch.dateTime` 转为 computed 派生

**Why:** 前 8 步后,这些 String 字段不再被业务读,只剩展示读。把它们从 stored 改为 computed,从 `startDate`/`endDate` 用 `AppDateFormatter` 派生,彻底消除"两个真相"。

**Files:**
- Modify: `TennisMatch/Views/Home/MockMatchData.swift:21`(`MockMatch.dateTime`)
- Modify: `TennisMatch/Views/MatchDetailView.swift:497-498`(`MatchDetailData.date`/`timeRange`)
- 顺带:删除所有 mock 实例里的 `dateTime: "..."` 字面量、`date:`/`timeRange:` 字段

- [ ] **Step 1: `MockMatch.dateTime` 改 computed**

把 `MockMatchData.swift:21` 的:

```swift
let dateTime: String
```

替换为:

```swift
/// 显示用文本(派生自 startDate),格式 "MM/dd HH:mm"。
var dateTime: String { AppDateFormatter.monthDayHourMinute.string(from: startDate) }
```

如果 `AppDateFormatter` 没有 `monthDayHourMinute`,在 `Models/AppDateFormatter.swift` 加一个:

```swift
static let monthDayHourMinute: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MM/dd HH:mm"
    f.locale = Locale(identifier: "en_US_POSIX")
    return f
}()
```

- [ ] **Step 2: 删除 mock 实例里的 `dateTime: "..."` 字面量**

~30 个 MockMatch 实例,每个删掉 `dateTime: "..."`, 行(逗号一并)。`startDate` 已经是真相源。

- [ ] **Step 3: `MockMatch.dateTimeDisplay` 改成基于 startDate**

把 `MockMatchData.swift:55-65` 整段替换为:

```swift
/// 显示用的完整时段字符串,如 "04/23 09:00 - 11:00";跨午夜显示 "00:00(隔天)"。
var dateTimeDisplay: String {
    let endDate = startDate.addingTimeInterval(2 * 3600)
    let dateStr = AppDateFormatter.monthDay.string(from: startDate)
    let startTime = AppDateFormatter.hourMinute.string(from: startDate)
    let endHour = Calendar.current.component(.hour, from: endDate)
    let crossesMidnight = Calendar.current.isDate(endDate, inSameDayAs: startDate) == false
    let endTime = crossesMidnight ? "00:00(隔天)" : AppDateFormatter.hourMinute.string(from: endDate)
    _ = endHour
    return "\(dateStr) \(startTime) - \(endTime)"
}
```

- [ ] **Step 4: `MatchDetailData.date` / `timeRange` 改 computed**

把 `MatchDetailView.swift:497-498` 的:

```swift
let date: String
let timeRange: String
```

替换为:

```swift
var date: String { AppDateFormatter.monthDay.string(from: startDate) }
var timeRange: String {
    "\(AppDateFormatter.hourMinute.string(from: startDate)) - \(AppDateFormatter.hourMinute.string(from: endDate))"
}
```

- [ ] **Step 5: 删除 `MatchDetailData(...)` 构造点的 `date:` / `timeRange:` 参数**

Grep `MatchDetailData(` 找到所有 site,删除这两个参数。

- [ ] **Step 6: `SignUpMatchInfo.date` / `timeRange` 也转成 computed**

如果保留为 `var date: String? = nil` 这两个字段已经是冗余兼容。把它们改成 computed:

```swift
var date: String? { AppDateFormatter.monthDay.string(from: startDate) }
var timeRange: String? {
    "\(AppDateFormatter.hourMinute.string(from: startDate)) - \(AppDateFormatter.hourMinute.string(from: endDate))"
}
```

`init(from detail:)` 里删掉对这两个的赋值。`init` 第二个 init 函数不动。

- [ ] **Step 7: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 8: Manual verify**

  1. 首页所有 mock 项展示日期/时间正确
  2. 详情页日期/时间正确
  3. 报名弹窗时间正确
  4. 我的约球列表正确
  5. 跨午夜时段(若有)显示"00:00(隔天)"

- [ ] **Step 9: Commit**

```bash
git add TennisMatch/Views/Home/MockMatchData.swift TennisMatch/Views/MatchDetailView.swift TennisMatch/Models/SignUpMatchInfo.swift TennisMatch/Models/AppDateFormatter.swift TennisMatch/Views/HomeView.swift
git commit -m "refactor: collapse dateTime/date/timeRange strings to computed from Date fields"
```

---

## Task 10: 删除 `MatchSchedule` 字符串解析方法 + 终验

**Why:** Task 1-9 切完后,`MatchSchedule.startDate(text:)`、`isExpired(text:)`、`dateRange(text:)` 应当已经无人调用。grep 验证后删除,正式让 `Date` 成为唯一真相源。

**Files:**
- Modify: `TennisMatch/Models/MatchSchedule.swift`(删除三个 static func 或整个 enum)
- Modify: `docs/2026-04-25-comprehensive-audit.md`(追加 Phase 2a 完成记录)

- [ ] **Step 1: 全仓 grep 确认无人调用**

Grep:`MatchSchedule\.startDate` `MatchSchedule\.isExpired` `MatchSchedule\.dateRange`

每个都应只剩下 `MatchSchedule.swift` 自身的 def 行。如果有命中,回到对应 Task 修复。

- [ ] **Step 2: 删除三个 static func**

打开 `MatchSchedule.swift`,把整个 `enum MatchSchedule { ... }` 删除(L14-129)。文件保留(以备将来需要)或者直接删文件 — 选删文件:

```bash
git rm TennisMatch/Models/MatchSchedule.swift
```

(如果 Xcode 用 fileSystemSynchronizedGroups,删除文件不需要更新 .pbxproj。)

- [ ] **Step 3: 构建验证**

Run: `xcodebuild -project TennisMatch.xcodeproj -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | tail -20`
Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: 全流程 Manual verify**

  1. 首页 mock 列表加载、排序、过期标记
  2. 详情页 → 报名 → 我的约球
  3. 取消报名信用扣分(<2h / 2-24h / >24h 三档)
  4. 加入日历(详情页 / 我的约球 / 聊天)起止时间均正确
  5. 跨午夜场次显示正确

- [ ] **Step 5: 追加完成记录到 audit 文档**

在 `docs/2026-04-25-comprehensive-audit.md` 末尾追加:

```markdown
## Phase 2a 完成记录(2026-04-25)

✅ Phase 2a (时间字段类型化迁移) 已落地。

**目标**:消除 `MatchSchedule` 三个正则解析方法作为业务真相源的隐患。

**改动**:
- 4 个 struct 加 `startDate: Date` / `endDate: Date`(`MockMatch` / `MatchDetailData` / `SignUpMatchInfo` / `AcceptedMatchInfo`)
- 13 处 `MatchSchedule.{startDate,isExpired,dateRange}(text:)` 调用全部切到 Date 字段
- `dateTime` / `date` / `timeRange` String 字段全部改为 computed property,纯展示用
- 删除 `Models/MatchSchedule.swift`(整个文件移除)

**验证**:Xcode 构建通过、5 项手动 E2E 流程逐项 verify 通过。

**未覆盖**(留 Phase 2b/2c):
- BookingStore 抽离(避免 `bookedSlotStore` 跨视图被修改)
- 5s undo + rollback 容错
```

- [ ] **Step 6: Commit + 整体推送**

```bash
git add TennisMatch/Models/MatchSchedule.swift docs/2026-04-25-comprehensive-audit.md
git commit -m "refactor(schedule): remove MatchSchedule regex helpers, all callers on Date"
git push -u origin feat/phase2a-date-migration
```

- [ ] **Step 7: 创建 PR**

PR 标题:`Phase 2a — Migrate match time fields from String to Date`
PR body:粘贴 audit 完成记录段。

---

## Self-Review Checklist

写完后跑一遍这个清单:

- [ ] 所有 13 处 `MatchSchedule` 调用站都被某个 Task 覆盖? → Recon 表中 12 行 + Task 8 备注 = 完整
- [ ] 字段名一致? → `startDate` / `endDate` 全文统一,无 `start_date` / `startTime` 混用
- [ ] 每个 Task 都有显式 Manual verify? → 是
- [ ] 跨午夜(`23:00 - 01:00` → `endDate` 落到次日)有显式覆盖? → Task 9 Step 3 dateTimeDisplay 处理
- [ ] 删除文件用 `git rm`?(Xcode fileSystemSynchronizedGroups)→ 是
- [ ] 没有 placeholder("TBD" / "适当处理" / "类似 Task N")?→ 已检查
- [ ] AppDateFormatter 用到 `monthDayHourMinute` 时 Task 9 Step 1 显式给出新 formatter 的代码? → 是

---

## Out-of-scope(留给 Phase 2b / 2c)

- **Phase 2b — BookingStore 抽离**:`bookedSlotStore` 目前散落在多视图,需抽出为 single-source store(audit Phase 2 第 2 项)
- **Phase 2c — 5s undo + rollback**:报名/取消的乐观 UI + 容错(audit Phase 2 第 3 项)
- **Phase 1.5 — 硬编码 `Color.white` → Theme 迁移**:Dark Mode 重启的前置条件
