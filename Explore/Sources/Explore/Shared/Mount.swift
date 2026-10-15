import ElementaryUI
import JavaScriptKit

// Every view of a page is drawn twice: once at build time, by this package built for the build
// machine, into the page's HTML (its first frame, before any WebAssembly arrives), and once in the
// browser, where ElementaryUI mounts it in the same element in place of that first frame.

#if arch(wasm32)
/// Whether the page has an element with id `id`.
func present(_ id: String) -> Bool {
    JSObject.global.document.getElementById(id).object != nil
}

/// Mounts `view` on the element with id `id`, replacing the first frame the build drew there.
/// Mounting commits in a microtask, so no frame is painted between the two.
func mountView(_ view: some View, in id: String) {
    guard let element = JSObject.global.document.getElementById(id).object else { return }
    _ = element.replaceChildren!()
    _ = element.removeAttribute!("data-loading")
    _ = element.removeAttribute!("aria-busy")
    Application(view).mount(in: .init(stringLiteral: "#" + id))
}
#else
/// Every element a figure sample can go in is drawn; the build keeps those the page has.
func present(_ id: String) -> Bool { true }

/// The first frame of each mounted view, by the id of the element it goes in.
nonisolated(unsafe) var firstFrames: [(id: String, html: String)] = []

/// Draws `view` as HTML for the element with id `id`.
func mountView(_ view: some View, in id: String) {
    firstFrames.append((id, view.render()))
}
#endif
