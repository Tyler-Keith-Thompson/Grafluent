#if !arch(wasm32)
import ElementaryUI
import Foundation

/// Fills the mount points of `<dist>/<page>.html` for each page named after `dist` with the HTML
/// of that page's first frame, and marks each `data-loading` and `aria-busy` until the
/// WebAssembly mounts there. A mount point is an empty element, `<tag id="…" …></tag>`.
func writeFirstFrames(arguments: [String]) {
    guard let dist = arguments.first else { fail("usage: Explore <dist> <page>…") }
    for name in arguments.dropFirst() {
        let url = URL(fileURLWithPath: dist).appendingPathComponent(name + ".html")
        guard var html = try? String(contentsOf: url, encoding: .utf8) else { fail("cannot read \(url.path)") }
        firstFrames = []
        guard mountPage(name) else { fail("no explorer page is called \(name)") }
        for frame in firstFrames {
            guard let open = html.range(of: " id=\"\(frame.id)\"") else { continue }
            guard let tagEnd = html[open.upperBound...].firstIndex(of: ">"),
                  let tagStart = html[..<open.lowerBound].lastIndex(of: "<") else { fail("\(name): malformed #\(frame.id)") }
            let tag = html[html.index(after: tagStart)...].prefix { $0.isLetter }
            let body = html.index(after: tagEnd)
            guard html[body...].hasPrefix("</\(tag)>") else { fail("\(name): #\(frame.id) is not empty") }
            html.insert(contentsOf: frame.html, at: body)
            html.insert(contentsOf: " data-loading aria-busy=\"true\"", at: open.upperBound)
        }
        do { try html.write(to: url, atomically: true, encoding: .utf8) } catch { fail("cannot write \(url.path)") }
    }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

// ElementaryUI draws its event handlers only into a live DOM, so on the build machine these
// stand in for the ones the pages use: each keeps the element and drops the handler, which a
// first frame has no use for. A member of the element type is chosen over ElementaryUI's member
// of `View`, being the more specific.
extension HTMLElement where Content: _Mountable {
    func onClick(_ handler: @escaping () -> Void) -> Self { self }
    func onInput(_ handler: @escaping (InputEvent) -> Void) -> Self { self }
}

extension HTMLVoidElement {
    func onInput(_ handler: @escaping (InputEvent) -> Void) -> Self { self }
}

extension SVGElement where Tag == SVGTag.svg, Content: _Mountable {
    func _onEvent<Config: _DOMEventHandlerConfig>(_ type: Config.Type, handler: @escaping (Config.Event) -> Void) -> Self { self }
}
#endif
