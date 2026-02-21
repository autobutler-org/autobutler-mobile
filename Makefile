SHELL := /bin/bash
.SHELLFLAGS = -e -c
.DEFAULT_GOAL := help
.ONESHELL:
.SILENT:

.PHONY: $(MAKECMDGOALS)

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

clean:
	echo "Cleaning build artifacts..."

setup: setup/flutter ## Setup development environment

setup/flutter: ## Install go tools
	echo "Setting up Flutter environment..."

build: ## Build mobile app
	echo "Building mobile app..."

test: test/unit test/e2e

test/unit: ## Run unit tests
	echo "Running unit tests..."

test/e2e:
	echo "Running end-to-end tests..."

format: format/dart ## Format code

format/dart: ## Format Dart code
	echo "Formatting Dart code..."

check: check/dart ## Check code

check/dart: ## Check Dart code
	echo "Checking Dart code..."

fix: fix/dart ## Fix code issues

fix/dart: ## Fix Dart code issues
	echo "Fixing Dart code issues..."

env-%: ## Check for env var
	if [ -z "$($*)" ]; then \
		echo "Error: Environment variable '$*' is not set."; \
		exit 1; \
	fi

help: ## Displays help info
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
