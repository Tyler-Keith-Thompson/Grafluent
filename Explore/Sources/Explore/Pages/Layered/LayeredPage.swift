import AdjacencyListModule
import ElementaryUI
import GraphDrawing
import GraphProtocols
import Reactivity

/// A point on one layer of the drawing: a vertex, or the `bend`-th bend of the edge at a position.
enum LayerItem: Hashable {
    case vertex(String)
    case bend(edge: Int, index: Int)
}

/// Where each item sits in one picture of the drawing, in drawing units: x along the layer, y the
/// layer (or a row of the starting grid).
typealias LayerPicture = [LayerItem: SIMD2<Double>]

/// The five phases of the Sugiyama framework, each a picture of the pipeline.
enum SugiyamaPhase: Int, CaseIterable {
    case cycles = 1, layers, bends, crossings, coordinates
}

/// The layered page's state: whether the nightly rerun closes a loop, Grafluent's layered
/// drawing, the org chart's form, and the phases' playhead.
@Reactive
final class LayeredModel {
    var rerun = false
    var circular = false
    var graph: AdjacencyList<String>
    var layered: LayeredDrawing<AdjacencyList<String>>
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1600, scrubID: "scrub-sugiyama")

    init() {
        graph = pipeline(rerun: false)
        layered = pipelineDrawing(pipeline(rerun: false))
        playback.reset(count: SugiyamaPhase.allCases.count)
    }

    func setRerun(_ on: Bool) {
        rerun = on
        graph = pipeline(rerun: on)
        layered = pipelineDrawing(graph)
        playback.reset(count: SugiyamaPhase.allCases.count)
        setProperty(id: "layered-rerun", "value", to: on ? "1" : "0")
    }

    /// Each edge's chain of items from its source to its target, self-loops left out.
    var chains: [(edge: Int, items: [LayerItem])] {
        graph.edges.indices.compactMap { p in
            let e = graph.edges[p]
            guard e.source != e.target else { return nil }
            let bends = layered.bends(ofEdgeAt: p)
            return (p, [.vertex(e.source)] + bends.indices.map { .bend(edge: p, index: $0 - bends.startIndex) } + [.vertex(e.target)])
        }
    }

    /// The final drawing's positions of every item.
    var finalPicture: LayerPicture {
        var picture: LayerPicture = [:]
        for v in graph.vertices { picture[.vertex(v)] = layered.drawing.positions[layered.drawing.vertices.firstIndex(of: v)!] }
        for (p, items) in chains {
            let bends = Array(layered.bends(ofEdgeAt: p))
            for (j, item) in items.enumerated() where j > 0 && j < items.count - 1 { picture[item] = bends[j - 1] }
        }
        return picture
    }

    /// The items of each layer in the order `rank` gives, then evenly spaced.
    func spaced(_ items: [LayerItem], layer: (LayerItem) -> Int, by rank: (LayerItem, LayerItem) -> Bool) -> LayerPicture {
        var picture: LayerPicture = [:]
        for l in Set(items.map(layer)) {
            for (i, item) in items.filter({ layer($0) == l }).sorted(by: rank).enumerated() { picture[item] = SIMD2(Double(i), Double(l)) }
        }
        return picture
    }

    /// The picture after phase `k` (0 for the pipeline as given).
    func picture(after k: Int) -> (picture: LayerPicture, withBends: Bool) {
        let vertices = Array(graph.vertices)
        let order: [String: Int] = Dictionary(uniqueKeysWithValues: vertices.enumerated().map { ($0.element, $0.offset) })
        if k <= 1 {
            var picture: LayerPicture = [:]
            for (i, v) in vertices.enumerated() { picture[.vertex(v)] = SIMD2(Double(i % 4) * 1.4, Double(i / 4) * 1.3) }
            return (picture, false)
        }
        let final = finalPicture
        let vertexItems = vertices.map { LayerItem.vertex($0) }
        let allItems = vertexItems + chains.flatMap { $0.items.filter { if case .bend = $0 { return true } else { return false } } }
        func layer(_ item: LayerItem) -> Int { Int(final[item]!.y.rounded()) }
        func given(_ a: LayerItem, _ b: LayerItem) -> Bool {
            switch (a, b) {
            case (.vertex(let x), .vertex(let y)): return order[x]! < order[y]!
            case (.vertex, .bend): return true
            case (.bend, .vertex): return false
            case (.bend(let e, let i), .bend(let f, let j)): return (e, i) < (f, j)
            }
        }
        switch k {
        case 2: return (spaced(vertexItems, layer: layer, by: given), false)
        case 3: return (spaced(allItems, layer: layer, by: given), true)
        case 4: return (spaced(allItems, layer: layer, by: { final[$0]!.x < final[$1]!.x }), true)
        default: return (final, true)
        }
    }

    /// The crossings in `picture` between adjacent layers, edges cut at their bends.
    func crossings(in picture: LayerPicture) -> Int {
        var segments: [(SIMD2<Double>, SIMD2<Double>, LayerItem, LayerItem)] = []
        for (_, items) in chains {
            for j in 0 ..< items.count - 1 {
                var a = picture[items[j]]!, b = picture[items[j + 1]]!
                var ia = items[j], ib = items[j + 1]
                if a.y > b.y { swap(&a, &b); swap(&ia, &ib) }
                if b.y - a.y == 1 { segments.append((a, b, ia, ib)) }
            }
        }
        var count = 0
        for s in segments.indices {
            for t in segments.indices where t > s && segments[s].0.y == segments[t].0.y {
                let (a1, b1, ia, ib) = segments[s], (a2, b2, ja, jb) = segments[t]
                if ia == ja || ib == jb { continue }
                if (a1.x - a2.x) * (b1.x - b2.x) < 0 { count += 1 }
            }
        }
        return count
    }
}

