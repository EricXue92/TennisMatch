# P1 Fixes Batch 2 — Data Flow, State & UX Fixes

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 13 more P1 issues — data persistence, hardcoded values, fake features, and interaction conflicts.

**Architecture:** Each task is independent.

**Tech Stack:** Swift / SwiftUI / iOS 17+ / `@Observable`

---

### Task 1: Fix hardcoded "明天" date label in MyMatchesView
Module 3 — MyMatchesView.swift:866 — dateLabel hardcoded as "明天 · 04/23（三）"

### Task 2: Wire tournament follow button to FollowStore
Module 6 — TournamentView.swift:308 — local @State isFollowing doesn't sync with FollowStore

### Task 3: Fix hardcoded organizer gender in TournamentView DM
Module 6 — TournamentView.swift:359 — "♂" and Theme.genderMale hardcoded

### Task 4: Save EditProfileView preferences to UserStore
Module 5 — EditProfileView.swift — partnerLevelLow/High and preferredSlots not saved

### Task 5: Add unsaved changes warning to EditProfileView
Module 5 — EditProfileView.swift — back button discards changes without confirmation

### Task 6: Fix card tap vs signup button conflict in HomeView
Module 2 — HomeView.swift:931 — onTapGesture on card conflicts with internal signup button

### Task 7: Fix hardcoded phone number in SettingsView
Module 7 — SettingsView.swift:95 — "+86 138****8888" hardcoded

### Task 8: Update tournament signup to reflect in participant count
Module 6 — TournamentView.swift — signup doesn't update participants or playerList

### Task 9: Fix chat actions (exit/delete/block) to actually work
Module 4 — ChatDetailView.swift — exit/delete/block only dismiss without removing data

### Task 10: Fix hardcoded user profile in ChatDetailView
Module 4 — ChatDetailView.swift — viewing counterpart profile uses hardcoded PublicPlayerData

### Task 11: Fix disabled chat menu items
Module 4 — ChatDetailView.swift:176-179 — "查看約球詳情" and "查看群成員" disabled but still clickable

### Task 12: Make "編輯約球" and "關閉報名" functional stubs
Module 3 — MyMatchesView.swift:239-246 — show "即將推出" but should have better UX

### Task 13: Fix reviews not writing to RatingFeedbackStore
Module 7 — ReviewsView.swift — submitted reviews don't affect the rating system
