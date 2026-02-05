gen:
	scripts/gen-bindings.sh

build-core:
	cargo build --manifest-path crates/core/Cargo.toml

build:
	$(MAKE) gen
	$(MAKE) build-core
	swift build --package-path app

run:
	$(MAKE) kill
	$(MAKE) build
	@APP_DIR=./app/.build/debug/Grit.app; \
	APP_MACOS=$$APP_DIR/Contents/MacOS; \
	APP_RES=$$APP_DIR/Contents/Resources; \
	mkdir -p $$APP_MACOS $$APP_RES; \
	cp -f ./app/.build/debug/Grit $$APP_MACOS/Grit; \
	cp -f ./app/Info.plist $$APP_DIR/Contents/Info.plist; \
	cp -f ./app/Config.json $$APP_RES/Config.json; \
	open $$APP_DIR

kill:
	-killall Grit 2>/dev/null || true
