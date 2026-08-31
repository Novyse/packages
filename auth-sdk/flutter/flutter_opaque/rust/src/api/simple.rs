#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(init, sync)]
pub fn init_app() {
    #[cfg(target_family = "wasm")]
    console_error_panic_hook::set_once();
}
