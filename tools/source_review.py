"""Read-only source review helpers; derived images go to tmp/source-review."""
import argparse
import sys
from pathlib import Path
from zipfile import ZipFile
from xml.etree import ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
sys.stdout.reconfigure(encoding="utf-8")
SOURCE = ROOT.parents[1]
parser = argparse.ArgumentParser()
sub = parser.add_subparsers(dest="command", required=True)
paragraphs = sub.add_parser("paragraphs")
paragraphs.add_argument("start", type=int)
paragraphs.add_argument("end", type=int)
crop = sub.add_parser("crop")
crop.add_argument("number", type=int)
crop.add_argument("box", nargs=4, type=int)
args = parser.parse_args()
if args.command == "paragraphs":
    with ZipFile(SOURCE / "异数改编项目策划案.docx") as archive:
        tree = ET.fromstring(archive.read("word/document.xml"))
    ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
    for index, paragraph in enumerate(tree.findall(".//w:body//w:p", ns)):
        if args.start <= index < args.end:
            text = "".join(t.text or "" for t in paragraph.findall(".//w:t", ns))
            if text:
                print(f"{index}: {text}")
else:
    from PIL import Image
    output = ROOT / "tmp/source-review"
    output.mkdir(parents=True, exist_ok=True)
    target = output / f"flow-{args.number}-{'-'.join(map(str, args.box))}.png"
    with Image.open(SOURCE / f"whiteboard_exported_image ({args.number}).png") as original:
        original.crop(tuple(args.box)).save(target)
    print(target)
