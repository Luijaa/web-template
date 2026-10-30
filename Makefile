# Single entry point for humans, agents and CI.
# Replace each "not configured" recipe once the stack is chosen (see docs/adr/0001-stack.md).
.PHONY: help setup lint test e2e dast build license docs-check pr-size decision-check release-draft up down check

COMPOSE ?= docker compose

help: ## list targets
	@grep -E '^[a-z0-9-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-14s %s\n", $$1, $$2}'

setup: ## install dependencies
	@echo "setup: not configured — choose a stack first (docs/adr/0001-stack.md)"; exit 1

lint: ## lint + format check + SAST rules (docs/testing.md)
	@echo "lint: not configured — choose a stack first (docs/adr/0001-stack.md)"; exit 1

test: ## unit/integration tests
	@echo "test: not configured — choose a stack first (docs/adr/0001-stack.md)"; exit 1

e2e: ## end-to-end tests on the production image (docs/testing.md)
	@echo "e2e: not configured — see docs/testing.md"; exit 1

dast: ## ZAP baseline scan of the running production image (docs/testing.md)
	@echo "dast: not configured — see docs/testing.md"; exit 1

build: ## build container images
	$(COMPOSE) build

license: ## open-source license check (docs/dependencies.md)
	@echo "license: not configured — see docs/dependencies.md"; exit 1

docs-check: ## structure of design docs, ADRs and the docs index (docs/design-process.md)
	python3 scripts/check-docs.py

pr-size: ## non-test lines added vs main — slice-size rule ~800 (docs/design-process.md section 4)
	./scripts/pr-size.sh

decision-check: ## ADR/doc triggers in this branch; fails on env vars missing from .env.example (docs/adr/README.md)
	./scripts/decision-check.sh

release-draft: ## draft the next CHANGELOG section from merged PRs — prints only (docs/release.md)
	python3 scripts/prepare-release.py

up: ## run locally
	$(COMPOSE) up -d

down: ## stop local stack
	$(COMPOSE) down

check: docs-check lint test build license ## everything CI runs — must pass before a PR
