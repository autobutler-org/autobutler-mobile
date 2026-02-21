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
	flutter pub clean

setup: setup/flutter ## Setup development environment

setup/flutter: ## Install go tools
	echo "Flutter suggests you use VSCode for this: https://docs.flutter.dev/install/quick#install"

build: ## Build mobile app
	flutter pub build

test: test/unit ## Run tests

test/unit: ## Run unit tests
	flutter pub test

format: format/dart ## Format code

format/dart: ## Format Dart code
	dart format .

check: check/format/dart check/lint/dart ## Check code

check/format/dart: ## Check code formatting
	dart format --set-exit-if-changed .

check/lint/dart: ## Lint Dart code
	flutter pub analyze

deps: ## Install dependencies
	flutter pub get

env-%: ## Check for env var
	if [ -z "$($*)" ]; then \
		echo "Error: Environment variable '$*' is not set."; \
		exit 1; \
	fi

help: ## Displays help info
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
