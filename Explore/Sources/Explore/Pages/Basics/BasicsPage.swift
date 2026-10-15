import ElementaryUI
import Reactivity

let basicsSpots: [(name: String, x: Double, y: Double)] = [("A", 70, 150), ("B", 210, 55), ("C", 210, 245), ("D", 370, 150), ("E", 490, 70)]
let basicsPairs: [(String, String)] = [("A", "B"), ("A", "C"), ("B", "C"), ("B", "D"), ("C", "D"), ("D", "E")]
let basicsWeights = [4, 2, 1, 5, 8, 3]

@Reactive
final class BasicsModel {
    var directed = false
    var weighted = false
    var picked = 1
}

let basics = BasicsModel()

@View
struct BasicsLab {
    var body: some View {
        let model = basics
        let picked = basicsSpots[model.picked].name
        let answers = model.directed
            ? directedBasics(pairs: basicsPairs, weights: basicsWeights, picked: picked)
            : undirectedBasics(pairs: basicsPairs, weights: basicsWeights, picked: picked)
        let out = Set(basicsPairs.filter { $0.0 == picked }.map(\.1)), into = Set(basicsPairs.filter { $0.1 == picked }.map(\.0))
        let nodes = basicsSpots.enumerated().map { v, spot in
            let near = out.contains(spot.name) || (!model.directed && into.contains(spot.name))
            return CanvasNode(x: spot.x, y: spot.y, name: "", badge: spot.name, radius: 21,
                              classes: v == model.picked ? "visited selected" : near ? "frontier" : model.directed && into.contains(spot.name) ? "done" : "")
        }
        let edges = basicsPairs.enumerated().map { i, pair in
            CanvasEdge(from: basicsSpots.firstIndex { $0.name == pair.0 }!, to: basicsSpots.firstIndex { $0.name == pair.1 }!,
                       directed: model.directed, label: model.weighted ? "\(basicsWeights[i])" : "",
                       classes: model.weighted && pair == answers.lightest ? "route" : pair.0 == picked || (!model.directed && pair.1 == picked) ? "tree" : "")
        }
        section(.class("lab"), .custom(name: "aria-label", value: "A small graph")) {
            div(.class("panel stage")) {
                GraphCanvas(label: "Five vertices, A to E, and six edges", width: 560, height: 300, nodes: nodes, edges: edges,
                            onNode: { basics.picked = $0 }, nodeAction: "Pick")
                p(.class("note")) { "Click a vertex to pick it." }
            }
            div(.class("side")) {
                div(.class("panel")) {
                    div(.class("buttons")) {
                        div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Direction")) {
                            button(.type(.button), .class(model.directed ? "" : "on")) { "Undirected" }
                                .onClick { basics.directed = false }
                            button(.type(.button), .class(model.directed ? "on" : "")) { "Directed" }
                                .onClick { basics.directed = true }
                        }
                        button(.type(.button), .class(model.weighted ? "on" : ""), .custom(name: "aria-pressed", value: model.weighted ? "true" : "false")) {
                            model.weighted ? "Hide weights" : "Show weights"
                        }
                        .onClick { basics.weighted.toggle() }
                    }
                }
                div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                    span(.class("label")) { "Vertex \(picked)" }
                    p(.class("narration")) {
                        if model.directed {
                            let s = basicsPairs.filter { $0.0 == picked }.map(\.1), p = basicsPairs.filter { $0.1 == picked }.map(\.0)
                            if s.isEmpty {
                                "No arrows leave \(picked). "
                            } else {
                                "Arrows from \(picked) go to "
                                b { s.joined(separator: ", ") }
                                ". These are its successors, in yellow. "
                            }
                            if p.isEmpty {
                                "No arrows come into \(picked)."
                            } else {
                                "Arrows into \(picked) come from "
                                b { p.joined(separator: ", ") }
                                ". These are its predecessors, in pale blue."
                            }
                        } else {
                            let nbrs = basicsPairs.compactMap { $0.0 == picked ? $0.1 : $0.1 == picked ? $0.0 : nil }
                            "\(picked)’s neighbours are "
                            b { nbrs.joined(separator: ", ") }
                            ". \(nbrs.count) edges touch \(picked), so its degree is \(nbrs.count)."
                        }
                        if model.weighted {
                            " The red edge is the lightest in the graph."
                        }
                    }
                }
            }
        }
    }
}

@View
struct BasicsCodePanel {
    var body: some View {
        let model = basics
        let picked = basicsSpots[model.picked].name
        let answers = model.directed
            ? directedBasics(pairs: basicsPairs, weights: basicsWeights, picked: picked)
            : undirectedBasics(pairs: basicsPairs, weights: basicsWeights, picked: picked)
        let bindings = ["let pairs = [" + basicsPairs.map { "(\"\($0.0)\", \"\($0.1)\")" }.joined(separator: ", ") + "]"]
            + (model.weighted ? ["let numbers = \(basicsWeights)"] : []) + ["let picked = \"\(picked)\""]
        CodePanel(
            snippets: [.basicsImports, Snippet(lines: bindings), model.directed ? .basicsDirected : .basicsUndirected]
                + (model.weighted ? [model.directed ? .basicsDirectedWeights : .basicsUndirectedWeights] : []),
            results: answers.lines)
    }
}

enum BasicsPage {
    static func mount() {
        mountView(BasicsLab(), in: "app")
        mountView(BasicsCodePanel(), in: "code")
    }
}
