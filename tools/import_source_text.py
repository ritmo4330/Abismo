"""Import authored DOCX text without paraphrasing; source documents remain untouched."""
import argparse
import hashlib
import json
import re
from pathlib import Path
from xml.etree import ElementTree as ET
from zipfile import ZipFile

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = Path('C:/Users/LEGION/Downloads')
NS = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
W = '{' + NS['w'] + '}'
ALIASES = {'穆暌信': '穆执', '松林夕': '周崇安', '苏溟玖': '林玖', '夏中清': '钟歧', '夏月': '钟岳', '苏姐姐': '林姐姐', '松院长': '周院长', '松叔叔': '周叔叔'}
SOURCES = {
    'ending_player': '结局·蕊期', 'ending_mu': '结局·穆暌信',
    'ending_zhou': '结局·松林夕', 'ending_lin': '结局·苏溟玖',
    'ending_wu': '结局·乌停湘', 'ending_zhong': '结局·夏中清',
    'past_zhou': '松林夕·往日', 'past_lin': '苏溟玖·往日',
    'past_wu': '乌停湘·往日', 'past_zhong': '夏中清·往日',
    'nightmare_mu': '穆执·梦魇', 'nightmare_zhou': '周崇安·梦魇',
    'nightmare_lin': '林玖·梦魇', 'nightmare_zhong': '钟歧·梦魇',
    'note_pages': '笔记残页', 'dream_notes': '梦境笔记',
    'cycle_notes': '轮回笔记', 'letter': '林羽的回信',
    'rules_meta': '梦境规则·梅塔研究所', 'rules_zhou': '梦境规则·周崇安研究所',
}

def normalize(text):
    for before, after in ALIASES.items():
        text = text.replace(before, after)
    return text

def read_doc(path):
    with ZipFile(path) as archive:
        tree = ET.fromstring(archive.read('word/document.xml'))
    result = []
    for p in tree.findall('.//w:body//w:p', NS):
        runs = []
        for r in p.findall('.//w:r', NS):
            text = ''.join(t.text or '' for t in r.findall('.//w:t', NS))
            props = r.find('w:rPr', NS)
            run = {'text': text}
            if props is not None:
                for tag in ('u', 'shd', 'highlight', 'color', 'vanish', 'strike'):
                    el = props.find('w:' + tag, NS)
                    if el is not None:
                        run[tag] = {k.split('}')[-1]: v for k, v in el.attrib.items()}
            runs.append(run)
        result.append({'text': ''.join(r['text'] for r in runs), 'runs': runs})
    return result

def content(key):
    return [normalize(p['text']) for p in read_doc(DOWNLOADS / (SOURCES[key] + '.docx'))]

def section_map(lines):
    result, current = {}, None
    for line in lines:
        if line.startswith('·'):
            current = line[1:].strip()
            result[current] = []
        elif current and line.strip():
            result[current].append(line)
    return result

def chunks(text, limit=145):
    # Preserve every character. Only add dialogue-page boundaries at punctuation.
    while len(text) > limit:
        cuts = [m.end() for m in re.finditer('[。！？；]', text[:limit])]
        cut = cuts[-1] if cuts else limit
        yield text[:cut]
        text = text[cut:]
    if text:
        yield text

def literal(text):
    return json.dumps(text, ensure_ascii=False)

def timeline(lines):
    return '[style name="plain_text"]\nleave --All--\n' + '\n'.join(part for line in lines if line.strip() for part in chunks(line)) + '\n[end_timeline]\n'

def build():
    out = ROOT / 'assets/data/source_text'
    out.mkdir(parents=True, exist_ok=True)
    manifest = {}
    for key, name in SOURCES.items():
        path = DOWNLOADS / (name + '.docx')
        paragraphs = read_doc(path)
        data = {'source': name + '.docx', 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'paragraphs': paragraphs}
        (out / (key + '.json')).write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        manifest[key] = {'source': data['source'], 'sha256': data['sha256'], 'paragraphs': len(paragraphs)}
        if key.startswith('ending_'):
            npc = key.removeprefix('ending_')
            directory = ROOT / 'assets/dialogues/finale/source'
            directory.mkdir(parents=True, exist_ok=True)
            for section, lines in section_map(content(key)).items():
                suffix = {'死亡结局':'death','遗忘结局':'forget','完美结局':'perfect','苏醒结局':'wake','诀别结局':'farewell','回归结局':'return','谒见结局':'audience'}[section]
                # The protagonist's authoring name is not the user's chosen name.
                if npc == 'player':
                    lines = [line.replace('蕊期', '{PlayerName}') for line in lines]
                (directory / f'source_ending_{npc}_{suffix}.dtl').write_text(timeline(lines).replace('[end_timeline]', 'return'), encoding='utf-8')
        if key.startswith('nightmare_'):
            directory = ROOT / 'assets/dialogues/source'
            directory.mkdir(parents=True, exist_ok=True)
            (directory / f'source_{key}.dtl').write_text(timeline(content(key)[1:]), encoding='utf-8')
    (out / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f'Imported {len(manifest)} original documents; no source DOCX modified.')

if __name__ == '__main__':
    import sys
    sys.stdout.reconfigure(encoding='utf-8')
    parser = argparse.ArgumentParser()
    parser.add_argument('key', nargs='?')
    parser.add_argument('start', type=int, nargs='?', default=0)
    parser.add_argument('end', type=int, nargs='?', default=9999)
    args = parser.parse_args()
    if args.key:
        for i, p in enumerate(read_doc(DOWNLOADS / (SOURCES[args.key] + '.docx'))):
            if args.start <= i < args.end:
                print(f'{i}: {p["text"]}')
    else:
        build()
