# 时间冲突 + 取消信用分 闭环 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the loop between 时间冲突检测 and 取消/爽约信用分,使报名流程能区分 pending 软占用 / confirmed 硬占用,取消行为按状态扣分,信用分跌破阈值时阻断后续发起约球。

**Architecture:** 在现有 `BookingStore.conflict(...)` 基础上新增 `softConflict(...)` 只查 pending;`CreditScoreStore` 新增 `recordConfirmedCancellation` 与 `canPublishMatch` 派生属性,`MyMatchesView` 取消流程按状态选用扣分入口。HomeView 的 `+ 发布` 与 `signUp` 入口分别接信用分门槛、软冲突二次确认。

**Tech Stack:** Swift / SwiftUI、`@Observable`、XCTest。

**Spec source:** `docs/2026-04-26-flow-stress-test.md` §🔴 #2(本计划裁剪掉「高级局/认证发起人 信用分门槛」分支 — 由用户决策跳过)。

**关键差异(对照原始 spec):**

- 原 spec 的 `-10/-30` 改成 hybrid:pending 维持 `-1/-2`,confirmed `<4h` `-4`,no-show `-5`(温和)。
- 原 spec 的「< 60 高级局禁报」整段删除 — 没有「高级局」概念。
- 信用分阈值新语义:`< 70` 禁止发起约球(警告);`< 60` 封号 3 个月。

---

## File Structure

| 文件                                                   | 责任                  | 动作                                                                                                                         |
| ------------------------------------------------------ | --------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `TennisMatch/Models/BookingStore.swift`                | 报名单一来源;冲突查询 | 新增 `softConflict(...)`,既有 `conflict(...)` 行为不变                                                                       |
| `TennisMatch/Models/CreditScoreStore.swift`            | 信用分及变动          | 新增 `recordConfirmedCancellation`、改 `recordNoShow` 为 -5、新增 `canPublishMatch` / `isBanned` 派生属性、注释/常量语义更新 |
| `TennisMatch/Components/CreditScoreHistoryView.swift`  | 规则展示              | 更新 `rulesCard` 文案与处罚行                                                                                                |
| `TennisMatch/Views/HomeView.swift`                     | 发布入口 + 报名入口   | `+ 按钮` 加信用分门槛;`showSignUp` 增加软冲突二次确认 alert                                                                  |
| `TennisMatch/Views/MyMatchesView.swift`                | 取消流程              | 按 application status 选 `recordConfirmedCancellation` vs `recordCancellation`;pending 撤回也走 tiered 扣分                  |
| `TennisMatchTests/CreditScoreStoreTests.swift`         | 新文件                | 覆盖三类扣分 + 派生属性边界                                                                                                  |
| `TennisMatchTests/BookingStoreSoftConflictTests.swift` | 新文件                | pending 触发 soft、confirmed 触发 hard、excluding 行为                                                                       |

---

## Task 1: `CreditScoreStore` 新规则

**Files:**

- Modify: `TennisMatch/Models/CreditScoreStore.swift`
- Test: `TennisMatchTests/CreditScoreStoreTests.swift` (create)

- [ ] **Step 1.1: 写第一个失败测试 — pending tiered 不变(防止回归)**

Create `TennisMatchTests/CreditScoreStoreTests.swift`:

```swift
import XCTest
@testable import TennisMatch

@MainActor
final class CreditScoreStoreTests: XCTestCase {

    var store: CreditScoreStore!

    override func setUp() async throws {
        store = CreditScoreStore(score: 80, entries: [])
    }

    func test_recordCancellation_pendingTiers_unchanged() {
        XCTAssertEqual(store.recordCancellation(hoursBeforeStart: 30, detail: "x"), 0)
        XCTAssertEqual(store.score, 80)

        XCTAssertEqual(store.recordCancellation(hoursBeforeStart: 10, detail: "x"), 1)
        XCTAssertEqual(store.score, 79)

        XCTAssertEqual(store.recordCancellation(hoursBeforeStart: 1, detail: "x"), 2)
        XCTAssertEqual(store.score, 77)
    }
}
```

- [ ] **Step 1.2: 跑该测试,确认通过(行为本来就符合)**

Run: `xcodebuild test -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TennisMatchTests/CreditScoreStoreTests/test_recordCancellation_pendingTiers_unchanged`
Expected: PASS — 锁定既有 pending 扣分行为。

