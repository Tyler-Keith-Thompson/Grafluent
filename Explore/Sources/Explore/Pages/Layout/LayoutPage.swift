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

    /// The frame that fits every drawing of `drawings` in the view box with a margin, keeping
    /// proportions. One frame for a whole run keeps the camera still while the vertices move.
    init(fitting drawings: some Sequence<Drawing<Int>>, including other: LayoutFrame? = nil) {
        var low = SIMD2<Double>(.infinity, .infinity), high = SIMD2<Double>(-.infinity, -.infinity)
        for drawing in drawings {
            guard let box = drawing.boundingBox else { continue }
            low = pointwiseMin(low, box.min)
            high = pointwiseMax(high, box.max)
        }
        if let other, other.scale != 1 || other.min != .zero {
            low = pointwiseMin(low, other.layout(SIMD2(30, 30)))
            high = pointwiseMax(high, other.layout(SIMD2(610, 410)))
        }
        guard low.x <= high.x else { return }
        let box = (min: low, max: high)
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
    /// The seed of the random start: the same on the build machine and in the browser, so the
    /// first frame is the one the browser plays from. Only Draw again changes it.
    var seed: UInt64 = 1
    /// Every drawing of the current run, the start first.
    var frames: [(drawing: Drawing<Int>, temperature: Double)] = []
    /// The vertex being dragged, and the frame its view-box coordinates are read in.
    var dragging: Int?
    @ReactiveIgnored var dragFrame = LayoutFrame()
    /// The camera for the current run: fitted to every frame, so it never moves mid-run.
    @ReactiveIgnored var viewFrame = LayoutFrame()
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 40)

    init() { restart() }

    /// A new run from the random start that `seed` gives, played from the start.
    func restart() {
        frames = trajectory(of: startLayout(choice, seed: seed))
        viewFrame = LayoutFrame(fitting: frames.map(\.drawing))
        playback.reset(count: frames.count - 1)
        playback.play()
    }

    /// A new run from the next seed's random start.
    func drawAgain() {
        seed += 1
        restart()
    }

    func choose(_ n: Int) {
        choice = n
        restart()
    }

    /// The drawing on screen.
    var drawing: Drawing<Int> { frames[min(playback.k, frames.count - 1)].drawing }

    /// Moves `vertex` to the view-box point. While the vertex is held only it moves; on release
    /// the layout runs on from there, in a frame that keeps the current view unless the run
    /// needs more room.
    func drag(_ vertex: Int, to point: (x: Double, y: Double)) {
        let target = dragFrame.layout(SIMD2(point.x, point.y))
        var positions = drawing.positions
        positions[drawing.vertices.firstIndex(of: vertex)!] = target
        frames = [(Drawing(vertices: drawing.vertices, positions: positions), frames[min(playback.k, frames.count - 1)].temperature)]
        playback.reset(count: 0)
    }

    /// Runs the layout on from the drawing the drag left.
    func release(_ vertex: Int) {
        let point = drawing.positions[drawing.vertices.firstIndex(of: vertex)!]
        frames = trajectory(of: Explore.drag(drawing, choice: choice, vertex: vertex, to: point))
        viewFrame = LayoutFrame(fitting: frames.map(\.drawing), including: viewFrame)
        playback.reset(count: frames.count - 1)
        playback.play()
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
        let frame = model.dragging == nil ? model.viewFrame : model.dragFrame
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
                    layoutModel.dragFrame = layoutModel.viewFrame
                    layoutModel.dragging = v
                }
                ._onEvent(PointerMoveEvent.self) { event in
                    guard let v = layoutModel.dragging, let point = event.viewBoxPoint(width: 640) else { return }
                    layoutModel.drag(v, to: point)
                }
                ._onEvent(PointerUpEvent.self) { _ in
                    guard let v = layoutModel.dragging else { return }
                    layoutModel.dragging = nil
                    layoutModel.release(v)
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
                button(.type(.button)) { "Draw again" }
                    .onClick { layoutModel.drawAgain() }
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
            snippets: [.layoutImports, .layoutFamilies, Snippet(lines: ["let choice = \(model.choice)  // \(families[model.choice].name)", "let seed: UInt64 = \(model.seed)"]), .layoutStart, .layoutStep, .layoutDrag],
            results: [])
    }
}

enum LayoutPage {
    static func mount() {
        mountView(LayoutLab(), in: "app")
        mountView(LayoutCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.fruchtermanReingold, Names.eades, Names.kamadaKawai]), in: "names")
    }
}
