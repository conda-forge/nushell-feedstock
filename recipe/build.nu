#!/usr/bin/env nu

# Tell `pixi global` to not set CONDA_PREFIX during activation
# https://pixi.sh/dev/global_tools/introduction/#opt-out-of-conda_prefix
mkdir $'($env.PREFIX)/etc/pixi/nu'
touch $'($env.PREFIX)/etc/pixi/nu/global-ignore-conda-prefix'

$env.OPENSSL_DIR = $env.PREFIX
$env.CARGO_BUILD_RUSTFLAGS = $'($env.CARGO_BUILD_RUSTFLAGS?) -L($env.PREFIX)/lib'
$env.CARGO_PROFILE_RELEASE_STRIP = "symbols"

# Directory that contains the nu executable
let nu_path = '.'

# Directory list for nu-plugin executables
# 
# Logic to identify plugin folder taken from homebrew formula
# https://github.com/Homebrew/homebrew-core/blob/566df2fba07c4100481cfc893ebe7c55f7306bc9/Formula/n/nushell.rb#L42-L43
let nu_plugin_paths = glob 'crates/nu_plugin_*'
  | where (
    $'($it)/Cargo.toml'
    | path exists
  )

$nu_path | append $nu_plugin_paths | each {
  ^cargo auditable install --locked --no-track --bins --root $env.PREFIX --path $in
}

^cargo-bundle-licenses --format yaml --output ./THIRDPARTY_LICENSES.yaml