- [ ] **Step 1.3: 写失败测试 — confirmed cancel <4h → -4**

Append:

```swift
    func test_recordConfirmedCancellation_under4h_minus4() {
        let deduction = store.recordConfirmedCancellation(hoursBeforeStart: 3, detail: "x")
        XCTAssertEqual(deduction, 4)
        XCTAssertEqual(store.score, 76)
        XCTAssertEqual(store.entries.first?.reason, "確認後取消")
    }

    func test_recordConfirmedCancellation_4hOrMore_noPenalty() {
        let deduction = store.recordConfirmedCancellation(hoursBeforeStart: 4, detail: "x")
        XCTAssertEqual(deduction, 0)
        XCTAssertEqual(store.score, 80)
    }
```

- [ ] **Step 1.4: 跑测试确认失败(方法不存在)**

Run: `xcodebuild test -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TennisMatchTests/CreditScoreStoreTests/test_recordConfirmedCancellation_under4h_minus4`
Expected: FAIL — `recordConfirmedCancellation` not found。

- [ ] **Step 1.5: 实现 `recordConfirmedCancellation`**

In `TennisMatch/Models/CreditScoreStore.swift`,在 `recordCancellation(...)` 之后插入:

```swift
    /// 已确认报名取消 — 仅当距开场不足 4 小时时扣 4 分;≥4h 不扣分。
    /// 与 `recordCancellation(hoursBeforeStart:)` 区分:后者用于 pending 撤回(tiered -1/-2)。
    /// 返回实际扣除的分数(绝对值),0 表示不扣分。
    @discardableResult
    func recordConfirmedCancellation(hoursBeforeStart: Double, detail: String) -> Int {
        guard hoursBeforeStart < 4 else { return 0 }
        let hours = max(0, Int(hoursBeforeStart.rounded(.down)))
        apply(
            delta: -4,
            reason: "確認後取消",
            detail: "\(detail) · 距開場 \(hours) 小時"
        )
        return 4
    }
```

- [ ] **Step 1.6: 跑两个 confirmed 测试都通过**

Run: `xcodebuild test -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TennisMatchTests/CreditScoreStoreTests`
Expected: 4 tests PASS。

- [ ] **Step 1.7: 写失败测试 — no-show 扣 5 分**

Append:

```swift
    func test_recordNoShow_minus5() {
        store.recordNoShow(detail: "x")
        XCTAssertEqual(store.score, 75)
        XCTAssertEqual(store.entries.first?.delta, -5)
    }
```

Run: `xcodebuild test ... -only-testing:TennisMatchTests/CreditScoreStoreTests/test_recordNoShow_minus5`
Expected: FAIL — 现行扣 10。

- [ ] **Step 1.8: 改 `recordNoShow` 扣分值**

In `TennisMatch/Models/CreditScoreStore.swift`,把:

```swift
    func recordNoShow(detail: String) {
        apply(delta: -10, reason: "爽約未到場", detail: detail)
    }
```

改为:

```swift
    /// 爽约未到场 — 扣 5 分。供后端考勤上报回来时调用。
    func recordNoShow(detail: String) {
        apply(delta: -5, reason: "爽約未到場", detail: detail)
    }
```

跑测试:Expected PASS。

- [ ] **Step 1.9: 写失败测试 — `canPublishMatch` / `isBanned` 派生属性**

Append:

```swift
    func test_canPublishMatch_thresholds() {
        let s70 = CreditScoreStore(score: 70, entries: [])
        XCTAssertTrue(s70.canPublishMatch, "= 70 仍可发起")

        let s69 = CreditScoreStore(score: 69, entries: [])
        XCTAssertFalse(s69.canPublishMatch, "< 70 不能发起")
    }

    func test_isBanned_below60() {
        let s60 = CreditScoreStore(score: 60, entries: [])
        XCTAssertFalse(s60.isBanned)

        let s59 = CreditScoreStore(score: 59, entries: [])
        XCTAssertTrue(s59.isBanned)
    }
```

Run: Expected FAIL — properties not found。

- [ ] **Step 1.10: 实现派生属性 + 注释更新**

In `TennisMatch/Models/CreditScoreStore.swift`:

把头部规则注释整块替换为:

