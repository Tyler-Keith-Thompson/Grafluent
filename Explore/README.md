# Explore

An interactive page for Dijkstra's algorithm that runs Grafluent itself in the browser. The town
graph is built with the result builder, `dijkstraSearch` produces the event timeline, and every
control (step, play, back, scrub, start place, destination, the places and the timeline marbles)
changes Swift state. The interface is written with
[ElementaryUI](https://github.com/elementary-swift/elementary-ui) and compiled with the rest to
WebAssembly.

This is a separate SwiftPM package; Bazel ignores it.

## Requirements

- [swiftly](https://www.swift.org/install/) with the Swift 6.3.3 toolchain:
  `swiftly install 6.3.3`.
- The matching Swift SDK for WebAssembly from swift.org:

  ```sh
  swiftly run swift sdk install \
      https://download.swift.org/swift-6.3.3-release/wasm-sdk/swift-6.3.3-RELEASE/swift-6.3.3-RELEASE_wasm.artifactbundle.tar.gz \
      --checksum cabfa08b73bb8ac783927ecd15fa386e99d0c139c5f232445067bcf58379cae7 +6.3.3
  ```

- `wasm-opt` from binaryen (`brew install binaryen`) to optimize the binary. The build still
  works without it, with a larger `.wasm`.

## Build

```sh
just explore
```

This builds release WebAssembly at `-Osize`, strips it and runs `wasm-opt -Oz`, and writes
`Explore/dist/`: `index.html`, `dijkstra.css`, `Explore.wasm`, the JavaScriptKit glue
(`index.js`, `instantiate.js`, `runtime.js`, `bridge-js.js`, `platforms/browser.js`) and the
vendored WASI shim (`vendor/browser_wasi_shim/`). Every URL is relative, so `dist/` works from
any directory, such as `/Grafluent/explore/` on GitHub Pages. Nothing is loaded from another
host except the Google Fonts stylesheet.

If the swift.org toolchain crashes compiling a package manifest against a newer Xcode's macOS
SDK, point the build at an older Xcode: `EXPLORE_XCODE=/Applications/Xcode-26.2.0.app just explore`.
`GRAFLUENT_EXPLORE_SWIFT` and `GRAFLUENT_EXPLORE_SDK` choose another toolchain version and SDK.

## Serve

```sh
cd Explore/dist && python3 -m http.server 8000
```

Then open <http://localhost:8000/>. The page must be served over HTTP; browsers do not load
WebAssembly modules from `file://` URLs.

## Layout

| Path | Holds |
|---|---|
| `Sources/Explore/Town.swift` | The town: minutes per street and the graph, the code the page shows |
| `Sources/Explore/Explorer.swift` | The shared state, and the timeline read from `dijkstraSearch` |
| `Sources/Explore/Views.swift` | The map, panels, controls and the code panel |
| `Sources/Explore/DOMEvents.swift` | Click and key handlers for the places and marbles inside the SVGs |
| `web/` | The page, its stylesheet and the vendored WASI shim (MIT or Apache-2.0) |
| `build.sh` | What `just explore` runs |

## Versions

- ElementaryUI 0.7.0 (with Elementary 0.8.2), the newest release that builds with Swift 6.3;
  0.8.0 needs Swift 6.4.
- JavaScriptKit 0.58.0, the version ElementaryUI 0.7.0 allows.
- swift-collections 1.6, which ElementaryUI 0.7.0 was written against.
- `@bjorn3/browser_wasi_shim` 0.3.0, the version JavaScriptKit's packager targets.

The app uses the full WebAssembly SDK, not the Embedded Swift one: Grafluent uses existential
types, which Embedded Swift does not support.
