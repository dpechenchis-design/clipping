# clipping

Skill для нарізання довгого відео на окремі короткі кліпи за транскриптом з таймкодами.

## Що це

- На вхід: відео + транскрипт із таймкодами по сегментах
- На вихід: окремі кліпи, по одному на сегмент
- Без склейок, без хуків, без A/B варіантів

## Швидкий старт

1. Встанови `ffmpeg`
2. Поклади відео і транскрипт в одну папку
3. Скажи Claude: "Наріж відео `video.mov` за транскриптом `transcript.txt` через skill clipping"

Детально — див. `SOP.md`.

## Файли

- `SKILL.md` — визначення skill для Claude
- `SOP.md` — покрокова інструкція для людини
- `scripts/cut_clip.sh` — допоміжний скрипт для нарізання одного кліпа

## Як перенести в окремий репозиторій

Цей skill наразі живе в репо `clip-pipeline-adam`. Щоб винести його в окремий репо:

```bash
# 1. Створи порожній репо на GitHub (наприклад clipping), БЕЗ README
# 2. На своєму компʼютері:

git clone https://github.com/dpechenchis-design/clip-pipeline-adam.git
cp -r clip-pipeline-adam/clipping ~/clipping-standalone
cd ~/clipping-standalone

git init
git add .
git commit -m "Initial commit: clipping skill"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/clipping.git
git push -u origin main
```

Готово — skill живе в окремому репо, ним можна ділитися.