```swift
//
//  CreditScoreStore.swift
//  TennisMatch
//
//  用户信誉积分(0-100)及变动历史。
//
//  规则(与 CreditScoreHistoryView 内的 rulesCard 对齐):
//    +1  完成一场约球
//    +1  获得球友好评
//    -1  pending 撤回(距开场 2-24 小时)
//    -2  pending 撤回(距开场不足 2 小时)
//    -4  已确认报名取消(距开场不足 4 小时)
//    -5  爽约未到场
//
//  账号处罚:
//    < 70  禁止发起约球(仍可报名他人发起的局)
//    < 60  封号 3 个月
//
//  Mock 阶段不持久化:重启 app 即恢复初始 score / entries。
//
```

把 thresholds 改为:

```swift
    /// `score < lowScoreThreshold` 时,UI 应展示提醒条幅。
    static let lowScoreThreshold = 60
    /// 信誉分低于此值 → 禁止发起约球。
    static let publishGateThreshold = 70
    /// 信誉分低于此值 → 封号 3 个月。
    static let banThreshold = 60
```

(保留 `freezeThreshold` 别名作为弃用 alias,见下一步以避免破坏 MyMatchesView。)

在 `isLowScore` 之后追加:

```swift
    /// 是否仍允许发起约球(< 70 → false)。
    var canPublishMatch: Bool { score >= CreditScoreStore.publishGateThreshold }

    /// 是否已封号(< 60 → true,三个月内禁所有写操作)。
    var isBanned: Bool { score < CreditScoreStore.banThreshold }
```

并保留旧名以免 MyMatchesView 编译失败:

```swift
    /// 已弃用别名 — 老代码在迁移期内仍引用 `freezeThreshold`,实际语义已改为「禁止发起约球」。
    @available(*, deprecated, renamed: "publishGateThreshold")
    static let freezeThreshold = publishGateThreshold
```

- [ ] **Step 1.11: 跑全部 CreditScoreStore 测试**

Run: `xcodebuild test -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:TennisMatchTests/CreditScoreStoreTests`
Expected: 7 tests PASS。

- [ ] **Step 1.12: Commit**

```bash
git add TennisMatch/Models/CreditScoreStore.swift TennisMatchTests/CreditScoreStoreTests.swift
git commit -m "feat(credit): tiered cancel/no-show rules + publish gate"
```

---

## Task 2: `BookingStore.softConflict(...)`

**Files:**

- Modify: `TennisMatch/Models/BookingStore.swift`
- Test: `TennisMatchTests/BookingStoreSoftConflictTests.swift` (create)

- [ ] **Step 2.1: 写失败测试 — pending 触发 soft,不触发 hard**

Create `TennisMatchTests/BookingStoreSoftConflictTests.swift`:

```swift
import XCTest
@testable import TennisMatch

@MainActor
final class BookingStoreSoftConflictTests: XCTestCase {

    var store: BookingStore!
    let userID = UUID()

    override func setUp() async throws {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        store = BookingStore(currentUserID: userID)
    }

    func test_pendingApplication_triggersSoftConflict_notHard() {
        let match = MockBuilders.match(requiresApproval: true)
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)

        let start = match.startDate.addingTimeInterval(60 * 30)   // 与原局重叠
        let end = start.addingTimeInterval(3600)

        XCTAssertNil(store.conflict(start: start, end: end), "pending 不应触发硬冲突")
        XCTAssertNotNil(store.softConflict(start: start, end: end), "pending 应触发软冲突")
    }
}
```

- [ ] **Step 2.2: 跑测试确认失败**

Run: `xcodebuild test ... -only-testing:TennisMatchTests/BookingStoreSoftConflictTests/test_pendingApplication_triggersSoftConflict_notHard`
Expected: FAIL — `softConflict` not found。

- [ ] **Step 2.3: 实现 `softConflict(...)`**

In `TennisMatch/Models/BookingStore.swift`,紧接 `func conflict(...)` 后插入:

```swift
    /// 软冲突 — 仅命中当前用户处于 `pendingReview` 状态的报名。返回值供 UI 提示
    /// 「该时段已有未审核报名,确认仍要提交?」。`pendingReview` 不算占名额,所以
    /// 不在 `conflict(...)` 里;但用户体验需要看见。
    func softConflict(start: Date, end: Date, excluding: UUID? = nil) -> ConflictHit? {
        for app in applications where app.applicantID == currentUserID && app.status == .pendingReview {
            guard app.matchID != excluding,
                  let m = matches[app.matchID] else { continue }
            let mEnd = m.startDate.addingTimeInterval(2 * 3600)
            if m.startDate < end && start < mEnd {
                return ConflictHit(id: app.matchID, label: "\(m.name) \(m.dateTimeDisplay)")
            }
        }
        return nil
    }
```

