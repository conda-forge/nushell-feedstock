use std/assert

print $"vendor-autoload-dirs:"
print ($nu.vendor-autoload-dirs)
print $"NU_LIB_DIRS:"
print ($NU_LIB_DIRS)

let expected = ($env.CONDA_PREFIX | path join "share" "nushell" "lib")
assert ($expected in $NU_LIB_DIRS) $"NU_LIB_DIRS should contain ($expected)"
