build-core:
	cargo build --manifest-path crates/core/Cargo.toml

gen:
	scripts/gen-bindings.sh

run:
	xcodebuild -scheme Grit -destination 'platform=macOS' -derivedDataPath .build -packagePath app build
