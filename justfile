# MoonBit Project Commands

# Default target (js for browser compatibility)
target := "js"

# Default task: check and test
default: check test

# Format code
fmt:
    moon fmt

# Type check
check:
    moon check --deny-warn --target {{target}}

# Run tests
test:
    moon test --target {{target}}

# Update snapshot tests
test-update:
    moon test --update --target {{target}}

# Run main
run:
    moon run src/main --target {{target}}

# Generate type definition files
info:
    moon info

# Clean build artifacts
clean:
    moon clean
    rm -rf dist
    rm -rf node_modules

# Pre-release check
release-check: clean fmt info check test

# Build for distribution
build: release-check
    pnpm build

# Release new version (tag + push)
release: release-check
    version=$(node -p "require('./package.json').version"); \
    git tag "v${version}"; \
    git push origin "v${version}"; \
    sha=$(git rev-parse "v${version}"); \
    run_id=""; \
    while [ -z "$run_id" ]; do \
        run_id=$(gh run list --workflow npm-publish.yaml --commit "$sha" --limit 1 --json databaseId --jq '.[0].databaseId'); \
        [ -z "$run_id" ] && sleep 2; \
    done; \
    gh run watch "$run_id" --exit-status
