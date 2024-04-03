#!/usr/bin/env bash

export OPENSSL_DIR=$PREFIX
export CARGO_BUILD_RUSTFLAGS="${CARGO_BUILD_RUSTFLAGS} -L$PREFIX/lib"

cargo-bundle-licenses \
    --format yaml \
    --output THIRDPARTY_LICENSES.yaml

# TODO: add --locked on next release
cargo install --features dataframe,extra --root "$PREFIX" --path .

"$STRIP" "$PREFIX/bin/nu"
