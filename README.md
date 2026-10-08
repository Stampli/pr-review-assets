# pr-review-assets

Static SVG banners, badges and icons that the Stampli AI PR reviewer embeds in its GitHub reviews. Public so GitHub can display them in private repos; the files carry no data about any pull request.

## Files

| File | Used for |
|---|---|
| `banner-approved.svg` | review heading banner on `APPROVE` |
| `banner-changes-requested.svg` | review heading banner on `REQUEST_CHANGES` |
| `banner-reviewer-failure.svg` | banner on the reviewer-failure comment |
| `badge-blocker.svg` 🔴 · `badge-should-fix.svg` 🟠 · `badge-suggestion.svg` 🟡 · `badge-question.svg` 🔵 · `badge-pre-existing.svg` 🟣 | pill after the severity emoji |
| `icons/*.svg` | 18 px icon in place of each reviewer emoji token, map below |

## Icons

Outline icons from [Tabler Icons](https://tabler.io/icons) v3.49.0, MIT licence, copyright Paweł Kuna; the full notice is in `LICENSE-tabler`. `vendor/VERSION` pins the version for both scripts; `vendor/fetch.sh` fetched the sources into `vendor/tabler-3.49.0/`; `gen.sh` recolours them and adds a one-time draw-in. Icons have no panel behind them, so each stroke holds 3:1 contrast on both GitHub grounds; banners and badges keep their own palette on their dark panel. New version or icon: edit `vendor/VERSION` or `NAMES` in `vendor/fetch.sh`, run `vendor/fetch.sh`, delete the old `vendor/tabler-*` folder, then follow Editing.

| Token | File | Tabler icon | Stroke |
|---|---|---|---|
| 🔴 | `icons/blocker.svg` | `circle-x` | `#e5534b` |
| 🟠 | `icons/should-fix.svg` | `alert-triangle` | `#d9752b` |
| 🟡 | `icons/suggestion.svg` | `bulb` | `#b8860b` |
| 🔵 | `icons/question.svg` | `help-circle` | `#2a96ab` |
| 🟣 | `icons/pre-existing.svg` | `history` | `#9a6bf0` |
| ✅ | `icons/resolved.svg` | `circle-check` | `#2da44e` |
| ⏳ | `icons/still-open.svg` | `hourglass` | `#d9752b` |
| 📎 | `icons/source.svg` | `paperclip` | `#868e96` |
| 📚 | `icons/checked.svg` | `list-check` | `#868e96` |
| 🤖 | `icons/bot.svg` | `robot` | `#868e96` |
| 🧭 | `icons/blast-radius.svg` | `compass` | `#868e96` |
| ⏭️ | `icons/skipped.svg` | `player-skip-forward` | `#868e96` |

## Editing

1. Edit `gen.sh`. It is the only source; never hand-edit an SVG.
2. `./gen.sh && ./check.sh`.
3. Commit and push. Copy the new commit SHA into `REVIEW_ASSETS_REF` in `Stampli/DevOps/.github/workflows/pr_review.yml` and open a PR there.

URLs are pinned by commit SHA: `https://raw.githubusercontent.com/Stampli/pr-review-assets/<sha>/<file>`. Old reviews keep their old look; nothing is cached by branch.

## Rules the checker enforces

Well-formed XML, under 20 KB, `role="img"`, `<title>`, `<desc>`, explicit `width`/`height`/`viewBox`, the GitHub monospace font stack, no scripts, no external references, finite animation only, a `prefers-reduced-motion` rule. Base styles are the finished frame so a viewer with motion off, or an email client, sees the final image.

Icons skip the `<desc>` and font-stack rules and add their own: under 2 KB, `pathLength="1"` on every `<path>`, no Tabler `M0 0h24v24H0z` box path, iteration count absent or `1` in the `animation-iteration-count` longhand and in every `animation` shorthand, every `stroke` a `#rrggbb` with WCAG contrast of at least 3.0 against both `#ffffff` and `#0d1117`.
