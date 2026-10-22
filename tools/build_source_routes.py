"""Mechanical transcription of the plan's authored late-route paragraphs."""
import re
from pathlib import Path
from import_source_text import ROOT, NS, read_doc, chunks, content, literal, normalize
from repair_inherited_source_topics import build as repair_inherited_topics, retain_wu_topics

PLAN = ROOT.parents[1] / '异数改编项目策划案.docx'
PARAS = [p['text'] for p in read_doc(PLAN)]
NAMES = {'主角':'player','管家':'butler','末雨':'butler','乌停湘':'wu_ting_xiang','穆执':'mu_zhi','周崇安':'zhou_chong_an','林玖':'lin_jiu','钟歧':'zhong_qi','旁白':''}

def paragraph(text):
    text = text.replace('{Killer}', '{Ch2.AccusedKiller}')
    text = re.sub('（记录疑点.*?）', '', text)
    match = re.match(r'^(主角|管家|末雨|乌停湘|穆执|周崇安|林玖|钟歧|旁白)：(.*)$', text)
    if match:
        name, body = match.groups()
        body = body.strip()
        if body.startswith('“') and body.endswith('”'):
            body = body[1:-1]
        speaker = NAMES[name]
        return '\n'.join((speaker + ': ' if speaker else '') + part for part in chunks(body))
    return '\n'.join(chunks(text))

def segment(start, end):
    return '\n'.join(paragraph(PARAS[i]) for i in range(start, end) if PARAS[i].strip() and not PARAS[i].startswith('（'))

def write(relative, text):
    path = ROOT / 'assets/dialogues' / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.strip() + '\n', encoding='utf-8')

