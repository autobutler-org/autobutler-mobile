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

UNAME_S := $(shell uname -s)
FLUTTER_VERSION=$(shell grep -Eo 'flutter: (.+)' pubspec.yaml | sed -E 's/^flutter: (.+)$$/\1/')

##@ Development environment

setup: setup/flutter ## Setup development environment

setup/flutter: ## Install go tools
	if [ -d "${HOME}/flutter" ]; then
		echo "Flutter already installed at ${HOME}/flutter"
		exit 0
	fi
	if [ -z "$(FLUTTER_VERSION)" ]; then
		echo "Error: Could not determine Flutter version from pubspec.yaml"
		exit 1
	fi
	echo "Installing Flutter version $(FLUTTER_VERSION)"
ifeq ($(UNAME_S),Linux)
	sudo apt-get update -y
	sudo apt-get install -y \
		curl \
		git \
		unzip \
		xz-utils \
		zip \
		libglu1-mesa
	curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_$(FLUTTER_VERSION)-stable.tar.xz" | tar -xf -C "${HOME}"
else ifeq ($(UNAME_S),Darwin)
	rm -f flutter.zip
	set -v
	curl --fail -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_arm64_$(FLUTTER_VERSION)-stable.zip" -o flutter.zip
	unzip flutter.zip -d "${HOME}"
	rm -f flutter.zip
else
	$(error "Unsupported OS: $(UNAME_S)")
endif

setup/cocoapods: ## Setup CocoaPods for iOS development
ifeq ($(UNAME_S),Darwin)
	brew install ruby
	$$(brew --prefix)/opt/ruby/bin/gem install cocoapods
	echo "Make sure to put $$(gem env gemdir)/bin in your PATH to use the installed cocoapods"
else
	$(error "CocoaPods setup is only supported on macOS")
endif

setup/ios: setup/cocoapods ## Setup iOS development environment
ifeq ($(UNAME_S),Darwin)
	sudo sh -c 'xcode-select -s /Applications/Xcode.app/Contents/Developer && xcodebuild -runFirstLaunch'
	sudo xcodebuild -license
	xcodebuild -downloadPlatform iOS
	sudo softwareupdate --install-rosetta --agree-to-license
else
	$(error "iOS development environment setup is only supported on macOS")
endif

##@ Development

build: ## Build mobile app
ifeq ($(UNAME_S),Linux)
	make build/android
else ifeq ($(UNAME_S),Darwin)
	make build/ios
else
	$(error "Unsupported OS: $(UNAME_S)")
endif

build/android: ## Build Android app
	flutter build apk --debug

build/ios: ## Build iOS app
	flutter build ios --debug --no-codesign

clean: ## Clean build artifacts
	flutter pub clean

emulate: ## Emulate mobile device
ifeq ($(UNAME_S),Linux)
	make emulate/android
else ifeq ($(UNAME_S),Darwin)
	make emulate/ios
else
	$(error "Unsupported OS: $(UNAME_S)")
endif

ANDROID_DEVICE_ID ?= Pixel_6
IOS_DEVICE_ID ?= apple_ios_simulator

emulate/android: ## Emulate Android device
	flutter emulators --launch $(ANDROID_DEVICE_ID)

emulate/ios: ## Emulate iOS device
	flutter emulators --launch $(IOS_DEVICE_ID)

generate: generate/icons ## Generate assets

generate/icons: ## Generate app icons
	dart run flutter_launcher_icons

refresh: ## Refresh build manifest
	flutter pub get

run: ## Run mobile app
	echo "Will run app on connected device or emulator..."
	flutter run

test: test/unit ## Run tests

test/unit: ## Run unit tests
	flutter test

##@ Code quality

check: check/format/dart check/lint/dart ## Check code

check/format/dart: ## Check code formatting
	dart format --set-exit-if-changed .

check/lint/dart: ## Lint Dart code
	flutter analyze

format: format/dart ## Format code

format/dart: ## Format Dart code
	dart format .

##@ Helpers

help: ## Displays help info
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

env-%: ## Check for env var
	if [ -z "$($*)" ]; then \
		echo "Error: Environment variable '$*' is not set."; \
		exit 1; \
	fi
