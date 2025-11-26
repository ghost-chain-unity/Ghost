fn main() {
    // Skip WASM build if SKIP_WASM_BUILD is set (Phase 1: native-only)
    if std::env::var("SKIP_WASM_BUILD").is_ok() {
        println!("cargo:warning=Skipping WASM build (SKIP_WASM_BUILD=1) - Phase 1 native only");
        return;
    }

    #[cfg(feature = "std")]
    {
        #[cfg(feature = "metadata-hash")]
        {
            substrate_wasm_builder::WasmBuilder::init_with_defaults()
                .enable_metadata_hash("UNIT", 12)
                .build();
        }

        #[cfg(not(feature = "metadata-hash"))]
        {
            substrate_wasm_builder::WasmBuilder::build_using_defaults();
        }
    }
}
