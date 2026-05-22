# godot 和 dialogic 的使用文档

## Dialogic 信号

1. Signal event

The signal event is used to inform code outside Dialogic that something happened or should happen.

When reached, the event will emit the signal Dialogic.signal_event and pass along the argument given in the event.

To react to the signal event, connect to it before starting your dialog:

```gdscript
func _ready():
     Dialogic.signal_event.connect(_on_dialogic_signal)

func _on_dialogic_signal(argument:String):
    if argument == "activate_something":
        print("Something was activated!")
```

2. Text signal

When using the [signal=activate_something] text effect, dialogic will emit the Dialogic.text_signal signal with the given argument.

You can connect it the same way as the signal_event signal:

```gdscript
func _ready():
     Dialogic.text_signal.connect(_on_dialogic_text_signal)

func _on_dialogic_text_signal(argument:String):
    if argument == "activate_something":
        print("Something was activated!")
```

3. Start & End signals
   
Using the Dialogic.timeline_ended and Dialogic.timeline_started signals (both have no arguments) lets you react to dialog ending or beginning.

Example:

```gdscript
func start_dialog():
    Dialogic.timeline_ended.connect(_on_timeline_ended)
    Dialogic.start("my_timeline")

func _on_timeline_ended():
    Dialogic.timeline_ended.disconnect(_on_timeline_ended)
    # do something else here
```

4. Subsystem signals

Dialogic subsystems have many useful signals. Here is a selection of them:

- Dialogic.Text has

  - signal about_to_show_text(info:Dictionary)
  - signal text_finished(info:Dictionary)
  - signal speaker_updated(character:DialogicCharacter)
  - signal textbox_visibility_changed(visible:bool)
  - signal animation_textbox_new_text
  - signal animation_textbox_show
  - signal animation_textbox_hide

- Dialogic.Portraits has

  - signal character_joined(info:Dictionary)
  - signal character_left(info:Dictionary)
  - signal character_portrait_changed(info:Dictionary)

- Dialogic.VAR has

  - signal variable_changed(info:Dictionary)
  - signal variable_was_set(info:Dictionary) # only on set variable events

If you want to find all signals, head over to the Subsystem Index, select a subsystem and take a look at the related Signals category.

## Dialogic 变量

1. Using variables outside Dialogic

You might want to access variables from scripts outside dialogic.

You can do so with direct access:

```gdscript
Dialogic.VAR.my_variable = 20
print(Dialogic.VAR.Group.other_variable)
```

You can also do so by string:

```gdscript
Dialogic.VAR.set('my_variable', 20)
print(Dialogic.VAR.get('Group').get('my_variable'))
```

> Warning
> Variables are only accessible after the Dialogic autoload is ready, so do not use them before your nodes are ready either!

Folders (as well as the root “folder”) have some methods that might be useful:

- `folders()` lists all folders in this folder (not strings but FolderObjects)
- `variables(@absolute)` lists the names of all the variables in that folder
- `has(@variable_name)` returns true if such a variable exists

This allows you to do fancy stuff like this:

```gdscript
var location = Dialogic.VAR.Towns.folders().pick_random().variables().pick_random()
```

Could pick a random house/place if your variables are set up like this:

```plaintext
Towns (folder)

   - Town A (folder)

      - CharacterAHouse

      - CharacterBHouse

      - Church

      - School

  - Town B (folder)

      - CharacterCHouse

      - CharacterDHouse

      - University

      - Park
```

Dialogic.VAR also has:

- Dialogic.VAR.reset(@variable_path="") resets the given variable or all variables if none is specified
- Dialogic.VAR.parse_variables(@string) returns the given string with variables replaced. This is what is used by the text event, etc.

## Dialogic 跳转

1. Text Syntax

Using jump without any target will set the next event to the beginning of this current timeline.

```text
Using "jump" returns to the beginning of this timeline.
character: Hello, this is the start.
character: This is the second message.
jump
```

Let’s introduce labels using the Label event. This will print Hello 1, Hello 2, and Hello 3. After this, the jump will print Hello 2 and Hello 3.

```text
character: Hello 1
label your_label_name
character: Hello 2
character: Hello 3
jump your_label_name
```

2. The Jump Stack

Whenever you use the Jump event, it will track where you are before changing the flow. This allows using the Return event, which reverses the flow back to the last jump point. If you jump from timeline A to timeline B’s start point and use the Return event in timeline B, it will revert to timeline A. This logic behaviour is implemented using a stack.

3. Jump Flow via Code

3.1 Starting at a Label
If you want to start at a specific label, you can provide this to your start event: `Dialogic.start(timeline, "your_label_name")`.

3.2 Jump Signals
Have a look at our signals here: [List of all signals.](https://docs.dialogic.pro/classes/subsystem_jump.html#signals)

3.3 Jumping directly
If starting at a label is not enough, you can use `Dialogic.Jump.jump_to_label(label: String)` as well. This does not use the jump stack. Alternatively, you can use `Dialogic.Jump.resume_from_last_jump()`.