let layeredModel = LayeredModel()

/// The canvas nodes and edges of a picture of the pipeline: a node per vertex, a hidden one per
/// bend, and a segment per step along each edge's chain, the last with its arrowhead.
func pipelineCanvas(_ model: LayeredModel, _ picture: LayerPicture, withBends: Bool, highlightReversed: Bool) -> (nodes: [CanvasNode], edges: [CanvasEdge], width: Int, height: Int) {
    let xs = picture.values.map(\.x), ys = picture.values.map(\.y)
    let minX = xs.min() ?? 0, maxX = xs.max() ?? 0, maxY = ys.max() ?? 0
    // At least 640 wide, the drawing centred, so a narrow drawing isn't blown up.
    let width = max(640, (maxX - minX) * 100 + 120)
    let left = (width - (maxX - minX) * 100) / 2
    func at(_ p: SIMD2<Double>) -> (Double, Double) {
        let x: Double = (((p.x - minX) * 100 + left) * 10).rounded() / 10
        let y: Double = ((p.y * 90 + 40) * 10).rounded() / 10
        return (x, y)
    }
    let vertices = Array(model.graph.vertices)
    var nodes = vertices.map { v in
        let (x, y) = at(picture[.vertex(v)]!)
        return CanvasNode(x: x, y: y, name: v, radius: 14, nameAbove: false)
    }
    var index: [LayerItem: Int] = [:]
    for (i, v) in vertices.enumerated() { index[.vertex(v)] = i }
    var edges: [CanvasEdge] = []
    let reversed = Set(model.layered.reversedEdges)
    for (p, items) in model.chains {
        let chain = withBends ? items : [items.first!, items.last!]
        for item in chain where index[item] == nil {
            let (x, y) = at(picture[item]!)
            index[item] = nodes.count
            nodes.append(CanvasNode(x: x, y: y, name: "", radius: 0, classes: "hidden"))
        }
        let isReversed = highlightReversed && reversed.contains(p)
        for j in 0 ..< chain.count - 1 {
            edges.append(CanvasEdge(from: index[chain[j]]!, to: index[chain[j + 1]]!, directed: j == chain.count - 2, classes: isReversed ? "route" : ""))
        }
    }
    return (nodes, edges, Int(width), Int(maxY * 90 + 90))
}

