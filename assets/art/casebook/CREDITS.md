# Casebook materials

## Actual assets used

- `ZhuqueFangsong-Regular.ttf`: 朱雀仿宋 (Zhuque Fangsong), TrionesType, v0.212, SIL Open Font License 1.1. Distributed with `ZhuqueFangsong-OFL.txt`. Official source: https://github.com/TrionesType/zhuque ; release: https://github.com/TrionesType/zhuque/releases/tag/v0.212 . Primary paper-interface typeface, based on historical movable-type letterforms. This release is a technical preview; Noto Serif SC remains a fallback for glyph coverage.
- `NotoSerifSC-Variable.ttf`: Noto Serif Simplified Chinese, SIL Open Font License 1.1. Distributed with `NotoSerifSC-OFL.txt`. Source: https://github.com/google/fonts/tree/main/ofl/notoserifsc . Retained as a missing-glyph fallback; no proprietary system fonts redistributed.

- `paper-scan-810-cc0.jpg`: **Old paper sheet texture**, author 810 / Yael Atletl Bueno Rojas. CC0. Source: https://opengameart.org/content/old-paper-sheet-texture ; original download: https://opengameart.org/sites/default/files/paper.jpg . A real document scan with erased text. Original source file retained unmodified; engine samples the blank center region with mipmapped filtering.
- `parchment-cron-cc0.png`: **Old Parchment Paper**, author cron. CC0. Source: https://opengameart.org/content/old-parchment-paper ; original download: https://opengameart.org/sites/default/files/parchment_alpha.png . Kept as a source alternative; not currently displayed.

## Assembly

The game renders the document scan into irregular paper outlines, overlapping sheets, a two-page journal with a spine, and pinned topic ribbons. The map is native interactive architectural linework; icons and ornamental lines are original code-native UI elements. No screenshot crops, characters, logos or text from the reference game are included.

The attempted built-in image generation failed repeatedly due to network errors. CLI/API fallback was authorized but cannot run because OPENAI_API_KEY is not configured locally. This delivered material pass uses licensed scanned textures and engine composition, not successful AI generation. No API fees incurred.
