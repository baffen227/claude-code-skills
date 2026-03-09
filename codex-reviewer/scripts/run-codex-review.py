#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# ///
"""Assemble Codex review reports from code and/or doc review results."""

import argparse
import datetime
import sys
from pathlib import Path

MODE_LABEL = {
    "code": "程式碼",
    "doc": "文件",
    "mixed": "混合",
}


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Assemble a Codex review report from review result files."
    )
    parser.add_argument(
        "--mode",
        required=True,
        choices=["code", "doc", "mixed"],
        help="Review mode: code, doc, or mixed",
    )
    parser.add_argument(
        "--subject",
        required=True,
        help="Descriptive name for the report (e.g. auth-refactor)",
    )
    parser.add_argument(
        "--output-dir",
        default="docs/reviews/",
        help="Directory to write the report (default: docs/reviews/)",
    )
    parser.add_argument(
        "--code-input",
        default="/tmp/codex-code-review.txt",
        help="Path to code review results (default: /tmp/codex-code-review.txt)",
    )
    parser.add_argument(
        "--doc-input",
        default="/tmp/codex-doc-review.txt",
        help="Path to doc review results (default: /tmp/codex-doc-review.txt)",
    )
    args = parser.parse_args()

    code_input = Path(args.code_input)
    doc_input = Path(args.doc_input)

    # Input validation
    if args.mode in ("code", "mixed") and not code_input.is_file():
        print(f"Error: code review input not found: {code_input}", file=sys.stderr)
        sys.exit(1)
    if args.mode in ("doc", "mixed") and not doc_input.is_file():
        print(f"Error: doc review input not found: {doc_input}", file=sys.stderr)
        sys.exit(1)

    today = datetime.date.today().isoformat()
    scope = MODE_LABEL[args.mode]

    # Build report
    lines = [
        f"# Codex Review: {args.subject}",
        f"- **日期**：{today}",
        f"- **範圍**：{scope}",
        f"- **模式**：{args.mode}",
        "",
        "---",
        "",
    ]

    if args.mode in ("code", "mixed"):
        lines.append("## 程式碼審查結果")
        lines.append(code_input.read_text(encoding="utf-8"))
        lines.append("")

    if args.mode in ("doc", "mixed"):
        lines.append("## 文件審查結果")
        lines.append(doc_input.read_text(encoding="utf-8"))
        lines.append("")

    report = "\n".join(lines)

    # Write output
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / f"{today}-{args.subject}.md"
    output_path.write_text(report, encoding="utf-8")

    print(output_path)


if __name__ == "__main__":
    main()
