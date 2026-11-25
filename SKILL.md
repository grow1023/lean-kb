---
name: lean-kb
description: Nine design rules for a wiki, an ontology, a knowledge graph, a RAG index, or a memory index. It holds evidence and templates.
---

# lean-kb

This skill holds nine design rules for a knowledge base. The source is one conference talk about token cost in RAG and memory. A hook adds a short note to each matching prompt. This file holds the evidence, the scope, and the templates that the note points to.

## When to use

- You build or edit a wiki, an ontology, a knowledge graph, a RAG index, or a memory index.
- You decide what stays in an always-loaded file and what stays behind an index.
- You decide when to change a default or a schema.

Do not use this skill for other work.

## The nine rules

All values come from the talk. Each value has the scope of one environment and small samples.

| Rule | Result in the talk | Scope and hedge | Status |
|---|---|---|---|
| 1. Count the always-loaded size multiplied by the number of requests. | Of 4k retrieved tokens, 13.8% held the answer evidence. One insert of 4k cost 10.3 times the cost of one answer call. That value is a session average and includes the answer call. | 84 development questions from the speaker. The 10.3 value is a replay of one user record, with a session range of 7.4 to 12.6 times. | measured in the talk |
| 2. Keep facts behind an index. | Test A, a core index with search for the rest: cost fell by 51.7%, and 607 original questions changed by -0.2 points. Test B, no index, with a location hint and Grep: 376 reworded questions changed by +0.8 points. | The cost value is a conversion from one environment. In test A, reworded questions fell short at -3.2 points or gave no decision. In test B, the interval is -1.4 to +2.9, and the result for original questions changed with the scoring method. The two tests have different conditions. | measured in the talk |
| 3. Keep rules in the always-loaded part, above the truncation limit. | The model opened the rule body in 16 of 52 runs when a rule line was in the index. It opened the body in 0 of 52 runs when the line was not in the index. A rule that the limit cut gave a violation rate of 53.8%. Always-loaded rules gave 23.1%. | 26 same tasks in a separate test. The CLI shows a truncation warning, but the model did not find the cut rule by itself. The rule block makes the first request 2.1 times larger. A violation rate of 23.1% remains. | measured in the talk |
| 4. Do not load the same evidence two times in one session. | Dedupe in a session cut the cost of a session by 38.7%. The answer rate changed from 81.4% to 81.7%, inside the set margin. | LoCoMo, 69 sessions, 690 turns. The test compared against a method that keeps the evidence in the history. The combination with sentence selection is not tested. | measured in the talk |
| 5. Add a dated entry for a changed fact. Put the newest first. | Stacking entries with dates gave an update answer rate of 98.3%. Two merge methods gave 85.0% and 86.7%. | A synthetic flow of 60 questions. The prompt told the model to read the newest date as the current value. The two merge methods are the speaker's own code. | measured in the talk |
| 6. Write final values and boundary conditions word for word before a session splits. | A rollover pilot cut input-equivalent tokens by 15.1% (T7) and 55.6% (T8). In an earlier test, a handover note lost one condition, and three runs of three used the wrong comparison. | 2 long tasks, 3 runs each, without search. T7 does not separate from run-to-run variation. A short task gave no gain. | measured in the talk |
| 7. Change a default only after a check that you defined before you saw the result. Compare with the first baseline. | The first-baseline comparison caught a slow decline in 200 of 200 runs. The step-only comparison passed all four steps in 191 of 200 runs. At 700 questions per step, 43% of runs fail even with equal quality (audio only). | A synthetic case of four steps, each with a 2 point drop. The talk did not connect it to operation. The talk covers default changes, and the schema part is inference. | simulated in the talk |
| 8. Write each sentence, list item, and table row with its context. | The talk selected sentences with title, table header, and path as context. It cut inserted tokens by 34.49%, and the answer rate moved from 92.98% to 92.23%. | The test covers retrieval for 399 short Korean fact questions. It does not cover wiki writing. The rule for wiki pages is our inference. | inference for wiki and ontology work |
| 9. Keep one canonical node for each entity. Put the aliases on that node. | The talk has no result for this rule. | Design inference for ontology work. Check it in the target repository. | inference for wiki and ontology work |

The rule note lists the rules with other words but the same meaning.

## Measure first

Measure these three ratios before you change a design. Version 1 has no script for them. Use a manual method.

