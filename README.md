# pr-review-assets

Static SVG banners and badges that the Stampli AI PR reviewer embeds in its GitHub reviews. Public so GitHub can display them in private repos; the files carry no data about any pull request.

## Files

| File | Used for |
|---|---|
| `banner-approved.svg` | review heading banner on `APPROVE` |
| `banner-changes-requested.svg` | review heading banner on `REQUEST_CHANGES` |
| `banner-reviewer-failure.svg` | banner on the reviewer-failure comment |
| `badge-blocker.svg` 🔴 · `badge-should-fix.svg` 🟠 · `badge-suggestion.svg` 🟡 · `badge-question.svg` 🔵 · `badge-pre-existing.svg` 🟣 | pill after the severity emoji |

## Editing

1. Edit `gen.sh`. It is the only source; never hand-edit an SVG.
2. `./gen.sh && ./check.sh`.
3. Commit and push. Copy the new commit SHA into `REVIEW_ASSETS_REF` in `Stampli/DevOps/.github/workflows/pr_review.yml` and open a PR there.

URLs are pinned by commit SHA: `https://raw.githubusercontent.com/Stampli/pr-review-assets/<sha>/<file>`. Old reviews keep their old look; nothing is cached by branch.

## Rules the checker enforces

Well-formed XML, under 20 KB, `role="img"`, `<title>`, `<desc>`, explicit `width`/`height`/`viewBox`, the GitHub monospace font stack, no scripts, no external references, finite animation only, a `prefers-reduced-motion` rule. Base styles are the finished frame so a viewer with motion off, or an email client, sees the final image.
