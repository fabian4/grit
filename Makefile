gen:
	scripts/gen-bindings.sh

build-core:
	cargo build --manifest-path crates/core/Cargo.toml

build:
	$(MAKE) gen
	$(MAKE) build-core
	swift build --package-path app

run:
	$(MAKE) build
	open ./app/.build/debug/Grit