/// The pipeline drawn by sugiyamaLayout().
@View
struct PipelineLab {
    var body: some View {
        let model = layeredModel
        let canvas = pipelineCanvas(model, model.finalPicture, withBends: true, highlightReversed: true)
        let reversed = model.layered.reversedEdges.map { model.graph.edges[$0] }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The build pipeline in layers")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A build pipeline drawn in layers, every step below the steps it waits for", width: canvas.width, height: canvas.height,
                                nodes: canvas.nodes, edges: canvas.edges)
                    div(.class("legend")) {
                        span { i(.class("line route")) {}; "drawn against its direction, to break a loop" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { "\(model.layered.layerCount) layers · \(model.layered.crossingCount) crossing\(model.layered.crossingCount == 1 ? "" : "s")" }
                        p(.class("narration")) {
                            if reversed.isEmpty {
                                "Every arrow points down: each step sits below everything it waits for. Long arrows bend at each layer they pass, so no arrow jumps over a step."
                            } else {
                                "The nightly rerun makes a loop, and a loop can’t point down all the way round. Sugiyama’s method turns "
                                em { reversed.map { "\($0.source) → \($0.target)" }.joined(separator: ", ") }
                                " around for the drawing only, lays out the rest, and draws it pointing up."
                            }
                        }
                    }
                    div(.class("panel")) {
                        label(.class("field"), .for("layered-rerun")) {
                            "Nightly rerun "
                            select(.id("layered-rerun")) {
                                option(.value("0")) { "off" }.attributes(.selected, when: !model.rerun)
                                option(.value("1")) { "release → fetch" }.attributes(.selected, when: model.rerun)
                            }
                            .onInput { event in
                                if let value = event.targetValue { layeredModel.setRerun(value == "1") }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The pipeline's code panel.
@View
struct PipelineCodePanel {
    var body: some View {
        let model = layeredModel
        CodePanel(
            snippets: [.layeredImports, .layeredPipeline, Snippet(lines: ["let rerun = \(model.rerun)"]), .layeredGraph, .layeredSugiyama],
            results: [
                "\(model.layered.crossingCount)",
                "[" + model.layered.reversedEdges.map { "\(model.graph.edges[$0])" }.joined(separator: ", ") + "]",
                "[" + model.graph.vertices.map { "\"\($0): \(model.layered.layer(of: $0))\"" }.joined(separator: ", ") + "]",
            ])
    }
}

/// The sentence for the picture after phase `k`.
func describePhase(_ k: Int, model: LayeredModel, crossings: Int) -> String {
    let reversed = model.layered.reversedEdges.map { model.graph.edges[$0] }
    switch SugiyamaPhase(rawValue: k) {
    case .cycles?:
        return reversed.isEmpty
            ? "1. Break the loops. There are none, so nothing is turned around."
            : "1. Break the loops: turn the fewest arrows around that leaves none, here \(reversed.map { "\($0.source) → \($0.target)" }.joined(separator: ", ")). Now every arrow can point down."
    case .layers?:
        return "2. Give each step a layer, every arrow at least one layer down, with the arrows as short in total as possible. \(model.layered.layerCount) layers; within each, steps in the order they were listed."
    case .bends?:
        return "3. Put a bend point on every layer a long arrow passes, so every piece of arrow joins adjacent layers. In the order given, there are \(crossings) crossing\(crossings == 1 ? "" : "s")."
    case .crossings?:
        return "4. Reorder each layer by where its neighbours sit, sweeping down and up, and keep the order with the fewest crossings: \(crossings)."
    case .coordinates?:
        return "5. Slide each point along its layer so arrows run as straight as they can, without changing the order. This is sugiyamaLayout()’s drawing."
    case nil:
        return "The pipeline as listed, in no particular arrangement. Press Step to lay it out in five phases."
    }
}

/// The five phases, one at a time.
@View
struct SugiyamaStepLab {
    var body: some View {
        let model = layeredModel
        let playback = model.playback
        let k = playback.k
        let (picture, withBends) = model.picture(after: k)
        let canvas = pipelineCanvas(model, picture, withBends: withBends, highlightReversed: k >= 1)
        let crossings = withBends ? model.crossings(in: picture) : 0
        let phases = SugiyamaPhase.allCases

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The phases of a layered drawing")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "The pipeline after \(k) of the five phases", width: canvas.width, height: canvas.height, nodes: canvas.nodes, edges: canvas.edges)
                    div(.class("legend")) {
                        span { i(.class("line route")) {}; "turned around to break a loop" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == phases.count ? "Done after \(phases.count) phases" : "Phase \(k) of \(phases.count)" }
                        p(.class("narration")) { describePhase(k, model: model, crossings: crossings) }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Crossings" }
                        p(.class("narration")) { withBends ? "\(crossings)" : "Counted once the arrows are cut at the layers." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                }
                Timeline(
                    playback: playback,
                    marbles: phases.map { phase in
                        let shown = model.picture(after: phase.rawValue)
                        return Marble(kind: phase == .coordinates ? "m-green" : "m-blue", radius: 9, letter: "\(phase.rawValue)",
                                      title: describePhase(phase.rawValue, model: model, crossings: shown.withBends ? model.crossings(in: shown.picture) : 0))
                    },
                    legend: [(Marble(kind: "m-blue", radius: 6), "a phase, numbered"), (Marble(kind: "m-green", radius: 6), "the finished drawing")])
                p(.class("note")) { "sugiyamaLayout() runs all five phases at once. The pictures between are the page’s, rebuilt from its layers, bends and final order, so phases 2 and 3 show the order the layout starts from, as it documents." }
            }
        }
    }
}

/// The phases' code panel.
@View
struct SugiyamaCodePanel {
    var body: some View {
        PipelineCodePanel()
    }
}

/// The org chart by Reingold–Tilford.
@View
struct TeamLab {
    var body: some View {
        let model = layeredModel
        let drawing = teamDrawing(circular: model.circular)
        let names = drawing.vertices
        let xs = drawing.positions.map(\.x), ys = drawing.positions.map(\.y)
        let minX = xs.min()!, maxX = xs.max()!, minY = ys.min()!, maxY = ys.max()!
        let scale = model.circular ? 95.0 : 70.0
        let yScale = model.circular ? 95.0 : 90.0
        let width = max(640, Int((maxX - minX) * scale + 100)), height = Int((maxY - minY) * yScale + 90)
        let left = (Double(width) - (maxX - minX) * scale) / 2
        let nodes = drawing.positions.indices.map { i in
            CanvasNode(x: (((drawing.positions[i].x - minX) * scale + left) * 10).rounded() / 10,
                       y: (((drawing.positions[i].y - minY) * yScale + 35) * 10).rounded() / 10,
                       name: names[i], radius: 13, classes: names[i] == "CEO" ? "visited" : "")
        }
        let edges = reportsTo.map { CanvasEdge(from: names.firstIndex(of: $0.1)!, to: names.firstIndex(of: $0.0)!) }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The org chart")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "An org chart of fourteen people, drawn as a tidy tree", width: width, height: height, nodes: nodes, edges: edges)
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { model.circular ? "Bent into a disc" : "A tidy tree" }
                        p(.class("narration")) {
                            model.circular
                                ? "The same drawing wrapped round the CEO: each level of the chart on its own circle, each team in its own slice."
                                : "Each level of the chart on its own row, each manager centred over their team, and teams packed as close as they can go without overlapping. Two teams of the same shape are drawn the same way."
                        }
                    }
                    div(.class("panel")) {
                        label(.class("field"), .for("layered-circular")) {
                            "Draw it "
                            select(.id("layered-circular")) {
                                option(.value("0")) { "in rows" }.attributes(.selected, when: !model.circular)
                                option(.value("1")) { "in a disc" }.attributes(.selected, when: model.circular)
                            }
                            .onInput { event in
                                if let value = event.targetValue {
                                    layeredModel.circular = value == "1"
                                    setProperty(id: "layered-circular", "value", to: value)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The org chart's code panel.
@View
struct TeamCodePanel {
    var body: some View {
        CodePanel(snippets: [.layeredImports, .layeredTeam, layeredModel.circular ? .layeredCircular : .layeredTidy])
    }
}

enum LayeredPage {
    static func mount() {
        mountView(PipelineLab(), in: "app")
        mountView(PipelineCodePanel(), in: "code")
        mountView(SugiyamaStepLab(), in: "phases")
        mountView(SugiyamaCodePanel(), in: "code-phases")
        mountView(TeamLab(), in: "tree")
        mountView(TeamCodePanel(), in: "code-tree")
        mountView(NamesStrip(names: [Names.sugiyama]), in: "names")
    }
}
