"""Idempotent propagation of verified source topics; never invent dialogue.

Run after changing an inherited first/second/third-round source menu. The two
identity corrections are explicitly authorized by the user on 2026-10-22.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DIALOGUES = ROOT / "assets/dialogues"
SPEAKERS = {"zhou": "zhou_chong_an", "lin": "lin_jiu", "wu": "wu_ting_xiang", "zhong": "zhong_qi"}


def repair_text(text, npc):
    if npc in SPEAKERS and "- 来到别墅的原因" not in text:
        original = (DIALOGUES / f"ch1_snow_villa/1_6_{npc}.dtl").read_text(encoding="utf-8-sig")
        start = original.index("- 来到别墅的原因")
        end = original.index("- 与死者的关系", start)
        text = text.replace("- 与死者的关系", original[start:end] + "- 与死者的关系", 1)
    if npc == "wu":
        text = text.replace("{Ch1.NPCIntro.Wu.Selected2} == true and {Ch1.PrivateChat.Wu.Removed.AnomalySociety}",
                            "{Ch1.PrivateChat.Wu.Asked.Arrival} == true and {Ch1.PrivateChat.Wu.Removed.AnomalySociety}")
    if npc == "zhong":
        text = text.replace("我们以前经常有学术上的探讨，也是他把我从梅塔手里救了出来。", "我们以前经常有学术上的探讨。")
        text = text.replace("当初周叔叔把我从那里救出来以后", "当初穆叔叔把我从那里救出来以后")
    return text


def retain_wu_topics(previous, late):
    # Figure 38 explicitly omits (but retains) the earlier private topics.
    if "- 与死者的关系" not in late:
        start = previous.index("- 来到别墅的原因")
        end = previous.rindex("- 暂时没有问题了")
        late = late.replace("- 关于全家福", previous[start:end] + "- 关于全家福", 1)
    return late


def build():
    changed = []
    for folder, prefix in [("ch1_snow_villa", "1_6_"), ("ch2_deepening", "2_2_"),
                           ("ch2_deepening", "2_5_"), ("ch3_transcend", "3_source_")]:
        for npc in SPEAKERS:
            path = DIALOGUES / folder / f"{prefix}{npc}.dtl"
            before = path.read_text(encoding="utf-8-sig")
            after = repair_text(before, npc)
            if npc == "wu" and prefix == "3_source_":
                previous = (DIALOGUES / "ch2_deepening/2_5_wu.dtl").read_text(encoding="utf-8-sig")
                after = retain_wu_topics(previous, after)
            if before != after:
                path.write_text(after, encoding="utf-8")
                changed.append(str(path.relative_to(ROOT)))
    print("Inherited source menus updated:", len(changed))
    for path in changed:
        print(path)


if __name__ == "__main__":
    build()
