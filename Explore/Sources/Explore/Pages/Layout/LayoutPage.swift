import ElementaryUI
import GraphDrawing
import JavaScriptKit
import Reactivity

/// How layout coordinates map to the 640 × 440 view box: `view = (layout − min) × scale + offset`.
struct LayoutFrame {
    var min = SIMD2<Double>(0, 0)
    var scale = 1.0
    var offset = SIMD2<Double>(0, 0)

    init() {}

    /// The frame that fits `drawing` in the view box with a margin, keeping its proportions.
    init(fitting drawing: Drawing<Int>) {
        guard let box = drawing.boundingBox else { return }
        let size = box.max - box.min
        let scale = Swift.min(580 / Swift.max(size.x, 1e-9), 380 / Swift.max(size.y, 1e-9))
        self.min = box.min
        self.scale = scale
        self.offset = SIMD2(320, 220) - size * scale / 2
    }

    func view(_ p: SIMD2<Double>) -> SIMD2<Double> { (p - min) * scale + offset }
    func layout(_ v: SIMD2<Double>) -> SIMD2<Double> { (v - offset) / scale + min }
}

@Reactive
final class LayoutModel {
    var choice = 0
    /// Every drawing of the current run, the start first.
    var frames: [(drawing: Drawing<Int>, temperature: Double)] = []
    /// The vertex being dragged, and the frame its view-box coordinates are read in.
    var dragging: Int?
    @ReactiveIgnored var dragFrame = LayoutFrame()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 40)

    init() { restart() }

    /// A new run from random positions, played from the start.
    func restart() {
        frames = trajectory(of: startLayout(choice))
        playback.reset(count: frames.count - 1)
        playback.play()
    }

    func choose(_ n: Int) {
        choice = n
        restart()
    }

    /// The drawing on screen.
    var drawing: Drawing<Int> { frames[min(playback.k, frames.count - 1)].drawing }

    /// Moves `vertex` to the view-box point and runs the layout on from there.
    func drag(_ vertex: Int, to point: (x: Double, y: Double)) {
        let layout = Explore.drag(drawing, choice: choice, vertex: vertex, to: dragFrame.layout(SIMD2(point.x, point.y)))
        frames = trajectory(of: layout)
        playback.reset(count: frames.count - 1)
        playback.show(dragging == nil ? 0 : 1)
        if dragging == nil { playback.play() }
    }
}

let layoutModel = LayoutModel()

/// `x` to four decimal places.
func fourPlaces(_ x: Double) -> String {
    let n = Int((x * 10000).rounded())
    let r = n % 10000
    return "\(n / 10000)." + String(repeating: "0", count: 4 - String(r).count) + "\(r)"
}

@View
struct LayoutLab {
    var body: some View {
        let model = layoutModel
        let graph = families[model.choice].graph
        let playback = model.playback
        let k = playback.k
        let drawing = model.drawing
        let frame = model.dragging == nil ? LayoutFrame(fitting: drawing) : model.dragFrame
        let temperature = model.frames[min(k, model.frames.count - 1)].temperature
        let finished = k == playback.count
        let points = drawing.positions.map { frame.view($0) }
        let index = Dictionary(uniqueKeysWithValues: drawing.vertices.enumerated().map { ($0.element, $0.offset) })
        div {
        section(.class("lab"), .custom(name: "aria-label", value: "Layout")) {
            div(.class("panel stage")) {
                SVG.svg(.class("canvas springs"), .viewBox(0, 0, 640, 440), .custom(name: "role", value: "img"),
                        .custom(name: "aria-label", value: "\(families[model.choice].name), drawn by Fruchterman–Reingold")) {
                    for edge in graph.edges {
                        if let a = index[edge.u], let b = index[edge.v] {
                            SVG.line(.x1(.init(points[a].x)), .y1(.init(points[a].y)), .x2(.init(points[b].x)), .y2(.init(points[b].y)), .class("spring")) {}
                        }
                    }
                    for (i, p) in points.enumerated() {
                        SVG.circle(.cx(.init(points[i].x)), .cy(.init(p.y)), .r(11), .class(model.dragging == drawing.vertices[i] ? "ball held" : "ball"),
                                   .data("vertex", value: "\(drawing.vertices[i])")) {}
                    }
                }
                ._onEvent(PointerDownEvent.self) { event in
                    guard let v = event.integer("data-vertex") else { return }
                    event.preventDefault()
                    event.capturePointer()
                    layoutModel.playback.pause()
                    layoutModel.dragFrame = LayoutFrame(fitting: layoutModel.drawing)
                    layoutModel.dragging = v
                }
                ._onEvent(PointerMoveEvent.self) { event in
                    guard let v = layoutModel.dragging, let point = event.viewBoxPoint(width: 640) else { return }
                    layoutModel.drag(v, to: point)
                }
                ._onEvent(PointerUpEvent.self) { _ in
                    guard layoutModel.dragging != nil else { return }
                    layoutModel.dragging = nil
                    layoutModel.playback.play()
                }
                p(.class("note")) { "Drag any vertex; the springs pull the rest after it." }
            }
            div(.class("side")) {
                div(.class("panel"), .custom(name: "aria-live", value: "off")) {
                    span(.class("label")) { finished ? "At rest" : "Settling" }
                    div(.class("stat")) {
                        div { span(.class("num")) { "\(k)" }; "steps" }
                        div { span(.class("num")) { fourPlaces(temperature) }; "temperature" }
                    }
                    p(.class("note")) { "\(graph.vertexCount) vertices, \(graph.edgeCount) edges. The temperature caps how far a vertex may move in one step; it falls every step until the drawing comes to rest." }
                }
                div(.class("panel")) {
                    label(.class("field"), .for("family")) {
                        "Graph "
                        select(.id("family")) {
                            for (n, family) in families.enumerated() {
                                option(.value("\(n)")) { family.name }.attributes(.selected, when: n == model.choice)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let n = Int(value) { layoutModel.choose(n) }
                        }
                    }
                }
            }
        }
        section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
            div(.class("buttons")) {
                PlaybackButtons(playback: playback)
                span(.class("spacer")) {}
                button(.type(.button)) { "Shuffle" }
                    .onClick { layoutModel.restart() }
            }
            Timeline(
                playback: playback,
                marbles: model.frames.dropFirst().enumerated().map { i, frame in
                    Marble(kind: "m-blue", radius: 2 + min(9, 60 * frame.temperature), title: "Step \(i + 1): temperature \(fourPlaces(frame.temperature))")
                },
                legend: [(Marble(kind: "m-blue", radius: 6), "one step(); smaller as it cools")])
        }
        }
    }
}

@View
struct LayoutCodePanel {
    var body: some View {
        let model = layoutModel
        CodePanel(
            snippets: [.layoutImports, .layoutFamilies, Snippet(lines: ["let choice = \(model.choice)  // \(families[model.choice].name)"]), .layoutStart, .layoutStep, .layoutDrag],
            results: [])
    }
}

enum LayoutPage {
    static func mount() {
        Application(LayoutLab()).mount(in: "#app")
        Application(LayoutCodePanel()).mount(in: "#code")
        Application(NamesStrip(names: [Names.fruchtermanReingold, Names.eades, Names.barnesHut, Names.kamadaKawai, Names.forceAtlas])).mount(in: "#names")
    }
}
