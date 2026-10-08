#!/usr/bin/env bash
# Constraint check for every SVG in this repo. Exit 1 on the first violation.
set -euo pipefail
cd "$(dirname "$0")"
rc=0
for f in *.svg icons/*.svg; do
  fail() { echo "FAIL $f: $1"; rc=1; }
  [ -e "$f" ] || { fail "glob matched no file"; continue; }
  xmllint --noout "$f" 2>/dev/null || fail "not well-formed XML"
  [ "$(wc -c <"$f")" -lt 20480 ] || fail "over 20 KB"
  grep -q 'role="img"' "$f"  || fail 'missing role="img"'
  grep -q '<title>' "$f"     || fail "missing <title>"
  grep -q ' width="' "$f"    || fail "missing width"
  grep -q ' height="' "$f"   || fail "missing height"
  grep -q ' viewBox="' "$f"  || fail "missing viewBox"
  case "$f" in
    icons/*)
      # Icons: Tabler outline paths, no text, so no <desc> or font stack.
      [ "$(wc -c <"$f")" -lt 2048 ] || fail "icon over 2 KB"
      paths=$(awk '{ n += gsub(/<path/, "") } END { print n + 0 }' "$f")
      drawn=$(awk '{ n += gsub(/<path [^>]*pathLength="1"/, "") } END { print n + 0 }' "$f")
      [ "$paths" -gt 0 ] || fail "no <path>"
      [ "$drawn" -eq "$paths" ] || fail '<path> without pathLength="1"'
      grep -q 'M0 0h24v24H0z' "$f" && fail "Tabler box path"
      # Icons sit on the page, not a panel: every stroke needs WCAG contrast >= 3.0 on both
      # GitHub grounds, light #ffffff and dark #0d1117.
      strokes=$(grep -Eo '[[:space:]]stroke="[^"]*"' "$f" | cut -d'"' -f2 | sort -u || true)
      [ -n "$strokes" ] || fail "no stroke colour"
      for c in $strokes; do
        [[ "$c" =~ ^#[0-9a-fA-F]{6}$ ]] || { fail "stroke $c is not #rrggbb"; continue; }
        low=$(awk -v c="$c" '
          function hx(s) { return index("0123456789abcdef", substr(s, 1, 1)) * 16 + index("0123456789abcdef", substr(s, 2, 1)) - 17 }
          function lin(v) { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ^ 2.4 }
          function lum(h) { h = tolower(substr(h, 2)); return 0.2126 * lin(hx(substr(h, 1, 2))) + 0.7152 * lin(hx(substr(h, 3, 2))) + 0.0722 * lin(hx(substr(h, 5, 2))) }
          function ratio(a, b) { a = lum(a); b = lum(b); return a > b ? (a + 0.05) / (b + 0.05) : (b + 0.05) / (a + 0.05) }
          BEGIN { n = split("#ffffff #0d1117", bg, " ")
                  for (i = 1; i <= n; i++) { r = ratio(c, bg[i]); if (r < 3.0) printf "%.2f on %s ", r, bg[i] } }')
        [ -z "$low" ] || fail "stroke $c contrast ${low}below 3.0"
      done
      # One iteration, in the longhand and in every animation shorthand. In a shorthand the
      # count is the only bare number: times carry a unit, and function arguments are dropped.
      awk '{ s = $0
             while (match(s, /animation(-iteration-count)?[[:space:]]*:[^;}"]*/)) {
               m = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
               prop = m; sub(/[[:space:]]*:.*/, "", prop)
               v = m; sub(/^[^:]*:/, "", v)
               gsub(/[a-zA-Z-]+\([^)]*\)/, " ", v); gsub(/,/, " ", v)
               n = split(v, tok, /[[:space:]]+/)
               for (i = 1; i <= n; i++) {
                 if (tok[i] == "" || tok[i] == "1") continue
                 if (prop == "animation-iteration-count" || tok[i] ~ /^[+-]?[0-9]*\.?[0-9]+$/) bad = 1 } } }
           END { exit !bad }' "$f" && fail "animation iteration count not 1"
      ;;
    *)
      grep -q '<desc>' "$f" || fail "missing <desc>"
      grep -q "ui-monospace, SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace" "$f" || fail "font stack"
      ;;
  esac
  grep -q '<script' "$f"     && fail "script"
  grep -Eq 'href=["'"'"']?(https?:)?//' "$f" && fail "external href"
  grep -Eq 'url\(["'"'"']?(https?:)?//' "$f" && fail "external url()"
  grep -Eiq '&#(58|x3a);' "$f" && fail "XML-encoded URL separator"
  grep -q '@import' "$f"     && fail "@import"
  grep -q 'repeatCount="indefinite"' "$f" && fail "SMIL loop"
  grep -q 'infinite' "$f"    && fail "CSS loop"
  grep -q 'prefers-reduced-motion' "$f" || fail "no reduced-motion rule"
done
[ "$rc" -eq 0 ] && echo "OK $(ls *.svg icons/*.svg 2>/dev/null | wc -l | tr -d ' ') files"
exit "$rc"
