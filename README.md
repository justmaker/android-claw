# 🤖 AndroidClaw

**AI Agent for Android** — 手機上的全功能 AI 助手，支援多 Provider、MCP 工具協議、檔案操作、Skill 系統。

> 解決一個問題：主流 AI app（Claude/ChatGPT/Gemini）在手機上不能操作檔案、不支援 MCP、只接自家 Provider。AndroidClaw 全部都能做。

---

## ✨ 特色

- 🔌 **多 Provider** — Anthropic (Claude)、GitHub Copilot、OpenAI (ChatGPT)，一個 app 全接
- 🛠️ **Tool System** — 標準 OpenAI function calling，讀寫檔案、搜尋網路、拍照、定位
- 🔗 **MCP 支援** — Model Context Protocol，連接外部工具生態
- 📱 **Phone-native** — 不是把 server 塞進手機，而是為手機重新設計的 AI agent
- 🔒 **4 級安全** — L0 自動 → L1 授權 → L2 確認 → L3 生物辨識
- ✨ **Skill 系統** — 內建 + 社群 + 自建，結構化的 AI 能力包

## 🏗️ 架構

```
UI Layer          — Flutter (Chat/Files/Skills/Settings)
Session Layer     — 多對話管理 + Context budget + Memory
Brain Layer       — Provider Router (GHC/Claude/OpenAI)
Action Layer      — Unified Tool Registry (native + MCP + skill)
Security Layer    — 4 級權限 × 3 種信任 Profile
Platform Layer    — Android 能力抽象 (檔案/相機/GPS/麥克風)
```

詳細架構文件：[`docs/architecture.md`](docs/architecture.md)

## 📋 技術決定

| 項目 | 決定 |
|------|------|
| 框架 | **Flutter (Dart)** — 未來可跨 iOS |
| 目標 Android | **API 35/36 (Android 15/16)** |
| Provider | Anthropic + GitHub Copilot + OpenAI |
| MCP Transport | SSE (localhost) |
| 本地 LLM | 不做（純雲端） |
| 認證 | OS 瀏覽器 OAuth (Custom Tabs) |
| 與 OpenClaw 關係 | 完全獨立 |
| 發佈 | GitHub APK（Google Play 之後再說） |

## 🗓️ 開發計畫

| Phase | 時間 | 目標 |
|-------|------|------|
| **0 — Skeleton** | 第 1 週 | Flutter 專案 + Chat UI + GHC 對話 |
| **1 — Tool System** | 第 2-4 週 | Tool 框架 + 檔案操作 + 3 Provider |
| **2 — MCP + Skills** | 第 4-8 週 | MCP Client + Skill Engine |
| **3 — Polish** | 第 8-12 週 | 多媒體 + Memory + 語音 + Share Intent |

## 🛠️ 技術棧

| 層級 | 技術 |
|------|------|
| 語言 | Dart |
| UI | Flutter |
| 網路 | dio |
| 資料庫 | sqflite / drift |
| 背景任務 | workmanager |
| JSON | json_serializable / freezed |
| DI | riverpod / get_it |
| OAuth | flutter_appauth |
| MCP | 自建 MCP client (SSE) |

## 📄 文件

- [架構文件](docs/architecture.md) — 六層堆疊詳細設計
- [可行性分析](docs/feasibility.md) — 市場調查、技術挑戰、路線選擇

## 📦 安裝

> 開發中，尚未釋出 APK。

## 📜 License

MIT
