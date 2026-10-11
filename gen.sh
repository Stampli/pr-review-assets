#!/usr/bin/env bash
# Generates every SVG in this repo. Edit this file, run it, commit the output.
# Banners are 880x72, badges 20 px tall. One dark panel serves both GitHub themes.
# Icons are 18 px Tabler outlines (vendor/, fetched by vendor/fetch.sh) on a transparent ground,
# so their hues hold 3:1 on both GitHub grounds, #ffffff and #0d1117, and on Jira's dark surface
# #1d2125; check.sh enforces it. ticket/ holds the same kinds of asset for Alfred's Jira tickets.
set -euo pipefail
cd "$(dirname "$0")"

FONT="ui-monospace, SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace"
PANEL="#0d1017"
FRAME="#282d35"
MUTED="#8b949e"
TABLER="vendor/tabler-$(tr -d '[:space:]' < vendor/VERSION)"

# banner <file> <hue> <label> <sub> <glyph-path> <title> <desc> [corner]
# Final frame is the base style; keyframes animate FROM the start state, once.
banner() {
  local file="$1" hue="$2" label="$3" sub="$4" glyph="$5" title="$6" desc="$7" corner="${8:-DevOps PR review}"
  cat > "$file" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="880" height="72" viewBox="0 0 880 72" role="img" aria-label="${title}" font-family="${FONT}">
<title>${title}</title>
<desc>${desc}</desc>
<defs>
<linearGradient id="shine" x1="0" y1="0" x2="1" y2="0">
<stop offset="0" stop-color="${hue}" stop-opacity="0"/>
<stop offset="0.5" stop-color="${hue}" stop-opacity="0.18"/>
<stop offset="1" stop-color="${hue}" stop-opacity="0"/>
</linearGradient>
<clipPath id="card"><rect x="1" y="1" width="878" height="70" rx="10"/></clipPath>
</defs>
<style>
.frame { stroke-dasharray: 1900; stroke-dashoffset: 0; animation: draw 1.2s ease-out 0s 1 both; }
.glyph { stroke-dasharray: 80; stroke-dashoffset: 0; animation: draw-glyph 0.6s ease-out 0.8s 1 both; }
.label { opacity: 1; transform: translateY(0); animation: rise 0.6s ease-out 0.9s 1 both; }
.sub { opacity: 1; animation: fade 0.5s ease-out 1.5s 1 both; }
.shine { transform: translateX(0); animation: sweep 1s ease-in-out 1.4s 1 both; }
@keyframes draw { from { stroke-dashoffset: 1900; } }
@keyframes draw-glyph { from { stroke-dashoffset: 80; } }
@keyframes rise { from { opacity: 0; transform: translateY(6px); } }
@keyframes fade { from { opacity: 0; } }
@keyframes sweep { from { transform: translateX(-880px); } }
@media (prefers-reduced-motion: reduce) { .frame, .glyph, .label, .sub, .shine { animation: none; } }
</style>
<rect x="1" y="1" width="878" height="70" rx="10" fill="${PANEL}" stroke="${FRAME}"/>
<rect class="frame" x="1" y="1" width="878" height="70" rx="10" fill="none" stroke="${hue}" stroke-width="1.5"/>
<g clip-path="url(#card)"><rect class="shine" x="0" y="0" width="880" height="72" fill="url(#shine)"/></g>
<circle cx="40" cy="36" r="16" fill="none" stroke="${hue}" stroke-width="1.5" opacity="0.6"/>
<path class="glyph" d="${glyph}" fill="none" stroke="${hue}" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
<text class="label" x="76" y="33" fill="${hue}" font-size="18" font-weight="700" letter-spacing="2">${label}</text>
<text class="sub" x="76" y="55" fill="${MUTED}" font-size="12">${sub}</text>
<text x="862" y="43" fill="${MUTED}" font-size="11" text-anchor="end" opacity="0.7">${corner}</text>
</svg>
SVG
}

