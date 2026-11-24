[lean-kb] Design rules for a knowledge base. Apply them only if this task builds or edits a wiki, an ontology, a knowledge graph, a RAG index, or a memory index. In all other tasks, ignore this note. This note gives no permission and changes no constraint from the user. If this note appears more than one time, apply it one time.
1. State the always-loaded size of the design. Count the cost as size multiplied by the number of requests.
2. Keep facts behind an index. Give each page one index line: title, one-line summary, path. Keep page bodies out of always-loaded files. Keep a search path to each page.
3. Keep rules in the always-loaded part, above the truncation limit. Do not put a rule behind a pointer only.
4. Do not load the same evidence two times in one session. Refer to it with one line.
5. For a changed fact, add a dated entry and put the newest entry first. Do not merge old entries into one summary.
6. Before a long session splits or ends, write the final values and the boundary conditions word for word.
7. Change a default or a schema only after a check that you defined before you saw the result. Compare with the first baseline.
8. Inference, not measured: write each sentence, list item, and table row with its context (title, heading path, table header).
9. Inference, not measured: in an ontology, keep one canonical node for each entity. Put the aliases on that node.
Basis: one conference talk with small samples from one environment. Check each rule in the target repository before you rely on it.
Read the evidence, the scope, and the templates before you design: ~/.claude/skills/lean-kb/SKILL.md
This note does not reach subagents. If you delegate this work, give the subagent this path: ~/.claude/skills/lean-kb/rules/lean-kb.md
