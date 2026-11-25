#!/bin/bash
# Self-test of lean_kb_hook.py. Exit 0 only if each case passes.
HERE="$(cd "$(dirname "$0")" && pwd)"
HOOK="$HERE/lean_kb_hook.py"
FAILS=0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mk() { P="$1" python3 -c 'import json,os;print(json.dumps({"prompt":os.environ["P"]}))'; }
report() { # name status
  if [ "$2" = "0" ]; then echo "PASS $1"; else echo "FAIL $1"; FAILS=$((FAILS+1)); fi
}
# run_hook <stdin-text> [hook-path] -> stdout of hook (clean env, empty HOME unless set)
run_hook() { printf '%s' "$1" | env -u LEAN_KB_DISABLE -u CLAUDE_PROJECT_DIR HOME="${HOME_OVERRIDE:-$TMP/home}" python3 "${2:-$HOOK}" 2>"$TMP/err"; echo "rc=$?" >"$TMP/rc"; }
valid_inject() { # stdout text
  printf '%s' "$1" | python3 -c '
import json,sys
d=json.load(sys.stdin)["hookSpecificOutput"]
assert d["hookEventName"]=="UserPromptSubmit"
assert d["additionalContext"].startswith("[lean-kb]")'
}
mkdir -p "$TMP/home"

for p in "사내 위키 구조 잡아줘" "온톨로지 스키마 설계해줘" "MEMORY.md 정리해줘" "build a knowledge graph for the docs" "RAG 색인 다시 만들자"; do
  out="$(run_hook "$(mk "$p")")"
  valid_inject "$out" 2>/dev/null; s=$?
  [ "$(cat "$TMP/rc")" = "rc=0" ] || s=1
  report "inject: $p" $s
done

expect_silent() { # name stdin-text
  out="$(run_hook "$2")"; s=0
  [ -z "$out" ] || s=1
  [ "$(cat "$TMP/rc")" = "rc=0" ] || s=1
  report "silent: $1" $s
}
expect_silent "결제 버그 고쳐줘" "$(mk '결제 버그 고쳐줘')"
expect_silent "empty prompt" "$(mk '')"
expect_silent "invalid JSON" "{not json"
expect_silent "no prompt field" '{"other":"위키"}'
expect_silent "URL only wiki" "$(mk 'https://en.wikipedia.org/wiki/Hippocampus 요약해줘')"
expect_silent "storage" "$(mk 'storage 정리해줘')"
expect_silent "side-agent note" "$(mk 'Here is a note offered by a side agent: 위키 관계 549건')"
expect_silent "host notification block" "$(mk '<task-notification><result>위키 검토 결과</result></task-notification>')"

expect_inject() { # name stdin-text
  out="$(run_hook "$2")"; s=0
  printf '%s' "$out" | grep -q 'lean-kb' || s=1
  report "inject: $1" $s
}
expect_inject "plural keyword" "$(mk 'compare two wikis')"
expect_inject "user text after a host block" "$(mk '<system-reminder>note</system-reminder> 위키 구조 잡아줘')"

# disable switch 1
out="$(printf '%s' "$(mk '사내 위키 구조 잡아줘')" | LEAN_KB_DISABLE=1 HOME="$TMP/home" python3 "$HOOK" 2>/dev/null)"; s=0; [ -z "$out" ] || s=1
report "silent: LEAN_KB_DISABLE=1" $s

# disable switch 2, project side: a flag file in the .claude folder of CLAUDE_PROJECT_DIR
mkdir -p "$TMP/proj/.claude"; : > "$TMP/proj/.claude/lean-kb.off"
out="$(printf '%s' "$(mk '사내 위키 구조 잡아줘')" | CLAUDE_PROJECT_DIR="$TMP/proj" HOME="$TMP/nohome" python3 "$HOOK" 2>/dev/null)"; s=0; [ -z "$out" ] || s=1
report "silent: project flag file" $s

# disable switch 2: flag file in temporary HOME
mkdir -p "$TMP/home2/.claude"; : >"$TMP/home2/.claude/lean-kb.off"
out="$(HOME_OVERRIDE="$TMP/home2" run_hook "$(mk '사내 위키 구조 잡아줘')")"; s=0; [ -z "$out" ] || s=1
report "silent: flag file lean-kb.off" $s

# rules file absent: copy of hook in a temporary folder
mkdir -p "$TMP/copy/hooks"; cp "$HOOK" "$TMP/copy/hooks/lean_kb_hook.py"
out="$(run_hook "$(mk '사내 위키 구조 잡아줘')" "$TMP/copy/hooks/lean_kb_hook.py")"; s=0
[ -z "$out" ] || s=1; [ "$(cat "$TMP/rc")" = "rc=0" ] || s=1
report "silent: rules file absent" $s

# privacy: marker must not appear in stdout or stderr
MARK="ZXQ-PRIVACY-7f3a9c"
out="$(printf '%s' "$(mk "위키 정리 $MARK")" | env HOME="$TMP/home" python3 "$HOOK" 2>"$TMP/err2")"; s=0
case "$out" in *"$MARK"*) s=1;; esac
grep -q "$MARK" "$TMP/err2" && s=1
[ -n "$out" ] || s=1
report "privacy: marker absent from stdout and stderr" $s

# run time of one call (informational)
TIMEFORMAT='%R'
T="$( { time printf '%s' "$(mk '사내 위키 구조 잡아줘')" | HOME="$TMP/home" python3 "$HOOK" >/dev/null 2>&1; } 2>&1 )"
echo "INFO run time of one call: ${T} s"

[ "$FAILS" = "0" ] && { echo "ALL PASS"; exit 0; }
echo "FAILED: $FAILS"; exit 1