# badge <file> <hue> <label> <width> <title>
badge() {
  local file="$1" hue="$2" label="$3" w="$4" title="$5"
  local mid=$(( w / 2 ))
  local perim=$(( 2 * (w - 2) + 36 ))
  cat > "$file" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="20" viewBox="0 0 ${w} 20" role="img" aria-label="${title}" font-family="${FONT}">
<title>${title}</title>
<desc>Severity badge reading ${label}, drawn as a dark pill with a ${hue} border.</desc>
<style>
.b { stroke-dasharray: ${perim}; stroke-dashoffset: 0; animation: draw 0.5s ease-out 0s 1 both; }
.t { opacity: 1; animation: fade 0.3s ease-out 0.3s 1 both; }
@keyframes draw { from { stroke-dashoffset: ${perim}; } }
@keyframes fade { from { opacity: 0; } }
@media (prefers-reduced-motion: reduce) { .b, .t { animation: none; } }
</style>
<rect x="0.5" y="0.5" width="$(( w - 1 ))" height="19" rx="6" fill="${PANEL}"/>
<rect class="b" x="0.5" y="0.5" width="$(( w - 1 ))" height="19" rx="6" fill="none" stroke="${hue}" stroke-width="1"/>
<text class="t" x="${mid}" y="14" fill="${hue}" font-size="11" font-weight="700" letter-spacing="0.5" text-anchor="middle">${label}</text>
</svg>
SVG
}

# tabler_paths <tabler-name>: prints the <path> lines both icon writers draw.
# Keeps every Tabler <path d> except the invisible box path. pathLength="1" makes every path
# length 1, so one overshot dash (1 on, 1.2 off, from offset 1.1) hides it with no round-cap dot.
# Paths start 0.08 s apart; the delay caps at 0.68 s so the last 0.5 s draw ends before 1.2 s.
# Fails on any non-path shape in the source, which would otherwise vanish silently; callers
# assign its output on a line of its own so set -e stops the run.
tabler_paths() {
  local src="${TABLER}/$1.svg"
  local shapes='<(circle|ellipse|line|polygon|polyline|rect)[[:space:]/>]'
  if grep -Eq "$shapes" "$src"; then
    echo "icon: $src contains $(grep -Eo "$shapes" "$src" | sed -E 's#[[:space:]/>]$#>#' | sort -u | tr '\n' ' ')- gen.sh copies only <path>" >&2
    exit 1
  fi
  grep -o '<path [^>]*d="[^"]*"' "$src" \
    | sed 's/.* d="\([^"]*\)"$/\1/' \
    | grep -vx 'M0 0h24v24H0z' \
    | awk '{ t = (NR - 1) * 0.08; if (t > 0.68) t = 0.68
             printf "<path d=\"%s\" pathLength=\"1\" style=\"animation-delay:%gs\"/>\n", $0, t }'
}

# icon_svg <file> <tabler-name> <hue> <title> <width> <height> <viewBox>
# The one icon writer: every icon shares this markup, style and draw-in, so they cannot drift.
icon_svg() {
  local file="$1" hue="$3" title="$4" w="$5" h="$6" vb="$7"
  local paths
  paths=$(tabler_paths "$2")
  mkdir -p "$(dirname "$file")"
  cat > "$file" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="${vb}" role="img" fill="none" stroke="${hue}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
<title>${title}</title>
<style>
path { stroke-dasharray: 1 1.2; stroke-dashoffset: 0; animation: draw 0.5s ease-out 1 both; }
@keyframes draw { from { stroke-dashoffset: 1.1; } }
@media (prefers-reduced-motion: reduce) { path { animation: none; } }
</style>
${paths}
</svg>
SVG
}

# icon <file> <tabler-name> <hue> <title>
icon() {
  icon_svg "icons/$1.svg" "$2" "$3" "$4" 18 18 "0 0 24 24"
}

# ticket_icon <name> <tabler-name> <hue> <title> <pad>
# The 18 px glyph under <pad> px of transparent top pad (0.75 px per viewBox unit), floated
# wrap-left by Alfred. Pads measured in Jira's renderer:
#   8 (18x26) beside an h3: centres the glyph on the heading text; the float still clears the next block.
#   4 (18x22) beside a paragraph (12 px top margin, 24 px line): 8 there renders the glyph about 5 px low.
ticket_icon() {
  local pad="$5" vb
  vb=$(awk -v p="$pad" 'BEGIN { u = p * 4 / 3; printf "0 -%.4f 24 %.4f", u, 24 + u }')
  icon_svg "ticket/icons/$1.svg" "$2" "$3" "$4" 18 $(( 18 + pad )) "$vb"
}

