# Bundled fonts for the CV build

These files are committed so the CV builds reproducibly without each
machine needing the fonts installed system-wide.

## Why bundled rather than CTAN

- **Inter** is loaded via the CTAN `inter` package (auto-installed by
  TinyTeX on first build) — not bundled here.
- **Fraunces** and **JetBrains Mono** have no CTAN package, so the
  per-weight static TTFs live here and are referenced by fontspec via
  `Path=./fonts/site/` in [`../cv.Rmd`](../cv.Rmd).

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

## Source and licence

Both families are licensed under the [SIL Open Font License 1.1](https://scripts.sil.org/OFL).

- Fraunces — © Undercase Type. https://github.com/UndercaseType/Fraunces
- JetBrains Mono — © JetBrains s.r.o. https://github.com/JetBrains/JetBrainsMono

Static cuts here were downloaded from the [fontsource](https://fontsource.org/)
CDN mirror of Google Fonts (`cdn.jsdelivr.net/fontsource/fonts/<family>@latest/latin-<weight>-<style>.ttf`).