def build():
    repair_inherited_topics()
    # Only normalize the established old/new character-name mapping; never paraphrase.
    for path in (ROOT / 'assets/dialogues').rglob('*.dtl'):
        original = path.read_text(encoding='utf-8-sig')
        fixed = normalize(original)
        fixed = re.sub(r'(?m)^(\s*)主角：“(.*)”$', r'\1player: \2', fixed)
        if fixed != original:
            path.write_text(fixed, encoding='utf-8')
    # Flowchart 21: this question precedes the faith topic in every later menu.
    for stem in ['ch1_snow_villa/1_6_mu', 'ch2_deepening/2_2_mu', 'ch2_deepening/2_5_mu']:
        path = ROOT / 'assets/dialogues' / (stem + '.dtl')
        text = path.read_text(encoding='utf-8')
        if '- 来到别墅的原因' not in text:
            text = text.replace('- 与死者的关系', '''- 来到别墅的原因
\tmu_zhi: 我是一名教徒，住处同样在这座山上。
\tmu_zhi: 来到此地之前，我前往教堂参加礼拜，返回时突遇暴风雪。
\tmu_zhi: 我只能就近找到这里，便请求管家收留了我。
\tset {Ch1.NPCIntro.Mu.Selected2} = true
\tjump 选择
- 与死者的关系''', 1)
        text = text.replace('好的。我们的教义认为，这个世界由上界的神明创造。', '好的。上界教派是世界四大宗教之一。我们的教义认为，这个世界由上界的神明创造。')
        text = text.replace('\t\tmu_zhi: 如今，上界教派已成为世界四大宗教之一。\n', '')
        path.write_text(text, encoding='utf-8')
    # Reported nightmares must be separately saved and cannot award repeat rewards.
    first_butler = ROOT / 'assets/dialogues/ch1_snow_villa/1_6_butler.dtl'
    first = first_butler.read_text(encoding='utf-8')
    first = re.sub(r'\t- 说出乌停湘的梦魇.*?(?=\t- )', '', first, flags=re.S)
    for name, npc, key in [('穆执','mu','Mu'),('周崇安','zhou','Zhou'),('林玖','lin','Lin'),('钟歧','zhong','Zhong')]:
        if f'do DataManager.set_flag("source_plot/reported_{npc}"' not in first:
            condition = f'{{Ch1.PrivateChat.{key}.NightmareSolved}} == true'
            first = first.replace(condition, condition + ' and {SourcePlot.Reported' + key + '} != true')
            start = first.index('\t- 说出' + name)
            end = first.index('\t\tjump 关于委托', start)
            first = first[:end] + f'\t\tset {{SourcePlot.Reported{key}}} = true\n\t\tdo DataManager.set_flag("source_plot/reported_{npc}", true)\n' + first[end:]
    # The yellow source nodes explicitly defer help-pool authoring. Do not ship xxx.
    first = re.sub(r'- 关于帮助 .*?(?=- 暂时没有问题了\n\tbutler: 了解了。)', '', first, flags=re.S)
    first_butler.write_text(first, encoding='utf-8')
    hall_path = ROOT / 'assets/dialogues/ch2_deepening/2_2_butler_hall.dtl'
    hall = hall_path.read_text(encoding='utf-8')
    if '- 关于委托\n' not in hall:
        request = first[first.index('- 关于委托'):first.rindex('- 暂时没有问题了')]
        request = request.replace('jump 选择', 'jump 自由调查')
        hall = hall.replace('- 指认凶手\n', request + '- 指认凶手\n')
        hall_path.write_text(hall, encoding='utf-8')
    route = '''[style name="default_visual_novel"]
do SaveManager.autosave_before_endings()
if {Affinity.Wu} < 30:
\tjump 修正
if {Affinity.Wu} > 70 and {Ch3.KeyDialogue.Freedom} == true:
\tjump 超越
jump 抗争

label 修正
[signal arg="audio:play_bgm:dust_rain:2.0"]
set {Ch3.Route.Correction} = true
'''+segment(857,861)+'''
do FlowManager.open_source_darkroom()
[end_timeline]

label 抗争
[signal arg="audio:play_bgm:hero_journey:2.0"]
set {Ch3.Route.Resistance} = true
'''+segment(872,906)+'''
do DataManager.add_suspicion("3_suspicion_god_weapon", "dialogue", "resistance")
do FlowManager.open_source_darkroom()
do FlowManager.set_dialogic_var("ButlerName", "末雨")
[end_timeline]

label 超越
[signal arg="audio:play_bgm:role_exit:2.0"]
set {Ch3.Route.Transcend} = true
'''+segment(952,982)+'''
do FlowManager.open_source_darkroom()
do FlowManager.set_dialogic_var("ButlerName", "末雨")
[end_timeline]
'''
    write('ch3_transcend/3_1_route.dtl', route)
    # Source 31: the door memory has already been recreated before choice 21.
    write('ch2_deepening/2_6_memory_fragments.dtl', '''[style name="default_visual_novel"]
if {Affinity.Wu} <= 70:
\tjump 私聊
当你回到大厅时，乌停湘拉了拉你，似乎有话要说。
join wu_ting_xiang right
wu_ting_xiang: 我想起来了一些事情，但是想起来的越多，我越感到不安，就好像一个至关重要的抉择被摆在了我的面前。我……我不知道该怎么办。
- 告诉她书房里的名言
\t- 读书不是为了雄辩和驳斥，也不是为了轻信和盲从，而是为了思考和权衡。
\t\twu_ting_xiang: 这句话和现在的情况有什么关系吗？我不明白。
\t- 自由不是在黑与白中做出选择，而是可以放弃这样被规定好的选择。
\t\twu_ting_xiang: 被规定好的选择……是什么意思？
\t\tset {Ch3.KeyDialogue.Freedom} = true
\t- 真正可怕的，并不是那种人人都难以避免的一念之差，而是那种深入习俗、盘踞于人心深处的谬误与偏见。
\t\twu_ting_xiang: 这句话和现在的情况有什么关系吗？我不明白。
- 让她放平心态
\tplayer: 每个人都有必须要做出抉择的时候，当你有机会做出抉择时，不要让自己后悔。
- 询问她原因
\twu_ting_xiang: 我……我不知道应不应该告诉你……
就在此时，你注意到管家向你们走来。
label 私聊
join butler left
butler: 乌停湘，我要和你私聊。
wu_ting_xiang: 嗯？好……
管家带着一股不容拒绝的气场，和乌停湘往会客厅走去。看来那里暂时是用不了了。
set {Ch2.MemoryFragments.Started} = true
[signal arg="flow:ch2_memory_complete"]
[end_timeline]''')
    # No rewritten condensed finale: append the exact accusation reactions.
    reactions = (ROOT / 'assets/dialogues/ch2_deepening/2_6_accusation.dtl').read_text(encoding='utf-8')
    reactions = reactions[reactions.index('if {Ch2.AccusedKiller}'):reactions.index('butler: 我相信侦探')]
    write('ch3_transcend/3_2_source_accusation.dtl', '''[style name="default_visual_novel"]
do SaveManager.autosave_before_endings()
do FlowManager.prepare_source_endings()
if {SourcePlot.PerfectReady} == true and {Ch3.Route.Transcend} == true:
\t[signal arg="flow:start_ending_clear_snow"]
\t[end_timeline]
if {Ch3.Route.Resistance} == true and {Ch3.Weapon.Agreed} == true:
\tjump 答应
if {Ch3.Route.Resistance} == true and {Ch3.Weapon.Offered} == true:
\tjump 未答应
'''+segment(911,913)+'\n'+reactions+segment(915,919)+'''
if {Ch3.Route.Resistance} == true:
\t[signal arg="flow:start_ending_calm"]
else:
\t[signal arg="flow:start_ending_dust"]
[end_timeline]
label 答应
set {Ch3.Weapon.Fired} = true
'''+segment(923,932)+'''
[signal arg="flow:start_ending_godslayer"]
[end_timeline]
label 未答应
set {Ch3.Weapon.Fired} = true
'''+segment(936,947)+'''
[signal arg="flow:start_ending_godslayer"]
[end_timeline]''')
    # Exact source summaries, followed by six independently evaluated endings.
    for name, idx in [('dust',986),('godslayer',988),('calm',990),('clear_snow',992)]:
        number = {'dust':1,'godslayer':2,'calm':3,'clear_snow':4}[name]
        write(f'finale/4_{number}_ending_{name}.dtl', f'''[background scene="res://scenes/dialogic/dialogic_color_background.tscn" arg="#000000ff" fade="1.5"]
[style name="plain_text"]
leave --All--
{PARAS[idx]}
set {{Ending.Completed}} = true
set {{Ending.Id}} = "{name}"
[signal arg="flow:source_character_endings"]
[end_timeline]''')
    sequence = ['[style name="plain_text"]', 'leave --All--', 'do FlowManager.prepare_source_endings()']
    for npc, endings in [('mu',['death','forget','perfect']),('zhou',['death','forget','perfect']),('lin',['death','forget','perfect']),('zhong',['death','forget','perfect']),('wu',['wake','farewell','perfect']),('player',['return','audience','perfect'])]:
        for i, ending in enumerate(endings):
            sequence += [f'{"if" if i == 0 else "elif"} {{SourcePlot.Ending{npc.capitalize()}}} == "{ending}":', f'\tjump source_ending_{npc}_{ending}/']
    sequence += ['[signal arg="flow:ending_finished"]','[end_timeline]']
    write('finale/source_character_endings.dtl', '\n'.join(sequence))
    wu = '''[style name="default_visual_novel"]
join wu_ting_xiang right
do FlowManager.sync_source_plot()
label 选择
wu_ting_xiang: 我会尽可能如实回答的。
- 关于全家福 | [if {SourcePlot.HasPhoto} == true and {SourcePlot.WuPhoto} != true]
\twu_ting_xiang: ……没错，那是我的全家福。那个房间也是我的房间。
\tset {SourcePlot.WuPhoto} = true
\tjump 选择
- 关于笔记本 | [if {Ch3.Route.Correction} == true and {SourcePlot.WuPhoto} == true and {SourcePlot.HasCycle} == true and {SourcePlot.WuNotebook} != true]
\twu_ting_xiang: 你看到了啊，那我也没什么好隐瞒的了。我都想起来了，我不来自任何一个平行世界，用你们的话来说，我来自上层世界。我曾经负责管理伽马世界线，也就是这里的林玖所在的那个世界线。
\twu_ting_xiang: 但由于黑门事件的发生，我一遍又一遍地试图找到解决的办法，却徒劳无功。老师最终还是发现了我的情况，不再让我接触箱庭，为了治疗我的心理障碍采用了箱庭疗法，将我的意识投放到伽马世界线，让我在这一段人生阅历中有所成长。
\tset {SourcePlot.WuNotebook} = true
\tjump 选择
- 关于房间内的其它线索 | [if ({Ch3.Route.Correction} == true and {SourcePlot.WuNotebook} == true) or ({Ch3.Route.Correction} != true and {SourcePlot.WuPhoto} == true)]
\tlabel 房间线索
\tif ({SourcePlot.HasPaper} != true or {SourcePlot.WuPaper} == true) and ({SourcePlot.HasFlowerPhoto} != true or {SourcePlot.WuFlower} == true) and ({SourcePlot.HasLetter} != true or {SourcePlot.WuLetter} == true) and ({Ch3.Route.Correction} == true or {SourcePlot.HasCycle} != true or {SourcePlot.WuNotebook} == true):
\t\t似乎没有可以询问的线索
\t\tjump 选择
\t- 关于报纸 | [if {SourcePlot.HasPaper} == true and {SourcePlot.WuPaper} != true]
\t\twu_ting_xiang: 乌叙是我的爸爸，他是一名解构学专家。
\t\tlabel 报纸后续
\t\tif {SourcePlot.WuSandbox} == true and {SourcePlot.WuDeconstruction} == true:
\t\t\tset {SourcePlot.WuPaper} = true
\t\t\tjump 房间线索
\t\t- 箱庭计划是什么？ | [if {SourcePlot.WuSandbox} != true]
\t\t\twu_ting_xiang: 箱庭计划是上层世界旨在通过建构箱庭来开展社会学等学科研究的计划，上层世界的人利用前沿科技创造了箱庭世界，并将弦理论作为箱庭世界的底层逻辑。你们所在的这个箱庭世界只是众多箱庭世界中的一个。
\t\t\tset {SourcePlot.WuSandbox} = true
\t\t\tjump 报纸后续
\t\t- 解构学是什么？ | [if {SourcePlot.WuDeconstruction} != true]
\t\t\twu_ting_xiang: 解构学是和建构学相对照的一门学科。后者是构造箱庭的学科，前者则是解构世界的学科——上层世界的人们创造了箱庭世界后，逐渐产生在我们的世界之外，是否还存在更上层的世界的疑问。于是解构学的研究内容就是解构我们正可能生活在其中的箱庭。
\t\t\tset {SourcePlot.WuDeconstruction} = true
\t\t\tjump 报纸后续
\t- 关于花海合照 | [if {SourcePlot.HasFlowerPhoto} == true and {SourcePlot.WuFlower} != true]
\t\twu_ting_xiang: 那是我和零姐姐的合照。她叫做零芝，是一名心理医生兼建构学家，也是她开创了箱庭疗法，主导着对我的治疗。她对我说过，“假如每一朵花都是一个世界，那么这片花海应该是什么样的”，这也成了我对多重时空的第一印象。
\t\tset {SourcePlot.WuFlower} = true
\t\tjump 房间线索
\t- 关于留言纸 | [if {SourcePlot.HasLetter} == true and {SourcePlot.WuLetter} != true]
\t\twu_ting_xiang: 我的爸爸妈妈都是解构学的专家，他们平常工作很忙，只能把我托给爷爷奶奶照顾。小时候的我不理解他们的工作，于是他们把我送到了末老师家里照看一段时间，学习和箱庭计划以及建构学有关的知识。
\t\twu_ting_xiang: 末老师名叫末雨，和爸爸妈妈师出同门，是一名建构师。末老师教会了我很多知识，我也因为他认识了零姐姐。
\t\tset {SourcePlot.WuLetter} = true
\t\tjump 房间线索
\t- 关于笔记本 | [if {Ch3.Route.Correction} != true and {SourcePlot.HasCycle} == true and {SourcePlot.WuNotebook} != true]
\t\twu_ting_xiang: 这就是我说过的那段经历。我曾经负责管理伽马世界线，也就是这里的林玖所在的那个世界线。但由于黑门事件的发生，我一遍又一遍地试图找到解决的办法，却徒劳无功。老师最终还是发现了我的情况，不再让我接触箱庭，为了治疗我的心理障碍采用了箱庭疗法，将我的意识投放到伽马世界线，让我在这一段人生阅历中有所成长。
\t\tset {SourcePlot.WuNotebook} = true
\t\tjump 房间线索
\t- 还有其他问题
\t\tjump 选择
- 关于管家 | [if {Ch3.Route.Correction} == true and {SourcePlot.WuButler} != true]
\twu_ting_xiang: 管家没有什么奇怪的地方，他只是给我看了一封信，至于信是哪里来的，他也不知道，估计只是这个梦境中的工具人吧。信的内容让我回想起了我的记忆，不过上面写着阅后即焚，我在读完后就烧掉了。
\tset {SourcePlot.WuButler} = true
\tjump 选择
- 关于建构师 | [if {Ch3.Route.Correction} != true and {SourcePlot.WuButler} != true]
\twu_ting_xiang: 刚刚老师和我私聊的时候，帮我回想起了所有的记忆，但我不想让大家被修正，明明大家都有自己的人生，都有未竟的心愿，为什么一定要做到这样的地步？但我也不知道应该如何阻止老师。
\tset {SourcePlot.WuButler} = true
\tjump 选择
- 暂时没有问题了
\twu_ting_xiang: 好，有什么别的疑问要记得和我交流哦。
[signal arg="flow:exit_private_chat"]
[end_timeline]'''
    previous_wu = (ROOT / 'assets/dialogues/ch2_deepening/2_5_wu.dtl').read_text(encoding='utf-8')
    write('ch3_transcend/3_source_wu.dtl', retain_wu_topics(previous_wu, wu))
    # Flowchart 38 retains earlier questions and adds these authored responses.
    architect_lines = {
        'mu': ('mu_zhi', '祂就是我们教会所信奉的神明，但我感觉……见到祂时我并没有预想中那么激动。我的虔诚对祂而言似乎不值一提，祂甚至没有因此多看我一眼。我……我还需要想想……'),
        'zhou': ('zhou_chong_an', '虽然时今将她的心愿托付给我了，但真正见到在幕后操控一切的人偶师时，我却不知道应该如何是好。如果时今也能在这里该有多好，她会做些什么？'),
        'lin': ('lin_jiu', '我只知道，我不想死……乌停湘愿意帮助我们，才选择告诉我们真相。但是，我们要怎么样才能阻止祂？'),
    }
    for npc, (speaker, line) in architect_lines.items():
        previous = (ROOT / f'assets/dialogues/ch2_deepening/2_5_{npc}.dtl').read_text(encoding='utf-8')
        topic = f'''- 关于建构师 | [if {{SourcePlot.{npc.capitalize()}Architect}} != true and {{Ch3.Route.Correction}} != true]
\t{speaker}: {line}
\tset {{SourcePlot.{npc.capitalize()}Architect}} = true
\tjump 选择
'''
        write(f'ch3_transcend/3_source_{npc}.dtl', previous.replace('- 暂时没有问题了', topic + '- 暂时没有问题了'))
    zhong = (ROOT / 'assets/dialogues/ch2_deepening/2_5_zhong.dtl').read_text(encoding='utf-8')
    new_topics = '''- 关于建构师 | [if {SourcePlot.ZhongArchitect} != true and {Ch3.Route.Correction} != true]
\tzhong_qi: 他就是我们世界的建构者，也是他设下了环状弦，将所有探索世界之理的人无情抹除。如果有任何机会做出反抗，我一定不会无动于衷。如果你不打算帮我，我会自己去找。
\tset {SourcePlot.ZhongArchitect} = true
\tjump 选择
- 我找到武器了 | [if {SourcePlot.WeaponReady} == true and {Ch3.Weapon.Offered} != true and {Ch3.Route.Correction} != true]
\tzhong_qi: 好！事不宜迟，我们要在他警觉之前动手。
\tset {Ch3.Weapon.Offered} = true
\t- 答应
\t\tjump 交枪
\t- 拒绝
\t\tzhong_qi: 为什么？明明只是最后一步。
\t\t- 答应
\t\t\t他松了一口气。
\t\t\tjump 交枪
\t\t- 我不想这么做
\t\t\tzhong_qi: 呵，好啊，一味地退缩、妥协，后果自负！
\t\t\tset {Affinity.Zhong} -= 100
\t\t\tset {SourcePlot.ZhongRefused} = true
\t\t\t他站起身，离开了会客厅。
\t\t\t[signal arg="flow:exit_private_chat"]
\t\t\t[end_timeline]
'''
    zhong = zhong.replace('label 选择', 'do FlowManager.sync_source_plot()\nlabel 选择', 1)
    zhong = zhong.replace('- 暂时没有问题了', new_topics + '- 暂时没有问题了')
    zhong += '''\nlabel 交枪
zhong_qi: 枪交给我吧，你去找他指认凶手，这样他一定会放下戒心，等他回到大厅宣布结果的时候，我就趁机动手。
set {Ch3.Weapon.Agreed} = true
你同意了他的计划，把手枪交给了他。接下来，去找那个建构师，让他理解一下箱庭中人的抗争。
[signal arg="flow:exit_private_chat"]
[end_timeline]\n'''
    write('ch3_transcend/3_source_zhong.dtl', zhong)
    # Use the same source menu and exact confirmation; never return to the old finale.
    butler = (ROOT / 'assets/dialogues/ch2_deepening/2_2_butler_hall.dtl').read_text(encoding='utf-8')
    write('ch3_transcend/3_source_butler.dtl', butler[butler.index('label 自由调查'):].join(['[style name="default_visual_novel"]\njoin butler left\n', '']))
    print('Transcribed three route introductions, three accusation outcomes and four source summaries.')

if __name__ == '__main__':
    build()
