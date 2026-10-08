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
      awk '{ s = $0
             while (match(s, /animation-iteration-count[[:space:]]*:[^;}"]*/)) {
               v = substr(s, RSTART, RLENGTH); sub(/^[^:]*:/, "", v); gsub(/[[:space:]]/, "", v)
               if (v != "1") bad = 1
               s = substr(s, RSTART + RLENGTH) } }
           END { exit !bad }' "$f" && fail "animation-iteration-count not 1"
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