- [ ] **Step 2.4: 跑测试确认通过**

Run: same path
Expected: PASS。

- [ ] **Step 2.5: 写失败测试 — confirmed 仍走 hard,不出现在 soft**

Append:

```swift
    func test_confirmedApplication_triggersHard_notSoft() {
        let match = MockBuilders.match(requiresApproval: false)
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)
        // autoConfirmed 直接占位

        let start = match.startDate.addingTimeInterval(60 * 30)
        let end = start.addingTimeInterval(3600)

        XCTAssertNotNil(store.conflict(start: start, end: end))
        XCTAssertNil(store.softConflict(start: start, end: end))
    }

    func test_softConflict_excludingSelfMatch() {
        let match = MockBuilders.match(requiresApproval: true)
        store.registerMatch(match)
        _ = store.apply(to: match, now: MockBuilders.fixedNow)

        let start = match.startDate
        let end = start.addingTimeInterval(2 * 3600)

        XCTAssertNil(
            store.softConflict(start: start, end: end, excluding: match.id),
            "查自身 match 不应命中"
        )
    }
```

- [ ] **Step 2.6: 跑全部 SoftConflict 测试**

Run: `xcodebuild test ... -only-testing:TennisMatchTests/BookingStoreSoftConflictTests`
Expected: 3 tests PASS。

- [ ] **Step 2.7: Commit**

```bash
git add TennisMatch/Models/BookingStore.swift TennisMatchTests/BookingStoreSoftConflictTests.swift
git commit -m "feat(booking): softConflict query for pending overlaps"
```

---

## Task 3: HomeView 接 softConflict + 二次确认 alert

**Files:**

- Modify: `TennisMatch/Views/HomeView.swift`(`showSignUp(_:)` 附近 + 新 alert state)

- [ ] **Step 3.1: 在 HomeView 顶部 state 区(找已有 `@State private var conflictToast` 那块)新增 state**

```swift
    @State private var softConflictPending: (match: MockMatch, label: String)? = nil
```

(放在 `conflictToast` 声明附近即可。)

- [ ] **Step 3.2: 改 `showSignUp(_:)` — 软冲突走二次确认,而非直接进 sheet**

打开 `TennisMatch/Views/HomeView.swift:656`,把现有 `showSignUp` 的 conflict 检查段落:

```swift
        let range = matchTimeWindow(for: match)
        if let conflict = bookingStore.conflict(start: range.start, end: range.end, excluding: match.id) {
            conflictToast = L10n.string("該時段已與「\(conflict.label)」衝突,請先取消已預訂的時段")
            return
        }
```

替换为:

```swift
        let range = matchTimeWindow(for: match)
        if let conflict = bookingStore.conflict(start: range.start, end: range.end, excluding: match.id) {
            conflictToast = L10n.string("該時段已與「\(conflict.label)」衝突,請先取消已預訂的時段")
            return
        }
        if let soft = bookingStore.softConflict(start: range.start, end: range.end, excluding: match.id) {
            // pending 软冲突 — 弹二次确认,用户决定是否仍要海投。
            softConflictPending = (match: match, label: soft.label)
            return
        }
```

- [ ] **Step 3.3: 把"打开报名 sheet"逻辑拆成可复用 helper**

紧接 `showSignUp(_:)` 之后,加私有 helper:

