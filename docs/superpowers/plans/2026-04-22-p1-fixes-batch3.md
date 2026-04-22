# P1 Fixes Batch 3 — Remaining Targeted Fixes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 8 remaining targeted P1 issues — loading states, UI consistency, fake data, missing features.

**Architecture:** Each task is independent.

**Tech Stack:** Swift / SwiftUI / iOS 17+ / `@Observable`

---

### Task 1: Add loading states to auth pages
Module 1 — PhoneInputView, PhoneVerificationView, EmailRegisterView, RegisterView — no ProgressView or loading indicator on any action button. Users get no visual feedback after tapping "發送驗證碼" / "驗證並登入" / "註冊".

### Task 2: Replace Tab Bar Emoji with SF Symbols
Module 2 — HomeView tab bar uses 🎯🗓💬👤 emoji which can't support selected/unselected states and VoiceOver reads emoji names. Replace with SF Symbols.

### Task 3: Fix court picker single-select mode
Module 3 — CreateMatchView.swift:79-84 — CourtPickerView is multi-select but only the first selection is used. Should restrict to single-select or at least make the UX clear.

### Task 4: Show actual signup data in registrant list
Module 3 — MyMatchesView registrant list shows hardcoded names regardless of which match. Should reflect the match's actual player data.

### Task 5: Add write review button to completed matches
Module 3 — CompletedMatchReviewSheet is display-only, no "寫評論" button. Breaks the rating system feedback loop.

### Task 6: Make PublicPlayerData consistent across pages
Module 5 — PublicPlayerData is hardcode-constructed in 4+ places (FollowingView, FollowerListView, MutualFollowListView, ChatDetailView) with inconsistent values (reputation 85/88/90). Should use mock player lookup.

### Task 7: Use multi-line input for tournament rules
Module 6 — CreateTournamentView.swift:413 — Rules input uses single-line TextField. Should use TextEditor or vertical-axis TextField for multi-line input.

### Task 8: Extract shared signup confirm/success views
Module 2 — SignUpConfirmSheet (HomeView) vs SignUpConfirmSheetForDetail (MatchDetailView) and SignUpSuccessView vs SignUpSuccessViewForDetail are near-identical duplicates. Extract into shared components.
