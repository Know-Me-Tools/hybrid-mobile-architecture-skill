mod bundle;
mod cli;
mod engine;
mod model;

pub use cli::Cli;

use anyhow::Result;

pub fn execute(cli: Cli) -> Result<()> {
    engine::execute(cli)
}
