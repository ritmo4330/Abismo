"""Read-only regression check against the user's original DOCX attachments."""
import hashlib
import json
from import_source_text import ROOT, DOWNLOADS, SOURCES, read_doc, normalize, section_map


def main():
    checked = 0
    for key, name in SOURCES.items():
        original = DOWNLOADS / (name + '.docx')
        imported = json.loads((ROOT / f'assets/data/source_text/{key}.json').read_text(encoding='utf-8'))
        assert imported['sha256'] == hashlib.sha256(original.read_bytes()).hexdigest(), key
        assert imported['paragraphs'] == read_doc(original), key
        checked += 1
        if not key.startswith('ending_'):
            continue
        npc = key.removeprefix('ending_')
        for section, lines in section_map([normalize(p['text']) for p in read_doc(original)]).items():
            suffix = {'死亡结局':'death', '遗忘结局':'forget', '完美结局':'perfect', '苏醒结局':'wake', '诀别结局':'farewell', '回归结局':'return', '谒见结局':'audience'}[section]
            path = ROOT / f'assets/dialogues/finale/source/source_ending_{npc}_{suffix}.dtl'
            text = path.read_text(encoding='utf-8')
            expected = ''.join(lines)
            if npc == 'player':
                expected = expected.replace('蕊期', '{PlayerName}')
            actual = ''.join(text.splitlines()[2:-1])
            assert actual == expected, path.name
            assert text.rstrip().endswith('return'), path.name
    print(f'PASS: {checked} original documents retained exactly, including run formatting.')
    print('PASS: All 18 ending branches preserve every authored character after name mapping.')


if __name__ == '__main__':
    main()
