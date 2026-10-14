#!/bin/sh
# Builds the explorer as release WebAssembly, optimized for size, into Explore/dist/: the page,
# its stylesheet, the .wasm, and the JavaScript that loads it, all as plain files with relative
# URLs. Run through `just explore`; see README.md.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
VERSION=${GRAFLUENT_EXPLORE_SWIFT:-6.3.3}
SDK=${GRAFLUENT_EXPLORE_SDK:-swift-$VERSION-RELEASE_wasm}
SWIFTLY=$(command -v swiftly || echo "$HOME/.swiftly/bin/swiftly")
# PackageToJS writes here by default; its plugin sandbox allows no other path in the package.
OUT="$HERE/.build/plugins/PackageToJS/outputs/Package"
DIST="$HERE/dist"

# A swift.org toolchain can fail to compile package manifests against a newer Xcode's macOS SDK;
# EXPLORE_XCODE names an older Xcode to take the SDK from.
if [ -n "${EXPLORE_XCODE:-}" ]; then
    export DEVELOPER_DIR="$EXPLORE_XCODE/Contents/Developer"
    export SDKROOT="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
fi

if ! command -v wasm-opt >/dev/null; then
    echo "wasm-opt (binaryen) is not on PATH; the .wasm will not be optimized." >&2
fi

# PackageToJS strips debug info and runs wasm-opt when it is on PATH.
cd "$HERE"
"$SWIFTLY" run swift package --swift-sdk "$SDK" -Xswiftc -Osize \
    js -c release --product Explore "+$VERSION"

if command -v wasm-opt >/dev/null; then
    wasm-opt -Oz --enable-bulk-memory --enable-sign-ext --enable-mutable-globals --enable-nontrapping-float-to-int \
        --strip-debug --strip-producers "$OUT/Explore.wasm" -o "$OUT/Explore.wasm"
fi

rm -rf "$DIST"
mkdir -p "$DIST/platforms" "$DIST/vendor"
cp "$HERE/web/index.html" "$HERE/web/dijkstra.css" "$DIST/"
cp -R "$HERE/web/vendor/browser_wasi_shim" "$DIST/vendor/"
cp "$OUT/Explore.wasm" "$OUT/index.js" "$OUT/instantiate.js" "$OUT/runtime.js" "$OUT/bridge-js.js" "$DIST/"
# The WASI shim is imported by package name; point it at the vendored copy so no bundler or
# import map is needed.
sed "s#'@bjorn3/browser_wasi_shim'#'../vendor/browser_wasi_shim/index.js'#" \
    "$OUT/platforms/browser.js" > "$DIST/platforms/browser.js"
grep -q "../vendor/browser_wasi_shim/index.js" "$DIST/platforms/browser.js"

# Pages hosts limit each file to 15 MB.
find "$DIST" -type f -size +15M -exec sh -c 'echo "$1 is over 15 MB" >&2; exit 1' _ {} \;
echo "Explore/dist:"
(cd "$DIST" && find . -type f | sort | while read -r f; do printf '%10s  %s\n' "$(wc -c < "$f" | tr -d ' ')" "${f#./}"; done)