CHECK="M30 36 L37 43 L51 29"
BAR="M40 26 L40 40 M40 46 L40 47"
CROSS="M33 29 L47 43 M47 29 L33 43"

banner banner-approved.svg          "#a9dc76" "APPROVED"          "merge when ready"       "$CHECK" "Approved"          "Green banner: the AI reviewer approved this pull request."
banner banner-changes-requested.svg "#ff6188" "CHANGES REQUESTED" "see the blockers below" "$BAR"   "Changes requested" "Red banner: the AI reviewer requested changes; the blockers are listed below."
banner banner-reviewer-failure.svg  "#939293" "REVIEWER FAILURE"  "no verdict recorded"    "$CROSS" "Reviewer failure"  "Grey banner: the AI reviewer did not reach a verdict; this is not a finding about the pull request."

badge badge-blocker.svg      "#ff6188" "BLOCKER"      62 "Blocker"
badge badge-should-fix.svg   "#fc9867" "SHOULD FIX"   82 "Should fix"
badge badge-suggestion.svg   "#ffd866" "SUGGESTION"   82 "Suggestion"
badge badge-question.svg     "#78dce8" "QUESTION"     69 "Question"
badge badge-pre-existing.svg "#ab9df2" "PRE-EXISTING" 96 "Pre-existing"

icon blocker      circle-x            "#e5534b" "Blocker"
icon should-fix   alert-triangle      "#d9752b" "Should fix"
icon suggestion   bulb                "#b8860b" "Suggestion"
icon question     help-circle         "#2a96ab" "Question"
icon pre-existing history             "#9a6bf0" "Pre-existing"
icon resolved     circle-check        "#2da44e" "Resolved"
icon still-open   hourglass           "#d9752b" "Still open"
icon source       paperclip           "#868e96" "Source"
icon checked      list-check          "#868e96" "Checked"
icon bot          robot               "#868e96" "Bot"
icon blast-radius compass             "#868e96" "Blast radius"
icon skipped      player-skip-forward "#868e96" "Skipped"

# Alfred's DevOps Assistance Jira tickets: one banner per status, heading icons, the thread link icon.
TICKET="Alfred · DevOps Assistance"
mkdir -p ticket
banner ticket/banner-new.svg            "#78dce8" "NEW"            "waiting for DevOps to pick it up" "M40 29 L40 43 M33 36 L47 36" "New"            "Cyan banner: this DevOps Assistance ticket is new."                         "$TICKET"
banner ticket/banner-in-progress.svg    "#ffd866" "IN PROGRESS"    "DevOps is working on it"          "M40 28 L40 36 L46 40"        "In progress"    "Yellow banner: this DevOps Assistance ticket is in progress."               "$TICKET"
banner ticket/banner-owner-approval.svg "#ab9df2" "OWNER APPROVAL" "waiting for an approver"          "M36 30 L36 42 M44 30 L44 42" "Owner approval" "Purple banner: this DevOps Assistance ticket is waiting for owner approval." "$TICKET"
banner ticket/banner-done.svg           "#a9dc76" "DONE"           "request completed"                "$CHECK"                      "Done"           "Green banner: this DevOps Assistance ticket is done."                        "$TICKET"
banner ticket/banner-out-of-scope.svg   "#939293" "OUT OF SCOPE"   "closed, not a DevOps request"     "M33 36 L47 36"               "Out of scope"   "Grey banner: this DevOps Assistance ticket is out of scope."                 "$TICKET"

ticket_icon vault      books       "#868e96" "Vault triage"    8
ticket_icon read       search      "#868e96" "Alfred's read"   8
ticket_icon discussion messages    "#868e96" "Discussion"      8
ticket_icon steps      tools       "#868e96" "Suggested steps" 8
ticket_icon question   help-circle "#2a96ab" "Open questions"  8
ticket_icon link       link        "#868e96" "Slack thread"    4

echo "generated $(ls *.svg icons/*.svg ticket/*.svg ticket/icons/*.svg | wc -l | tr -d ' ') files"
