#!/bin/sh
# Builds the explorer as release WebAssembly, optimized for size, into Explore/dist/: the pages,
# their stylesheet, the one .wasm they share, and the JavaScript that loads it, all as plain files
# with relative URLs. Run through `just explore`; see README.md.
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

# PackageToJS strips debug info and runs wasm-opt when it is on PATH. Without swiftly (as in CI,
# where the toolchain is the container's), the `swift` on PATH must be $VERSION.
cd "$HERE"
if [ -x "$SWIFTLY" ]; then
    "$SWIFTLY" run swift package --swift-sdk "$SDK" -Xswiftc -Osize \
        js -c release --product Explore "+$VERSION"
else
    swift --version 2>&1 | grep -q "Swift version $VERSION " || { echo "swift on PATH is not $VERSION" >&2; exit 1; }
    swift package --swift-sdk "$SDK" -Xswiftc -Osize js -c release --product Explore
fi

if command -v wasm-opt >/dev/null; then
    wasm-opt -Oz --enable-bulk-memory --enable-sign-ext --enable-mutable-globals --enable-nontrapping-float-to-int \
        --strip-debug --strip-producers "$OUT/Explore.wasm" -o "$OUT/Explore.wasm"
fi

rm -rf "$DIST"
mkdir -p "$DIST/platforms" "$DIST/vendor"
cp "$HERE/web/explore.css" "$DIST/"
cp -R "$HERE/web/vendor/browser_wasi_shim" "$DIST/vendor/"
cp "$OUT/Explore.wasm" "$OUT/index.js" "$OUT/instantiate.js" "$OUT/runtime.js" "$OUT/bridge-js.js" "$DIST/"
# The WASI shim is imported by package name; point it at the vendored copy so no bundler or
# import map is needed.
sed "s#'@bjorn3/browser_wasi_shim'#'../vendor/browser_wasi_shim/index.js'#" \
    "$OUT/platforms/browser.js" > "$DIST/platforms/browser.js"
grep -q "../vendor/browser_wasi_shim/index.js" "$DIST/platforms/browser.js"

# Each page is web/pages/<name>.html: a title and a description comment, then the body, poured
# into web/template.html as <name>.html. web/contents.txt gives the reading order: the index's
# contents list (its @CONTENTS@ line) and each page's previous and next links come from it. The
# index loads no WebAssembly.
CONTENTS="$HERE/web/contents.txt"
for name in $(grep -v '^#' "$CONTENTS" | awk -F'|' '$5 == "page" { print $1 }'); do
    [ -f "$HERE/web/pages/$name.html" ] || { echo "contents.txt lists $name, but web/pages/$name.html is missing" >&2; exit 1; }
done
for page in "$HERE"/web/pages/*.html; do
    name=$(basename "$page" .html)
    if [ "$name" != index ] && ! grep -q "^$name|.*|page\$" "$CONTENTS"; then
        echo "web/pages/$name.html is not a page row in contents.txt" >&2
        exit 1
    fi
    title=$(sed -n '1s/^<!-- title: \(.*\) -->$/\1/p' "$page")
    description=$(sed -n '2s/^<!-- description: \(.*\) -->$/\1/p' "$page")
    if [ -z "$title" ] || [ -z "$description" ]; then
        echo "$page must start with a title and a description comment" >&2
        exit 1
    fi
    tail -n +3 "$page" > "$DIST/.body"
    awk -v title="$title" -v description="$description" -v name="$name" -v body="$DIST/.body" -v contents="$CONTENTS" '
        BEGIN {
            FS = "|"
            while ((getline line < contents) > 0) {
                if (line ~ /^#/ || line == "") continue
                split(line, f, "|")
                n++; slug[n] = f[1]; heading[n] = f[2]; group[n] = f[3]; summary[n] = f[4]; status[n] = f[5]
            }
            # The contents list, a section per group.
            list = "<nav class=\"contents\" id=\"contents\" aria-label=\"Contents\">\n  <h2>Contents</h2>"
            for (i = 1; i <= n; i++) {
                if (i == 1 || group[i] != group[i - 1]) {
                    if (i > 1) list = list "\n    </ol>\n  </section>"
                    list = list "\n  <section class=\"group\">\n    <h3>" group[i] "</h3>\n    <ol>"
                }
                if (status[i] == "page")
                    list = list "\n      <li><a href=\"" slug[i] ".html\"><b>" heading[i] "</b><span>" summary[i] "</span></a></li>"
                else
                    list = list "\n      <li><div class=\"soon\"><b>" heading[i] "</b><span>" summary[i] "</span><i>Coming soon</i></div></li>"
            }
            list = list "\n    </ol>\n  </section>\n</nav>"
            # The menu of every page, grouped, the current one marked.
            menu = "    <details class=\"menu\"><summary><span class=\"burger\" aria-hidden=\"true\"></span><span class=\"mlabel\">All pages</span></summary>"
            menu = menu "\n      <nav class=\"mpanel\" aria-label=\"All pages\"><a class=\"mhome\" href=\"./\"" (name == "index" ? " aria-current=\"page\"" : "") ">Contents</a>"
            for (i = 1; i <= n; i++) {
                if (i == 1 || group[i] != group[i - 1]) {
                    if (i > 1) menu = menu "</div>"
                    menu = menu "\n        <div class=\"mgroup\"><span>" group[i] "</span>"
                }
                if (status[i] == "page")
                    menu = menu "<a href=\"" slug[i] ".html\"" (slug[i] == name ? " aria-current=\"page\"" : "") ">" heading[i] "</a>"
                else
                    menu = menu "<i>" heading[i] " (soon)</i>"
            }
            menu = menu "</div>\n      </nav>\n    </details>"
            # Previous and next among the pages that exist.
            pager = ""
            if (name != "index") {
                prev = ""; following = ""; found = 0
                for (i = 1; i <= n; i++) {
                    if (status[i] != "page") continue
                    if (slug[i] == name) { found = 1; continue }
                    if (!found) prev = i
                    else if (following == "") following = i
                }
                pager = "<nav class=\"pager\" aria-label=\"Pages\">"
                pager = pager (prev != "" ? "<a class=\"prev\" href=\"" slug[prev] ".html\"><span>Previous</span>" heading[prev] "</a>" : "<a class=\"prev\" href=\"./\"><span>Previous</span>Contents</a>")
                pager = pager (following != "" ? "<a class=\"next\" href=\"" slug[following] ".html\"><span>Next</span>" heading[following] "</a>" : "<a class=\"next\" href=\"./#contents\"><span>Next</span>Contents</a>")
                pager = pager "</nav>"
            }
        }
        /<!-- wasm -->/ { if (name == "index") { skip = 1 }; next }
        /<!-- end wasm -->/ { skip = 0; next }
        skip { next }
        /^@BODY@$/ {
            while ((getline line < body) > 0) { if (line ~ /^ *@CONTENTS@$/) print list; else print line }
            next
        }
        /^@PAGER@$/ { print pager; next }
        /^@MENU@$/ { print menu; next }
        { gsub(/@TITLE@/, title); gsub(/@DESCRIPTION@/, description); gsub(/@PAGE@/, name); print }
    ' "$HERE/web/template.html" > "$DIST/$name.html"
done
rm "$DIST/.body"

# Pages hosts limit each file to 15 MB.
find "$DIST" -type f -size +15M -exec sh -c 'echo "$1 is over 15 MB" >&2; exit 1' _ {} \;
echo "Explore/dist:"
(cd "$DIST" && find . -type f | sort | while read -r f; do printf '%10s  %s\n' "$(wc -c < "$f" | tr -d ' ')" "${f#./}"; done)
