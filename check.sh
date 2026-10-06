#!/usr/bin/env bash
# Constraint check for every SVG in this repo. Exit 1 on the first violation.
set -euo pipefail
cd "$(dirname "$0")"
rc=0
for f in *.svg; do
  [ -e "$f" ] || continue
  fail() { echo "FAIL $f: $1"; rc=1; }
  xmllint --noout "$f" 2>/dev/null || fail "not well-formed XML"
  [ "$(wc -c <"$f")" -lt 20480 ] || fail "over 20 KB"
  grep -q 'role="img"' "$f"  || fail 'missing role="img"'
  grep -q '<title>' "$f"     || fail "missing <title>"
  grep -q '<desc>' "$f"      || fail "missing <desc>"
  grep -q ' width="' "$f"    || fail "missing width"
  grep -q ' height="' "$f"   || fail "missing height"
  grep -q ' viewBox="' "$f"  || fail "missing viewBox"
  grep -q "ui-monospace, SFMono-Regular, Menlo, Consolas, 'Liberation Mono', monospace" "$f" || fail "font stack"
  grep -q '<script' "$f"     && fail "script"
  grep -Eq 'href=["'"'"']?(https?:)?//' "$f" && fail "external href"
  grep -Eq 'url\(["'"'"']?(https?:)?//' "$f" && fail "external url()"
  grep -q '@import' "$f"     && fail "@import"
  grep -q 'repeatCount="indefinite"' "$f" && fail "SMIL loop"
  grep -q 'infinite' "$f"    && fail "CSS loop"
  grep -q 'prefers-reduced-motion' "$f" || fail "no reduced-motion rule"
done
[ "$rc" -eq 0 ] && echo "OK $(ls *.svg 2>/dev/null | wc -l | tr -d ' ') files"
exit "$rc"
