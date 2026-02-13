#!/usr/bin/env nu

# Tell `pixi global` to not set CONDA_PREFIX during activation
# https://pixi.sh/dev/global_tools/introduction/#opt-out-of-conda_prefix
mkdir $'($env.PREFIX)/etc/pixi/nu'
touch $'($env.PREFIX)/etc/pixi/nu/global-ignore-conda-prefix'

$env.OPENSSL_DIR = $env.PREFIX
$env.CARGO_BUILD_RUSTFLAGS = $'($env.CARGO_BUILD_RUSTFLAGS?) -L($env.PREFIX)/lib'
$env.CARGO_PROFILE_RELEASE_STRIP = "symbols"

# Conda will handle prefix replacement at install time.
let nu_lib_dir = [$env.PREFIX "share" "nushell" "lib"] | path join

if $env.target_platform == "win-64" {
    # prefix replacement doesn't work in this json because it needs \\ instead of \
    # otherwise a broken json will be generated
    let activate_d = $'($env.PREFIX)/etc/conda/activate.d'
    let deactivate_d = $'($env.PREFIX)/etc/conda/deactivate.d'
    mkdir $activate_d
    mkdir $deactivate_d

    $'@echo off
set "NU_LIB_DIRS_CONDA_BACKUP=%NU_LIB_DIRS%"
set "NU_LIB_DIRS=($nu_lib_dir)"
' | save -f $'($activate_d)/nushell_activate.bat'

    $'@echo off
set "NU_LIB_DIRS=%NU_LIB_DIRS_CONDA_BACKUP%"
set "NU_LIB_DIRS_CONDA_BACKUP="
' | save -f $'($deactivate_d)/nushell_deactivate.bat'

    $'export NU_LIB_DIRS_CONDA_BACKUP="${NU_LIB_DIRS:-}"
export NU_LIB_DIRS="($nu_lib_dir)"
' | save -f $'($activate_d)/nushell_activate.sh'

    $'export NU_LIB_DIRS="$NU_LIB_DIRS_CONDA_BACKUP"
unset NU_LIB_DIRS_CONDA_BACKUP
if [ -z $NU_LIB_DIRS ]; then
    unset NU_LIB_DIRS
fi
' | save -f $'($deactivate_d)/nushell_deactivate.sh'
} else {
    mkdir $'($env.PREFIX)/etc/conda/env_vars.d'
    {NU_LIB_DIRS: $nu_lib_dir} | to json -r | save -f $'($env.PREFIX)/etc/conda/env_vars.d/nushell.json'
}

# Directory that contains `nu` code
let nu_path = '.' | path expand

# Directory list for `nu_plugin_*` code
# Logic to identify plugin folder taken from nushell's homebrew formula
# https://github.com/Homebrew/homebrew-core/blob/566df2fba07c4100481cfc893ebe7c55f7306bc9/Formula/n/nushell.rb#L42-L43
let nu_plugin_paths = glob 'crates/nu_plugin_*'
  | where ($'($it)/Cargo.toml' | path exists)
  | path expand

let license_dir = './license-files' | path expand
mkdir $license_dir

$nu_path
# | append $nu_plugin_paths
| each {
  let license_file = $in | path parse | get stem | $'($license_dir)/($in)_thirdparty_licenses.yaml'

  cd $in
  ^cargo auditable install --debug --locked --no-track --bins --root $env.PREFIX --path .
  ^cargo-bundle-licenses --format yaml --output $license_file
}
