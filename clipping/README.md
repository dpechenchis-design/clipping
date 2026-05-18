# clipping

Skill для Claude Code, який ріже довге відео на короткі склеєні кліпи за транскриптом з блоками `Clip N`.

## Що це

- **На вхід:** відео (.mov/.mp4) + транскрипт з блоками `Clip 1`, `Clip 2`...
- **На вихід:** один склеєний фінальний кліп на кожен блок `Clip N`
- Re-encode для точних різів, буфери 5с/1с на зовнішніх краях, склейка через ffmpeg concat

## Швидкий старт

1. Встанови `ffmpeg` (`brew install ffmpeg` на Mac, `winget install ffmpeg` на Windows)
2. Поклади цю папку у `~/.claude/skills/clipping/`
3. Запусти Claude Code у папці з відео і транскриптом
4. Скажи: "наріж відео за транскриптом через skill clipping"

Детальна інструкція — див. `SOP.md`.
Приклад транскрипту — див. `examples/transcript.txt`.

## Файли

```
clipping/
├── README.md              # цей файл
├── SKILL.md               # визначення skill для Claude (англійською)
├── SOP.md                 # покрокова інструкція для команди (українською)
├── scripts/
│   └── cut_clip.sh        # допоміжний скрипт для одного простого кліпа
└── examples/
    └── transcript.txt     # приклад правильного формату транскрипту
```

## Як встановити

### Через git (рекомендую)

```bash
# Mac/Linux
mkdir -p ~/.claude/skills
cd ~/.claude/skills
git clone https://github.com/dpechenchis-design/clipping.git
```

```powershell
# Windows
mkdir $env:USERPROFILE\.claude\skills -Force
cd $env:USERPROFILE\.claude\skills
git clone https://github.com/dpechenchis-design/clipping.git
```

### Через zip (якщо без git)

1. Завантаж zip з GitHub (зелена кнопка Code → Download ZIP)
2. Розпакуй
3. Поклади папку `clipping` у:
   - Mac: `~/.claude/skills/clipping`
   - Windows: `%USERPROFILE%\.claude\skills\clipping`

## Як перевірити що встановлено

```bash
# Mac/Linux
ls ~/.claude/skills/clipping
# має показати README.md, SKILL.md, SOP.md, scripts/, examples/
```

```powershell
# Windows
dir $env:USERPROFILE\.claude\skills\clipping
```

Якщо запускаєш `claude` у будь-якій папці і пишеш "наріж відео через skill clipping" — Claude підхопить skill автоматично.
