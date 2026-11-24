# lean-kb
.DEFAULT_GOAL := test
.PHONY: test hook-test

test: ## Run the master gate (needs the asd-ste100 linter, or LEAN_KB_SKIP_STE=1)
	bash gates/verify_lean_kb.sh

hook-test: ## Run only the hook self-test
	bash hooks/lean_kb_hook.test.sh