```swift
    /// 实际触发报名 sheet — 假定冲突检查已通过(包括强制提交后调用)。
    private func presentSignUpSheet(for match: MockMatch) {
        let endDate = match.startDate.addingTimeInterval(2 * 3600)
        let date = AppDateFormatter.yearMonthDay.string(from: match.startDate)
        let startTime = AppDateFormatter.hourMinute.string(from: match.startDate)
        let endTime = AppDateFormatter.hourMinute.string(from: endDate)
        let timeRange = "\(startTime) - \(endTime)"

        signUpMatchId = match.id
        let newCount = match.currentPlayers + 1
        let playersStr = "\(newCount)/\(match.maxPlayers)"

        signUpMatch = SignUpMatchInfo(
            organizerName: match.name,
            organizerGender: match.gender,
            dateTime: "\(date)  \(timeRange)",
            location: match.location,
            matchType: match.matchType,
            ntrpRange: String(format: "%.1f-%.1f", match.ntrpLow, match.ntrpHigh),
            fee: match.fee,
            notes: "自帶球拍和球",
            players: playersStr,
            isFull: newCount >= match.maxPlayers,
            startDate: match.startDate,
            endDate: endDate,
            requiresApproval: match.requiresApproval
        )
    }
```

并把 `showSignUp(_:)` 末尾原来构造 `signUpMatch` 的整段(从 `let endDate = match.startDate.addingTimeInterval...` 到 `requiresApproval: match.requiresApproval)`)替换为:

```swift
        presentSignUpSheet(for: match)
```

- [ ] **Step 3.4: 在 mainBody 末端(已有 `.overlay(alignment: .top) { calendarToastBanner ... }` 之后,`.onAppear { ... }` 之前)挂 soft conflict alert**

```swift
        .alert(
            "時段衝突",
            isPresented: Binding(
                get: { softConflictPending != nil },
                set: { if !$0 { softConflictPending = nil } }
            ),
            presenting: softConflictPending
        ) { pending in
            Button("仍要報名", role: .destructive) {
                let m = pending.match
                softConflictPending = nil
                presentSignUpSheet(for: m)
            }
            Button("再想想", role: .cancel) {
                softConflictPending = nil
            }
        } message: { pending in
            Text("該時段已有未審核報名「\(pending.label)」。\n如發起人都接受,你會撞時段。確定仍要報名?")
        }
```

- [ ] **Step 3.5: build app,确认编译通过**

Run: `xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED。

- [ ] **Step 3.6: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "feat(signup): pending soft-conflict 二次确认"
```

---

## Task 4: HomeView 发布按钮加信用分门槛

**Files:**

- Modify: `TennisMatch/Views/HomeView.swift`(`+ 按钮` 触发处 line 97 + line 508)

- [ ] **Step 4.1: 找出现有 `+` 按钮的 action**

`TennisMatch/Views/HomeView.swift:97` 与 `:508` 处都有 `showCreateMatch = true`。把两处都改为调用一个新的 `tryShowCreateMatch()` helper。

- [ ] **Step 4.2: 加 helper(放在 `showSignUp` 附近)**

```swift
    /// 进入「发布约球」前先做信用分门槛检查。score < 70 → toast 拦截;不开 sheet。
    private func tryShowCreateMatch() {
        guard creditScoreStore.canPublishMatch else {
            conflictToast = L10n.string("信譽分 \(creditScoreStore.score) 分（< 70）暫不可發起約球")
            return
        }
        showCreateMatch = true
    }
```

- [ ] **Step 4.3: 替换两处调用**

`HomeView.swift:97` 与 `:508`,把:

```swift
showCreateMatch = true
```

改为:

```swift
tryShowCreateMatch()
```

(用 Edit 时注意 line 97 在抽屉之外的某个按钮内,line 508 在另一个按钮内 — 用 `replace_all` 安全。)

- [ ] **Step 4.4: build app,确认编译通过**

Run: `xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED。

- [ ] **Step 4.5: Commit**

```bash
git add TennisMatch/Views/HomeView.swift
git commit -m "feat(home): 信用分 < 70 拦截发起约球"
```

---

## Task 5: MyMatchesView — 取消按状态选扣分入口

**Files:**

- Modify: `TennisMatch/Views/MyMatchesView.swift`(line ~441-525 confirmed cancel block;line ~530-549 pending withdraw block)

- [ ] **Step 5.1: 在 confirmed 取消 block 把 `recordCancellation` 改为 `recordConfirmedCancellation`**

`MyMatchesView.swift:480` 附近,把:

```swift
                    let deduction = creditScoreStore.recordCancellation(
                        hoursBeforeStart: hoursToStart,
                        detail: "\(match.title) · \(match.location)"
                    )
```

改为:

```swift
                    // 已确认报名取消:< 4h 扣 4 分,≥ 4h 不扣分。
                    let deduction = creditScoreStore.recordConfirmedCancellation(
                        hoursBeforeStart: hoursToStart,
                        detail: "\(match.title) · \(match.location)"
                    )