| Ratio | Talk value | Manual method |
|---|---|---|
| Share of inserted tokens that hold the answer evidence | 13.8% of 4k | Take a set of questions with known evidence. For each question, count the evidence tokens in the insert. Divide by the insert size. |
| Share of evidence that an earlier turn already inserted | 49.3% of LoCoMo chunks | Log the chunk ids that you insert in each turn. Count the ids that appear in an earlier turn of the same session. Divide by all ids. |
| Share of the always-loaded index that a session opens | 6.9% (134 lines, 9.22 files on average) | List the index lines. Read the session log for the files that the model opens. Divide the opened count by the line count. |

The talk counted only the files that it found, so the real value can be higher.

## Templates

Index line (one line for each page):

```
- [Title](path/to/page.md): one-line summary
```

Position of the rules block. Put it at the top of the always-loaded file, above the index lines:

```
# Rules
(each rule in one line, with the reason)
# Index
(one line for each page)
```

Dated entry. Put the newest entry first. Do not edit the old entries:

```
## Fact: <subject>
- YYYY-MM-DD: <new value>. Reason: <reason>. Source: <path>
- YYYY-MM-DD: <old value>. Source: <path>
```

Handover memo for a session split:

```
Goal: <one sentence>
Final values: <each value word for word>
Boundary conditions: <each condition word for word, with the comparison sign>
Open items: <list>
Files: <paths>
```

Checklist for a default change. Write it before you see the result:

```
- [ ] Metric and margin are written down.
- [ ] Sample and question set are fixed.
- [ ] The baseline is the first baseline, not the last step.
- [ ] The check uses questions that you did not use to choose the change.
- [ ] Someone other than the author scores the result.
```

## Hook

The hook is hooks/lean_kb_hook.py. Register it as a UserPromptSubmit hook. Add this entry to the `hooks.UserPromptSubmit` list in ~/.claude/settings.json:

```json
{"hooks": [{"type": "command", "command": "python3 -I \"$HOME/.claude/skills/lean-kb/hooks/lean_kb_hook.py\"", "timeout": 5}]}
```

A session that is in operation can keep its old hook settings. Start a new session after you register the hook.

- Start condition: the prompt has a keyword from the list KEYWORDS. Latin keywords match as full words. The match ignores case. A URL does not count.
- Korean keywords also match inside a longer word.
- The hook adds no note to a prompt that starts with `!` or with a side-agent note. Text inside a host notification block does not count.
- If no keyword matches, the hook prints nothing.
- Disable switch 1: set the environment variable LEAN_KB_DISABLE to 1.
- Disable switch 2: create a file named lean-kb.off in ~/.claude or in the .claude folder of the project. The hook finds the project from the environment variable CLAUDE_PROJECT_DIR.
- The hook keeps no state. It adds the full note to each matching prompt.
- Cost: the note size multiplied by the number of matching prompts in a session.
- The repeat of the note is contrary to rule 4. Version 1 has no session dedupe.
- Calibration: the author checked the keywords against the past prompts of one user. The hook matched less than one percent of them.
- The words Obsidian, memory, CLAUDE.md, and graph matched unrelated prompts more often. They are not keywords.
- The share of knowledge-base prompts that the hook does not match is not measured.
- Live check: in one Claude Code session with a temporary settings file, a wiki prompt received the note. An unrelated prompt received no note.

## Subagents

The hook runs on prompts that the user submits. A subagent receives its prompt from the parent agent. Thus the note is not expected to reach a subagent. This behavior is not tested. If you delegate knowledge-base work, give the subagent this path: ~/.claude/skills/lean-kb/rules/lean-kb.md

## Limits

- The source is one talk, with small samples from one environment. Check each rule in the target repository.
- The talk did not test the rules on a wiki or an ontology. Rules 8 and 9 are inference.
- Claude Code loads the first 200 lines or 25 KB of MEMORY.md, the limit that comes first. Other tools can have other limits.
- Korean text uses 3 bytes for each character in UTF-8. Thus a Korean index can reach 25 KB before 200 lines.
- The Claude Code documentation says that Claude Code measures MEMORY.md against these limits. Therefore this skill has no index checker.
- This skill is an independent summary. It is not a NAVER project.
- This skill is not the Haema engine. It only keeps design rules.
- The self-test and the gate ran on macOS. Linux and Windows are not tested.
