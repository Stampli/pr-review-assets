#!/usr/bin/env bash
# Generates every SVG in this repo. Edit this file, run it, commit the output.
# Banners are 880x72, badges 20 px tall. One dark panel serves both GitHub themes.
# Icons are 18 px Tabler outlines (vendor/, fetched by vendor/fetch.sh) on a transparent ground.
set -euo pipefail
cd "$(dirname "$0")"

FONT="ui-monospace, SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace"
PANEL="#0d1017"
FRAME="#282d35"
MUTED="#8b949e"
TABLER="vendor/tabler-$(tr -d '[:space:]' < vendor/VERSION)"

# banner <file> <hue> <label> <sub> <glyph-path> <title> <desc>
# Final frame is the base style; keyframes animate FROM the start state, once.
banner() {
  local file="$1" hue="$2" label="$3" sub="$4" glyph="$5" title="$6" desc="$7"
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
<text x="862" y="43" fill="${MUTED}" font-size="11" text-anchor="end" opacity="0.7">DevOps PR review</text>
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

# icon <file> <tabler-name> <hue> <title>
# Keeps every Tabler <path d> except the invisible box path. pathLength="1" makes every path
# length 1, so one overshot dash (1 on, 1.2 off, from offset 1.1) hides it with no round-cap dot.
# Paths start 0.08 s apart; the delay caps at 0.68 s so the last 0.5 s draw ends before 1.2 s.
# Fails on any non-path shape in the source, which would otherwise vanish silently.
icon() {
  local file="icons/$1.svg" src="${TABLER}/$2.svg" hue="$3" title="$4"
  local shapes='<(circle|ellipse|line|polygon|polyline|rect)[[:space:]/>]'
  local paths
  if grep -Eq "$shapes" "$src"; then
    echo "icon: $src contains $(grep -Eo "$shapes" "$src" | sed -E 's#[[:space:]/>]$#>#' | sort -u | tr '\n' ' ')- gen.sh copies only <path>" >&2
    exit 1
  fi
  paths=$(grep -o '<path [^>]*d="[^"]*"' "$src" \
    | sed 's/.* d="\([^"]*\)"$/\1/' \
    | grep -vx 'M0 0h24v24H0z' \
    | awk '{ t = (NR - 1) * 0.08; if (t > 0.68) t = 0.68
             printf "<path d=\"%s\" pathLength=\"1\" style=\"animation-delay:%gs\"/>\n", $0, t }')
  mkdir -p icons
  cat > "$file" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" role="img" fill="none" stroke="${hue}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
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

icon blocker      circle-x       "#ff6188" "Blocker"
icon should-fix   alert-triangle "#fc9867" "Should fix"
icon suggestion   bulb           "#ffd866" "Suggestion"
icon question     help-circle    "#78dce8" "Question"
icon pre-existing history        "#ab9df2" "Pre-existing"
icon resolved     circle-check   "#a9dc76" "Resolved"
icon still-open   hourglass      "#fc9867" "Still open"
icon source       paperclip      "#939293" "Source"
icon checked      list-check     "#939293" "Checked"
icon bot          robot          "#939293" "Bot"
icon blast-radius compass        "#939293" "Blast radius"

echo "generated $(ls *.svg icons/*.svg | wc -l | tr -d ' ') files"
