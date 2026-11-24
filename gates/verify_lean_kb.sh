#!/bin/bash
# Master gate for lean-kb. Exit 0 only if each check passes. bash 3.2 safe.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 1
FAILS=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
res() { if [ "$2" = "0" ]; then echo "PASS $1"; else echo "FAIL $1"; FAILS=$((FAILS+1)); fi; }

# 1. py_compile for each .py file
s=0; n=0
while IFS= read -r f; do
  n=$((n+1)); python3 -m py_compile "$f" >/dev/null 2>&1 || s=1
done < <(find . -name __pycache__ -prune -o -name '*.py' -print)
[ "$n" -ge 2 ] || s=1
res "1 py_compile ($n files)" $s

# 2. hook self-test
bash hooks/lean_kb_hook.test.sh >"$TMP/hook.out" 2>&1; res "2 hook self-test" $?
sed 's/^/    /' "$TMP/hook.out"

# 3. rule note: size, no percent sign, no decimal number
s=0
SZ="$(wc -c < rules/lean-kb.md | tr -d ' ')"
[ "$SZ" -le 2000 ] || s=1
grep -q '%' rules/lean-kb.md && s=1
grep -Eq '[0-9]+\.[0-9]+' rules/lean-kb.md && s=1
res "3 rule note size $SZ bytes, no percent, no decimal" $s

# 4. ste-lint on the rule note and on SKILL.md
# The linter is the asd-ste100 skill (github.com/danyuchn/asd-ste100-skill). Set STE_LINT to its path.
# Without the linter this check fails. LEAN_KB_SKIP_STE=1 skips it, and the gate says so.
LINT="${STE_LINT:-$HOME/.claude/skills/asd-ste100/scripts/ste-lint.py}"
if [ "${LEAN_KB_SKIP_STE:-0}" = "1" ]; then
  echo "SKIP 4 ste-lint (LEAN_KB_SKIP_STE=1; this is not a pass)"
elif [ ! -f "$LINT" ]; then
  res "4 ste-lint (linter not found: set STE_LINT, or LEAN_KB_SKIP_STE=1 to skip)" 1
else
  s=0
  python3 "$LINT" rules/lean-kb.md >"$TMP/l1" 2>&1 || s=1
  python3 "$LINT" SKILL.md >"$TMP/l2" 2>&1 || s=1
  res "4 ste-lint" $s
  [ "$s" = "0" ] || { head -20 "$TMP/l1" "$TMP/l2" | sed 's/^/    /'; }
fi

# 5. check_numbers selftest
python3 -I scripts/check_numbers.py --selftest >"$TMP/st" 2>&1; res "5 check_numbers selftest" $?

# 6. numbers in SKILL.md and in each README exist in facts.md
cat SKILL.md README*.md > "$TMP/joined.md"
if [ -f gates/number_allow.txt ]; then
  python3 -I scripts/check_numbers.py evidence/facts.md "$TMP/joined.md" --allow gates/number_allow.txt >"$TMP/cn" 2>&1; rc=$?
else
  python3 -I scripts/check_numbers.py evidence/facts.md "$TMP/joined.md" >"$TMP/cn" 2>&1; rc=$?
fi
res "6 numbers match facts.md" $rc
[ "$rc" = "0" ] || head -20 "$TMP/cn" | sed 's/^/    /'

# 7. required files exist and are not empty
s=0
for f in evidence/facts.md rules/lean-kb.md hooks/lean_kb_hook.py hooks/lean_kb_hook.test.sh SKILL.md README.md scripts/check_numbers.py; do
  [ -s "$f" ] || { s=1; echo "    missing or empty: $f"; }
done
res "7 required files" $s

[ "$FAILS" = "0" ] && { echo "GATE PASS"; exit 0; }
echo "GATE FAIL ($FAILS)"; exit 1
