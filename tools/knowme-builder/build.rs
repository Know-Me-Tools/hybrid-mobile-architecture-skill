fn main() {
    // include_dir embeds these trees. Watch the directories so adding a new
    // resource rebuilds the executable, not only editing an existing file.
    for path in ["../../assets/templates", "../../skills"] {
        println!("cargo:rerun-if-changed={path}");
    }
}
