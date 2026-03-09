# uv-python-setup Skill 設計文件

> **部署位置**：`~/.claude/skills/uv-python-setup/`（全域，跨倉庫使用）
> **設計日期**：2026-03-09
> **Skill 名稱**：`uv-python-setup`

## 概述

一個全域 Claude Code Skill，用於在任何倉庫初始化 Python uv 開發環境。核心步驟自動執行，可選項目互動詢問。

## 檔案結構

```
uv-python-setup/
├── SKILL.md              # 核心指令與流程
└── references/
    └── ruff-config.md    # ruff 預設設定模板與說明
```

## 觸發條件

- 使用者說「初始化 Python 環境」、「設定 uv」、「setup python」
- 被其他 skill 前置引用（如 codex-reviewer 偵測到沒有 uv 時建議觸發）

## 執行流程

### 第一階段：核心（自動執行）

1. 檢查 uv 是否已安裝
   - 已安裝 → 跳過，顯示版本
   - 未安裝 → 執行 `curl -LsSf https://astral.sh/uv/install.sh | sh`
2. 檢查 `pyproject.toml` 是否存在
   - 已存在 → 跳過，顯示摘要
   - 不存在 → 執行 `uv init`
3. 建立專案結構（若不存在）
   - `scripts/`
   - `tests/`
4. 更新 CLAUDE.md 加入 Python 慣例區塊

### 第二階段：可選（互動詢問）

5. 「要不要設定 ruff 作為 linter/formatter？」
   - 是 → `uv add --dev ruff`，寫入 `pyproject.toml` `[tool.ruff]` 設定
6. 「要不要設定 pre-commit hooks？」
   - 是 → `uv add --dev pre-commit`，建立 `.pre-commit-config.yaml`（含 ruff hook）

### 第三階段：收尾（自動執行）

7. 執行 `uv sync` 確認環境正常
8. 顯示摘要：已完成的設定項目清單

## CLAUDE.md 更新模板

自動在 CLAUDE.md 中追加：

```markdown
## Python 開發環境

- **套件管理**：使用 `uv`（不使用 pip/venv）
- **新增依賴**：`uv add <package>`（開發依賴加 `--dev`）
- **執行腳本**：`uv run python scripts/<name>.py`
- **執行測試**：`uv run pytest tests/`
- **腳本目錄**：`scripts/`
- **測試目錄**：`tests/`
```