```

并把扣分提示文案里的 "2/24 小時" 措辞校正为 "4 小時"。在 `MyMatchesView.swift:486` 附近 把:

```swift
                        notificationStore.push(MatchNotification(
                            type: .cancelled,
                            title: "信譽積分 -\(deduction)",
                            body: "距開場不足 \(hoursToStart < 2 ? "2" : "24") 小時取消，已扣除 \(deduction) 分信譽積分（當前 \(creditScoreStore.score) 分）",
                            time: "剛剛",
                            isRead: false
                        ))
```

改为:

```swift
                        notificationStore.push(MatchNotification(
                            type: .cancelled,
                            title: "信譽積分 -\(deduction)",
                            body: "距開場不足 4 小時取消已確認約球,已扣除 \(deduction) 分信譽積分（當前 \(creditScoreStore.score) 分）",
                            time: "剛剛",
                            isRead: false
                        ))
```

- [ ] **Step 5.2: 改账号处罚提示 — `freezeThreshold` 文案**

`MyMatchesView.swift:512-520` 附近,把:

```swift
                    if creditScoreStore.score < CreditScoreStore.banThreshold {
                        toast = .init(kind: .warning, text: L10n.string("信譽分低於 60，帳號已被永久封禁"))
                    } else if creditScoreStore.score < CreditScoreStore.freezeThreshold {
                        toast = .init(kind: .warning, text: L10n.string("信譽分低於 70，帳號將凍結 1 個月"))
                    } else if creditDeducted {
```

改为:

```swift
                    if creditScoreStore.score < CreditScoreStore.banThreshold {
                        toast = .init(kind: .warning, text: L10n.string("信譽分低於 60，帳號封禁 3 個月"))
                    } else if creditScoreStore.score < CreditScoreStore.publishGateThreshold {
                        toast = .init(kind: .warning, text: L10n.string("信譽分低於 70，暫不可發起約球"))
                    } else if creditDeducted {
```

- [ ] **Step 5.3: pending 撤回也走 tiered 扣分(line ~540 附近)**

`MyMatchesView.swift:538-543` 把:

```swift
            Button("確認撤回", role: .destructive) {
                if let aid = match.applicationID {
                    bookingStore.cancelApplication(aid)
                    toast = .init(kind: .success, text: L10n.string("已撤回申請"))
                }
                applicationToWithdraw = nil
            }
```

改为:

```swift
            Button("確認撤回", role: .destructive) {
                if let aid = match.applicationID {
                    let hoursToStart = match.startDate.timeIntervalSince(.now) / 3600
                    bookingStore.cancelApplication(aid)
                    let deduction = creditScoreStore.recordCancellation(
                        hoursBeforeStart: hoursToStart,
                        detail: "\(match.title) · \(match.location)"
                    )
                    if deduction > 0 {
                        toast = .init(kind: .warning, text: L10n.string("已撤回申請,扣 \(deduction) 分信譽"))
                    } else {
                        toast = .init(kind: .success, text: L10n.string("已撤回申請"))
                    }
                }
                applicationToWithdraw = nil
            }
```

- [ ] **Step 5.4: build,确认编译通过**

Run: `xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED(`freezeThreshold` 弃用 alias 仍可用,无 deprecation error;若开 `-warnings-as-errors`,把 5.2 的 `publishGateThreshold` 改名彻底替换 freezeThreshold 引用)。

- [ ] **Step 5.5: Commit**

```bash
git add TennisMatch/Views/MyMatchesView.swift
git commit -m "feat(my-matches): confirmed/pending 取消按状态扣分 + 文案对齐新阈值"
```

---

## Task 6: `CreditScoreHistoryView.rulesCard` 文案更新

**Files:**

- Modify: `TennisMatch/Components/CreditScoreHistoryView.swift`(line 68-106 `rulesCard`)

- [ ] **Step 6.1: 替换 rulesCard 内容**

`CreditScoreHistoryView.swift:68-101`,把整个 `rulesCard` 块替换为:

```swift
    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("積分規則")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)
            ruleRow(sign: "+", amount: "1", text: "完成一場約球")
            ruleRow(sign: "+", amount: "1", text: "獲得球友好評")
            ruleRow(sign: "-", amount: "1", text: "撤回報名(距開場 2-24 小時)")
            ruleRow(sign: "-", amount: "2", text: "撤回報名(距開場不足 2 小時)")
            ruleRow(sign: "-", amount: "4", text: "確認後取消(距開場不足 4 小時)")
            ruleRow(sign: "-", amount: "5", text: "爽約未到場")

            Divider().padding(.vertical, 4)
            Text("帳號處罰")
                .font(Typography.labelSemibold)
                .foregroundColor(Theme.textPrimary)
            HStack(spacing: Spacing.xs) {
                Text("< 70")
                    .font(Typography.captionMedium)
                    .foregroundColor(Theme.requiredText)
                    .frame(width: 40, alignment: .leading)
                Text("禁止發起約球(仍可報名)")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textBody)
            }
            HStack(spacing: Spacing.xs) {
                Text("< 60")
                    .font(Typography.captionMedium)
                    .foregroundColor(Theme.requiredText)
                    .frame(width: 40, alignment: .leading)
                Text("封號 3 個月")
                    .font(Typography.caption)
                    .foregroundColor(Theme.textBody)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
```

- [ ] **Step 6.2: build,确认编译通过**

Run: `xcodebuild -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16' build`
Expected: BUILD SUCCEEDED。

- [ ] **Step 6.3: Commit**

```bash
git add TennisMatch/Components/CreditScoreHistoryView.swift
git commit -m "docs(credit): rulesCard 对齐新阈值"
```

---

## Task 7: 全量回归 + 手动测试

- [ ] **Step 7.1: 跑全部测试**

Run: `xcodebuild test -scheme TennisMatch -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: ALL TESTS PASS。修复任何回归(尤其 `BookingStoreApprovalTests` 与 `BookingStoreWaitlistTests` 不应受影响,因为 `conflict(...)` 行为未变)。

- [ ] **Step 7.2: 手动 UX 测试 checklist(在模拟器跑)**

按以下场景逐条验证:

1. 报名 A 局(requiresApproval=true)→ 进入 pending → 报名同时段 B 局 → 出现「該時段已有未審核報名」二次确认 alert,点「仍要報名」可继续。
2. 接受 A 局后(转 confirmed)→ 报名同时段 B 局 → 直接红色 toast 拦截。
3. 在「我的約球」距开场 3 小时取消 confirmed → toast「扣 4 分信譽」+ 通知出现。
4. 距开场 5 小时取消 confirmed → 不扣分,绿色 toast「已通知所有參與者」。
5. 撤回 pending 申请,距开场 < 2 小时 → toast「扣 2 分信譽」。
6. 把 `CreditScoreStore` 初始 score 临时改为 65 跑 app → 首页 `+` 按钮 toast「信譽分 65 分(< 70) 暫不可發起約球」,sheet 不打开。复原 score 默认。
7. ProfileView → 信譽積分 → 检查 rulesCard 文案与新规则一致。

- [ ] **Step 7.3: Commit 任何收尾(若有)**

如手动测试发现需要微调,合并到对应任务的 commit;否则跳过。

---

## Self-Review Notes

- **Spec 覆盖**:
  - § pending 软占用 → Task 2 + Task 3
  - § confirmed 硬占用 → 现有 `conflict(...)` 已实现,Task 7 验收
  - § confirmed <4h 取消扣分 → Task 1 + Task 5
  - § no-show 扣分 → Task 1
  - § <60 高级局禁报 → **跳过**(用户决策)
- **裁剪决策**:
  - 罚分降级到 `-4 / -5`(用户嫌 -10/-30 太重)
  - 新阈值语义:`< 70` 限发起,`< 60` 封 3 月(替代旧 freeze 1 月 / 永封)
  - 「高级局/认证发起人」整段不实现
- **风险点**:
  - `freezeThreshold` 改为 deprecated alias — 若 CI 把 deprecation 当 error 会断;build 步骤已包含。如需彻底干净,Task 5.2 已把 `MyMatchesView` 引用换成 `publishGateThreshold`,实际已无活跃引用,可后续清理 alias。
  - 软冲突 alert 使用 `Binding(get/set)` + `presenting:`,SwiftUI 16+ OK。
  - `MockMatch` 时长固定 2 小时,与 `BookingStore.conflict` 保持一致 — `softConflict` 同一假设。
