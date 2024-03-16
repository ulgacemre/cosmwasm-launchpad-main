workspaces := "./packages ./contracts "

# Displays available recipes by running `just -l`.
setup:
  #!/usr/bin/env bash
  just -l

# Install wasm target, nibid, and pricefeeder
install:
  # https://crates.io/crates/clippy
  rustup component add clippy
  # https://crates.io/crates/cargo-llvm-cov
  cargo install cargo-llvm-cov
  rustup target add wasm32-unknown-unknown
  curl -s https://get.nibiru.fi/@v0.21.11! | bash
  curl -s https://get.nibiru.fi/pricefeeder! | bash

wasm-all:
  bash scripts/wasm-out.sh


deploy-all:
  bash scripts/deploy.sh

# Move binding artifacts to teh local nibiru wasmbin
wasm-export:
  bash scripts/wasm-export.sh

# Compiles a single CW contract to wasm bytecode.
# wasm-single:
#   bash scripts/wasm-out.sh --single

# Runs rustfmt
fmt:
  cargo fmt --all

# Runs rustfmt without updating
fmt-check:
  cargo fmt --all -- --check

# Compiles Rust code
build:
  cargo build

build-update:
  cargo update
  cargo build

# Clean target files and temp files
clean:
  cargo clean

# Run linter + fix
clippy:
  cargo clippy --fix --allow-dirty --allow-staged

# Run linter + check only
clippy-check:
  cargo clippy

# Test a specific package or contract
test *pkg:
  #!/usr/bin/env bash
  set -e;
  if [ -z "{{pkg}}" ]; then
    just test-all
  else
    RUST_BACKGTRACE="1" cargo test --package "{{pkg}}"
  fi

# Test everything in the workspace.
test-all:
  cargo test

# Test everything and output coverage report.
test-coverage:
  cargo llvm-cov --lcov --output-path lcov.info \
    --ignore-filename-regex .*buf\/[^\/]+\.rs$

# Format, lint, and test
tidy:
  just fmt
  just clippy
  just test

# Format, lint, update dependencies, and test
tidy-update: build-update
  just tidy

# Run local instance of the Nibiru blockchain
run-nibiru:
  bash scripts/localnet.sh --no-build

run-pricefeed:
  bash scripts/run_pricefeed.sh

add-key:
  #!/usr/bin/env bash
  export KEY_NAME="test-me"
  add_key() {
    MNEM="guard cream sadness conduct invite crumble clock pudding hole grit liar hotel maid produce squeeze return argue turtle know drive eight casino maze host" 
    echo "$MNEM" | nibid keys add $KEY_NAME --recover --keyring-backend test
  }
  add_key 2> /dev/null
  nibid keys list | jq

# Set up keys and environment variables for nibid
setup-env:
  #!/usr/bin/env bash
  source scripts/setup_env.sh
  echo "WASM: $WASM"
  echo "KEY_NAME: $KEY_NAME"

# Run the server for the slide presentation
slides:
  #!/usr/bin/env bash
  source scripts/lib.sh
  if ! which_ok marp; then
    echo "Installing @marp-team/marp-cli"
  else 
    marp --server . --theme theme.css 
    exit 0
  fi

  binary=""
  if ! which_ok bun && ! which_ok yarn && ! which_ok npm; then
      echo "Neither bun, npm, nor yarn is installed."
      # Install bun
      curl -fsSL https://bun.sh/install | bash
      binary="bun"
  elif which_ok bun; then 
      binary="bun"
  elif which_ok yarn; then 
      binary="yarn"
  elif which_ok npm; then 
      binary="npm"
  else 
    echo "Failed to initialize JS binary" >&2
    exit 1 
  fi
  
  $binary install @marp-team/marp-cli 
  $binary run marp --server . --theme theme.css
