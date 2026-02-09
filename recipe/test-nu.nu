use std/assert

print $"vendor-autoload-dirs: ($nu.vendor-autoload-dirs)"
print $"NU_LIB_DIRS: ($env.NU_LIB_DIRS? | default 'NOT SET')"

let expected = ($env.CONDA_PREFIX | path join "share" "nushell" "lib")
assert ($expected in $env.NU_LIB_DIRS) $"NU_LIB_DIRS should contain ($expected)"
