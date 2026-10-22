from __future__ import annotations

import re
import sys
import argparse
from zipfile import ZipFile
from xml.etree import ElementTree
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[2]
SOURCE_PATH = PROJECT_ROOT / "docs" / "游戏流程.md"
DIALOGUE_ROOT = PROJECT_ROOT / "assets" / "dialogues"

NAME_REPLACEMENTS = {
    "夏中清": "钟歧",
    "夏月": "钟岳",
    "苏溟玖": "林玖",
    "穆暌信": "穆执",
    "松林夕": "周崇安",
}

IGNORED_PREFIXES = (
    "#",
    "label ",
    "jump ",
    "if ",
    "elif ",
    "else",
    "set ",
    "do ",
    "signal ",
    "join ",
    "leave ",
    "update ",
    "background ",
    "music ",
    "sound ",
    "style ",
    "wait ",
    "return",
)


def normalize(value: str) -> str:
    for old_name, new_name in NAME_REPLACEMENTS.items():
        value = value.replace(old_name, new_name)
    value = value.replace("{PlayerName}", "玩家名")
    value = value.replace("[PlayerName]", "玩家名")
    value = re.sub(r"\[[^\]]*\]", "", value)
    value = re.sub(r"[\s\u3000]", "", value)
    value = re.sub(r"[，。！？；：、,.!?;:'\"“”‘’…—·（）()《》【】\[\]<>\\]", "", value)
    return value.casefold()


def iter_visible_entries(path: Path):
    for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        stripped = raw_line.strip()
        if not stripped or stripped.startswith(IGNORED_PREFIXES):
            toast_match = re.search(r"ToastManager\.show_notice\(\"([^\"]+)\"", stripped)
            if toast_match:
                yield line_number, toast_match.group(1)
            continue
        if stripped in {"{", "}"}:
            continue
        if stripped.startswith("-"):
            stripped = stripped[1:].split("|", 1)[0].strip()
        elif re.match(r"^[A-Za-z0-9_]+\s*:", stripped):
            stripped = stripped.split(":", 1)[1].strip()
        if not stripped:
            continue
        yield line_number, stripped


def read_source(path: Path) -> str:
    if path.suffix.lower() != ".docx":
        return path.read_text(encoding="utf-8")
    with ZipFile(path) as archive:
        document = ElementTree.fromstring(archive.read("word/document.xml"))
    namespace = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
    return "\n".join(
        "".join(node.itertext())
        for node in document.findall(".//w:t", namespace)
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare dialogue with planning text; image-only flowcharts still need manual review.")
    parser.add_argument("--source", action="append", type=Path)
    parser.add_argument("--limit", type=int, default=30, help="Maximum unmatched entries shown, 0 for all")
    args = parser.parse_args()
    source = "\n".join(read_source(path) for path in (args.source or [SOURCE_PATH]))
    normalized_source = normalize(source)
    failures: list[tuple[Path, int, str]] = []
    checked = 0

    for timeline_path in sorted(DIALOGUE_ROOT.rglob("*.dtl")):
        for line_number, text in iter_visible_entries(timeline_path):
            normalized_text = normalize(text)
            if len(normalized_text) < 2:
                continue
            checked += 1
            if normalized_text not in normalized_source:
                failures.append((timeline_path, line_number, text))

    print(f"checked={checked} unmatched={len(failures)}")
    shown = failures if args.limit == 0 else failures[:args.limit]
    for path, line_number, text in shown:
        relative_path = path.relative_to(PROJECT_ROOT)
        print(f"{relative_path}:{line_number}: {text}")
    if len(shown) < len(failures):
        print(f"... {len(failures) - len(shown)} additional entries; use --limit 0 to list all.")
    print("Image-only dialogue branches are not included in this automated text comparison.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
