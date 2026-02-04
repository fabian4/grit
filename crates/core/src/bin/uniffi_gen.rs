use std::env;

use camino::Utf8PathBuf;
use uniffi_bindgen::bindings::{generate_swift_bindings, SwiftBindingsOptions};

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("usage: uniffi_gen <udl_path> <out_dir>");
        std::process::exit(2);
    }

    let udl_path = Utf8PathBuf::from(&args[1]);
    let out_dir = Utf8PathBuf::from(&args[2]);

    let options = SwiftBindingsOptions {
        generate_swift_sources: true,
        generate_headers: true,
        generate_modulemap: true,
        source: udl_path,
        out_dir,
        xcframework: false,
        module_name: Some("GritCoreFFI".to_string()),
        modulemap_filename: Some("module.modulemap".to_string()),
        metadata_no_deps: true,
        link_frameworks: Vec::new(),
    };

    if let Err(err) = generate_swift_bindings(options) {
        eprintln!("uniffi bindgen failed: {err:?}");
        std::process::exit(1);
    }
}
