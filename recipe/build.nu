#!/usr/bin/env nu

# Tell `pixi global` to not set CONDA_PREFIX during activation
# https://pixi.sh/dev/global_tools/introduction/#opt-out-of-conda_prefix
mkdir $'($env.PREFIX)/etc/pixi/nu'
touch $'($env.PREFIX)/etc/pixi/nu/global-ignore-conda-prefix'

$env.OPENSSL_DIR = $env.PREFIX
$env.CARGO_BUILD_RUSTFLAGS = $'($env.CARGO_BUILD_RUSTFLAGS?) -L($env.PREFIX)/lib'
$env.CARGO_PROFILE_RELEASE_STRIP = "symbols"

$env.NU_VENDOR_AUTOLOAD_DIR = $'($env.PREFIX)/share/nushell/vendor/autoload'
mkdir $env.NU_VENDOR_AUTOLOAD_DIR
cp $'($env.RECIPE_DIR)/set-nu-lib-dirs.nu' $'($env.NU_VENDOR_AUTOLOAD_DIR)/set-nu-lib-dirs.nu'

# Directory that contains `nu` code
let nu_path = '.' | path expand

# Directory list for `nu_plugin_*` code
#
# Logic to identify plugin folder taken from nushell's homebrew formula
# https://github.com/Homebrew/homebrew-core/blob/566df2fba07c4100481cfc893ebe7c55f7306bc9/Formula/n/nushell.rb#L42-L43
let nu_plugin_paths = glob 'crates/nu_plugin_*'
  | where ($'($it)/Cargo.toml' | path exists)
  | path expand

let license_dir = './license-files' | path expand
mkdir $license_dir

$nu_path
| append $nu_plugin_paths
| each {
  let license_file = $in | path parse | get stem | $'($license_dir)/($in)_thirdparty_licenses.yaml'

  cd $in
  ^cargo auditable install --locked --no-track --bins --root $env.PREFIX --path .
  ^cargo-bundle-licenses --format yaml --output $license_file
}
