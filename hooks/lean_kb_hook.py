#!/usr/bin/env python3
# ponytail: stateless, one note per matching prompt. Add session dedupe if the measured cost matters.
"""UserPromptSubmit hook for the lean-kb skill.

When the prompt names a wiki, an ontology, a knowledge graph, a RAG index, or a memory
index, the hook adds the text of rules/lean-kb.md as additionalContext. Otherwise it
prints nothing.

Contract: JSON on stdin with `prompt`. JSON on stdout with
hookSpecificOutput.hookEventName and hookSpecificOutput.additionalContext. Exit 0 always
(fail-open). No network, no subprocess, no file write, no state. The only file access is
a read of rules/lean-kb.md, found from the path of this file. The prompt text is never
printed, logged, or stored.

Disable: environment variable LEAN_KB_DISABLE=1, or a file named lean-kb.off in
~/.claude or in the .claude folder of the project.
"""
import json
import os
import re
import sys

KEYWORDS = (
    "온톨로지", "위키", "지식 그래프", "지식그래프", "지식 베이스", "지식베이스",
    "세컨드 브레인", "기억 목차", "메모리 목차",
    "ontology", "wiki", "knowledge graph", "knowledge base", "second brain",
    "MEMORY.md", "RAG",
)
# No note for a shell escape, or for a note that a side agent adds (not a user request).
# Calibrated on one user's past prompts: side-agent notes were false hits.
EXCLUDE = re.compile(r"^\s*(?:!|Here is a note offered by a side agent)")

URL = re.compile(r"(?:https?://|www\.)\S+", re.IGNORECASE)


def _is_latin(word):
    return word.isascii()


def _build_pattern():
    parts = []
    for word in KEYWORDS:
        body = re.escape(word)
        if _is_latin(word):  # full word only: "storage" must not match RAG
            body = r"(?<![A-Za-z0-9_])" + body + r"(?![A-Za-z0-9_])"
        parts.append(body)
    return re.compile("|".join(parts), re.IGNORECASE)


PATTERN = _build_pattern()


def matches(prompt):
    """True when the prompt asks for knowledge-base work."""
    if not isinstance(prompt, str) or not prompt.strip():
        return False
    if EXCLUDE.search(prompt):
        return False
    return PATTERN.search(URL.sub(" ", prompt)) is not None


def disabled(env):
    if env.get("LEAN_KB_DISABLE") == "1":
        return True
    folders = (env.get("CLAUDE_PROJECT_DIR"), os.path.expanduser("~"))
    return any(f and os.path.exists(os.path.join(f, ".claude", "lean-kb.off")) for f in folders)


def read_note():
    here = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(here, os.pardir, "rules", "lean-kb.md")
    with open(path, "rb") as handle:
        return handle.read().decode("utf-8", "replace").strip()


def main():
    if disabled(os.environ):
        return
    payload = json.loads(sys.stdin.buffer.read().decode("utf-8", "replace"))
    if not isinstance(payload, dict) or not matches(payload.get("prompt")):
        return
    note = read_note()
    if note:
        sys.stdout.write(json.dumps({"hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit", "additionalContext": note}}))


if __name__ == "__main__":
    try:
        main()
    except Exception:  # fail-open: a hook fault must never block the prompt
        pass
    sys.exit(0)
