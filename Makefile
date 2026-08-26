# Makefile for kubevirt-ai-helpers

# Container runtime (podman or docker)
CONTAINER_RUNTIME ?= $(shell command -v podman 2>/dev/null || echo docker)

# skillsaw image (pinned version)
SKILLSAW_VERSION := 0.18.0
SKILLSAW_IMAGE = ghcr.io/stbenjam/skillsaw:v$(SKILLSAW_VERSION)

.PHONY: help
help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

.PHONY: badge
badge: ## Regenerate the skillsaw grade badge (.skillsaw-badge.json)
	$(CONTAINER_RUNTIME) run --rm -v $(PWD):/workspace:Z $(SKILLSAW_IMAGE) badge

.PHONY: lint
lint: badge ## Run plugin linter (verbose, strict mode) and refresh the badge
	@echo "Running skillsaw with $(CONTAINER_RUNTIME)..."
	$(CONTAINER_RUNTIME) run --rm -v $(PWD):/workspace:Z $(SKILLSAW_IMAGE) -v --strict

.PHONY: lint-fix
lint-fix: ## Apply skillsaw deterministic autofixes
	$(CONTAINER_RUNTIME) run --rm -v $(PWD):/workspace:Z $(SKILLSAW_IMAGE) fix

.PHONY: lint-pull
lint-pull: ## Pull the pinned skillsaw image
	@echo "Pulling skillsaw image $(SKILLSAW_IMAGE)..."
	$(CONTAINER_RUNTIME) pull $(SKILLSAW_IMAGE)

.PHONY: update
update: ## Update plugin documentation and website data
	@echo "Updating plugin documentation..."
	@python3 scripts/generate_plugin_docs.py
	@echo "Building website data..."
	@python3 scripts/build-website.py

.DEFAULT_GOAL := help
