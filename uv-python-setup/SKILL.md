---
name: uv-python-setup
description: Initialize Python uv development environment in any repository. Use when user says "初始化 Python 環境", "設定 uv", "setup python", or when another skill needs a Python environment. Sets up uv, pyproject.toml, project structure (scripts/, tests/), and updates CLAUDE.md with Python conventions. Optionally configures ruff linter/formatter and pre-commit hooks.
---

# uv-python-setup

Initialize a Python development environment using uv in the current repository.

## Phase 1: Core (Auto-execute)

Run all steps in this phase automatically without asking the user.

### 1. Ensure uv is installed

Check if `uv` is available:

```bash
which uv
```

If not found, install it:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

After installation, verify it succeeded:

```bash
uv --version
```

### 2. Initialize project

Check if `pyproject.toml` exists in the repository root. If it does not exist, run:

```bash
uv init
```

### 3. Create project directories

Create `scripts/` directory if it does not exist:

```bash
mkdir -p scripts/
```

Create `tests/` directory if it does not exist:

```bash
mkdir -p tests/
```

### 4. Update CLAUDE.md with Python conventions

Check if `CLAUDE.md` exists in the repository root. If it does not exist, create it. Then check whether it already contains a `## Python 開發環境` section. If the section is missing, append the following block to the end of `CLAUDE.md`:

```markdown
## Python 開發環境

- **套件管理**：使用 `uv`（不使用 pip/venv）
- **新增依賴**：`uv add <package>`（開發依賴加 `--dev`）
- **執行腳本**：`uv run python scripts/<name>.py`
- **執行測試**：`uv run pytest tests/`
- **腳本目錄**：`scripts/`
- **測試目錄**：`tests/`
```

Do not duplicate the section if it already exists.

## Phase 2: Optional (Interactive)

Ask the user before executing each step in this phase.

### 5. Ruff linter/formatter

Ask the user: **"要不要設定 ruff 作為 linter/formatter？"**

If yes:

1. Add ruff as a dev dependency:

   ```bash
   uv add --dev ruff
   ```

2. Add `[tool.ruff]` configuration to `pyproject.toml`. Consult `references/ruff-config.md` for the recommended configuration template and apply it.

### 6. Pre-commit hooks

Ask the user: **"要不要設定 pre-commit hooks？"**

If yes:

1. Add pre-commit as a dev dependency:

   ```bash
   uv add --dev pre-commit
   ```

2. Create `.pre-commit-config.yaml` in the repository root. Consult `references/ruff-config.md` for the pre-commit configuration template.

## Phase 3: Finalize (Auto-execute)

Run all steps in this phase automatically.

### 7. Sync environment

Run `uv sync` to install all dependencies and verify the environment works:

```bash
uv sync
```

### 8. Display summary

Print a summary of what was set up, including:

- Whether uv was freshly installed or already present
- Whether `pyproject.toml` was created or already existed
- Whether `scripts/` and `tests/` directories were created
- Whether CLAUDE.md was updated
- Whether ruff was configured (if chosen)
- Whether pre-commit was configured (if chosen)

## Additional Resources

- `references/ruff-config.md` — Contains the recommended `[tool.ruff]` configuration for `pyproject.toml` and the `.pre-commit-config.yaml` template. Consult this file when the user opts in to ruff or pre-commit setup.
