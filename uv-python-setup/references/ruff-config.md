# Ruff Configuration Reference

## pyproject.toml — `[tool.ruff]` section

Add the following to `pyproject.toml`:

```toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = [
    "E",    # pycodestyle errors
    "W",    # pycodestyle warnings
    "F",    # pyflakes
    "I",    # isort
    "UP",   # pyupgrade
    "B",    # flake8-bugbear
    "SIM",  # flake8-simplify
    "RUF",  # ruff-specific rules
]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

## .pre-commit-config.yaml

Create `.pre-commit-config.yaml` in the repository root with the following content:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.10
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

After creating the file, install the hooks:

```bash
uv run pre-commit install
```
