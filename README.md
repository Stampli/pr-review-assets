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

Outline icons from [Tabler Icons](https://tabler.io/icons) v3.49.0, MIT licence, copyright Paweł Kuna; the full notice is in `LICENSE-tabler`. `vendor/VERSION` pins the version for both scripts; `vendor/fetch.sh` fetched the sources into `vendor/tabler-3.49.0/`; `gen.sh` recolours them and adds a one-time draw-in. New version or icon: edit `vendor/VERSION` or `NAMES` in `vendor/fetch.sh`, run `vendor/fetch.sh`, delete the old `vendor/tabler-*` folder, then follow Editing.

| Token | File | Tabler icon | Stroke |
|---|---|---|---|
| 🔴 | `icons/blocker.svg` | `circle-x` | `#ff6188` |
| 🟠 | `icons/should-fix.svg` | `alert-triangle` | `#fc9867` |
| 🟡 | `icons/suggestion.svg` | `bulb` | `#ffd866` |
| 🔵 | `icons/question.svg` | `help-circle` | `#78dce8` |
| 🟣 | `icons/pre-existing.svg` | `history` | `#ab9df2` |
| ✅ | `icons/resolved.svg` | `circle-check` | `#a9dc76` |
| ⏳ | `icons/still-open.svg` | `hourglass` | `#fc9867` |
| 📎 | `icons/source.svg` | `paperclip` | `#939293` |
| 📚 | `icons/checked.svg` | `list-check` | `#939293` |
| 🤖 | `icons/bot.svg` | `robot` | `#939293` |

## Editing

1. Edit `gen.sh`. It is the only source; never hand-edit an SVG.
2. `./gen.sh && ./check.sh`.
3. Commit and push. Copy the new commit SHA into `REVIEW_ASSETS_REF` in `Stampli/DevOps/.github/workflows/pr_review.yml` and open a PR there.

URLs are pinned by commit SHA: `https://raw.githubusercontent.com/Stampli/pr-review-assets/<sha>/<file>`. Old reviews keep their old look; nothing is cached by branch.

## Rules the checker enforces

Well-formed XML, under 20 KB, `role="img"`, `<title>`, `<desc>`, explicit `width`/`height`/`viewBox`, the GitHub monospace font stack, no scripts, no external references, finite animation only, a `prefers-reduced-motion` rule. Base styles are the finished frame so a viewer with motion off, or an email client, sees the final image.

Icons skip the `<desc>` and font-stack rules and add their own: under 2 KB, `pathLength="1"` on every `<path>`, no Tabler `M0 0h24v24H0z` box path, iteration count absent or `1` in the `animation-iteration-count` longhand and in every `animation` shorthand.
