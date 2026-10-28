# Bundled fonts for the CV build

These files are committed so the CV builds reproducibly without each
machine needing the fonts installed system-wide.

## Why bundled

All three families are loaded by fontspec via `Path=./fonts/site/` in
[`../../preamble.tex`](../../preamble.tex). Looking fonts up by name
works on a desktop but not on the Linux CI runner, which has none of
them installed, so the files live here.

## Files

| File | Weight | Style |
|------|--------|-------|
| `Fraunces-Light.ttf`         | 300 | Regular |
| `Fraunces-LightItalic.ttf`   | 300 | Italic  |
| `Fraunces-Regular.ttf`       | 400 | Regular |
| `Fraunces-Italic.ttf`        | 400 | Italic  |
| `Fraunces-SemiBold.ttf`      | 600 | Regular |
| `Fraunces-SemiBoldItalic.ttf`| 600 | Italic  |
| `JetBrainsMono-Regular.ttf`  | 400 | Regular |
| `JetBrainsMono-Italic.ttf`   | 400 | Italic  |
| `JetBrainsMono-Bold.ttf`     | 700 | Regular |
| `JetBrainsMono-BoldItalic.ttf`| 700 | Italic  |
| `Inter-Light.ttf`            | 300 | Regular |
| `Inter-LightItalic.ttf`      | 300 | Italic  |
| `Inter-Regular.ttf`          | 400 | Regular |
| `Inter-Italic.ttf`           | 400 | Italic  |
| `Inter-SemiBold.ttf`         | 600 | Regular |
| `Inter-SemiBoldItalic.ttf`   | 600 | Italic  |

## Source and licence

All three families are licensed under the [SIL Open Font License 1.1](https://scripts.sil.org/OFL).

- Fraunces — © Undercase Type. https://github.com/UndercaseType/Fraunces
- JetBrains Mono — © JetBrains s.r.o. https://github.com/JetBrains/JetBrainsMono
- Inter — © The Inter Project Authors. https://github.com/rsms/inter

Fraunces and JetBrains Mono static cuts were downloaded from the
[fontsource](https://fontsource.org/) CDN mirror of Google Fonts
(`cdn.jsdelivr.net/fontsource/fonts/<family>@latest/latin-<weight>-<style>.ttf`).
Inter comes from the full-coverage static TTFs in the official
[v4.1 release](https://github.com/rsms/inter/releases/tag/v4.1)
(`extras/ttf/`), so accented author names render.
