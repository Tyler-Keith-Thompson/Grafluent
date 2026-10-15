import AdjacencyMatrixModule
import CompressedSparseRowModule
import ElementaryUI
import GraphProtocols
import LabeledGraphs
import Reactivity

let friendSpots: [(name: String, x: Double, y: Double)] = [("Ana", 90, 80), ("Ben", 330, 80), ("Cy", 330, 250), ("Dee", 90, 250)]
let friendNames = friendSpots.map(\.name)
let startingFollows4: [(String, String)] = [("Ana", "Ben"), ("Ana", "Cy"), ("Ben", "Cy"), ("Cy", "Ana"), ("Dee", "Cy")]

@Reactive
final class RepresentationsModel {
    var arrows = startingFollows4
    var undirected = false
    /// The person whose row (and column) is highlighted, and from whom a click on another
    /// person draws an edge.
    var selected: Int? = 0

    /// Adds `a → b`, or removes it (either way round, for friendships).
    func toggle(_ a: Int, _ b: Int) {
        guard a != b else { return }
        let (u, v) = (friendNames[a], friendNames[b])
        if let i = arrows.firstIndex(where: { $0 == (u, v) || (undirected && $0 == (v, u)) }) {
            arrows.removeAll { $0 == (u, v) || (undirected && $0 == (v, u)) }
            _ = i
        } else {
            arrows.append((u, v))
        }
    }

    func tap(_ v: Int) {
        if let u = selected, u != v { toggle(u, v) } else { selected = selected == v ? nil : v }
    }

    var forms: ThreeForms {
        undirected ? friendForms(people: friendNames, arrows: arrows) : followForms(people: friendNames, arrows: arrows)
    }
}

let representations = RepresentationsModel()

@View
struct RepresentationsLab {
    var body: some View {
        let model = representations
        let undirected = model.undirected
        let forms = model.forms
        let selected = model.selected
        let offsets = forms.csr.base.offsets, targets = forms.csr.base.targets
        let n = friendNames.count
        let ones = (0 ..< n).reduce(0) { sum, r in sum + (0 ..< n).filter { forms.matrix.base[r, $0] }.count }
        let pairs = Set(model.arrows.map { undirected ? [$0.0, $0.1].sorted().joined(separator: "–") : "\($0.0)→\($0.1)" })
        let shownArrows = model.arrows.filter { a in
            !undirected || model.arrows.firstIndex { $0 == a || $0 == (a.1, a.0) } == model.arrows.firstIndex { $0 == a }
        }
        let nodes = friendSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: String(spot.name.prefix(1)), radius: 22,
                       classes: v == selected ? "visited selected" : "", nameAbove: spot.y < 150)
        }
        let edges = shownArrows.map { a, b in
            CanvasEdge(from: friendNames.firstIndex(of: a)!, to: friendNames.firstIndex(of: b)!, directed: !undirected,
                       classes: selected.map { friendNames[$0] == a || (undirected && friendNames[$0] == b) } ?? false ? "tree" : "",
                       bend: !undirected && model.arrows.contains { $0 == (b, a) } ? 14 : 0)
        }
        // CSR drawn as two rows of boxes, each offset pointing at the start of its run.
        let box = 52.0, left = 86.0
        let width = Int(left + Double(max(targets.count, offsets.count)) * box + 12)
        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Four friends")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: undirected ? "Four friends; a line joins two friends" : "Four friends; an arrow from each person to everyone they follow",
                                width: 420, height: 320, nodes: nodes, edges: edges,
                                onNode: { representations.tap($0) },
                                onEdge: { i in
                                    let (a, b) = shownArrows[i]
                                    representations.toggle(friendNames.firstIndex(of: a)!, friendNames.firstIndex(of: b)!)
                                }, nodeAction: "Pick")
                    p(.class("note")) {
                        if let selected {
                            "\(friendNames[selected]) is picked. Click someone else to add or remove \(undirected ? "a friendship with them" : "“\(friendNames[selected]) follows them”"), or click \(friendNames[selected]) again to let go."
                        } else {
                            "Click a person to pick them, then someone else to add or remove an edge. Clicking an edge removes it."
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel")) {
                        span(.class("label")) { "Directed or not" }
                        div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Kind of graph")) {
                            button(.type(.button), .class(undirected ? "" : "on")) { "Follows (directed)" }
                                .onClick { representations.undirected = false }
                            button(.type(.button), .class(undirected ? "on" : "")) { "Friends (undirected)" }
                                .onClick { representations.undirected = true }
                        }
                        p(.class("note")) {
                            undirected
                                ? "A friendship goes both ways, so each one is stored in both people’s rows, and the matrix is a mirror image across its diagonal."
                                : "A follow goes one way: Ana can follow Ben without Ben following back."
                        }
                        div(.class("stat")) {
                            div { span(.class("num")) { "\(n)" }; "vertices" }
                            div { span(.class("num")) { "\(pairs.count)" }; "edges" }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Adjacency list" }
                        div(.class("adj")) {
                            for (v, row) in forms.rows.enumerated() {
                                div(.class(v == selected ? "hl" : "")) {
                                    b { friendNames[v] }
                                    " → " + (row.isEmpty ? "·" : row.joined(separator: ", "))
                                }
                            }
                        }
                        p(.class("note")) { undirected ? "Each row is one person, followed by all their friends." : "Each row is one person, followed by everyone they follow." }
                    }
                }
            }
            div(.class("reps")) {
                div(.class("panel")) {
                    h3 { "Adjacency matrix" }
                    p(.class("note")) {
                        "Read across a row: the 1s are who that person "
                        undirected ? "is friends with" : "follows"
                        ". Read down a column: the 1s are "
                        undirected ? "the same people again." : "who follows that person."
                        " Click a square to flip it."
                    }
                    table(.class("matrix")) {
                        tr {
                            th(.class("corner")) { undirected ? "" : "follows ↓ · followed →" }
                            for v in 0 ..< n { th(.class(v == selected ? "col hl" : "col")) { friendNames[v] } }
                        }
                        for r in 0 ..< n {
                            tr(.class(r == selected ? "hl" : "")) {
                                th { friendNames[r] }
                                for c in 0 ..< n {
                                    MatrixCell(row: r, column: c, on: forms.matrix.base[r, c], highlighted: c == selected)
                                }
                            }
                        }
                    }
                    p(.class("note")) {
                        "\(ones) ones and \(n * n - ones) zeros: the matrix spends a square on every pair, edge or not. Four people need 16 squares; a million would need a trillion, almost all of them 0."
                    }
                }
                div(.class("panel")) {
                    h3 { "Compressed sparse row" }
                    p(.class("note")) {
                        "Every row of the list packed end to end into one targets array. The offsets array says where each person’s run starts; the last offset marks the end."
                    }
                    div(.class("csr-scroll")) {
                        SVG.svg(.class("csr"), .width(.init(width)), .viewBox(0, 0, .init(width), 190), .custom(name: "role", value: "img"),
                                .custom(name: "aria-label", value: "Compressed sparse row: offsets pointing into one targets array")) {
                            SVG.text(.x(.init(left - 10)), .y(52), .textAnchor("end"), .class("hdr")) { "offsets" }
                            SVG.text(.x(.init(left - 10)), .y(150), .textAnchor("end"), .class("hdr")) { "targets" }
                            for (v, offset) in offsets.enumerated() {
                                let x = left + Double(v) * box
                                let hl = selected.map { v == $0 || v == $0 + 1 } ?? false
                                SVG.rect(.x(.init(x)), .y(30), .width(.init(box - 4)), .height(34), .class(hl ? "cell hl" : "cell")) {}
                                SVG.text(.x(.init(x + box / 2 - 2)), .y(53), .textAnchor("middle"), .class("bit")) { "\(offset)" }
                                SVG.text(.x(.init(x + box / 2 - 2)), .y(20), .textAnchor("middle"), .class("idx")) { v < n ? friendNames[v] : "end" }
                                SVG.line(.x1(.init(x + box / 2 - 2)), .y1(64), .x2(.init(left + Double(offset) * box + 2)), .y2(126), .class(hl ? "ptr hl" : "ptr")) {}
                            }
                            for (j, target) in targets.enumerated() {
                                let x = left + Double(j) * box
                                let hl = selected.map { offsets[$0] <= j && j < offsets[$0 + 1] } ?? false
                                SVG.rect(.x(.init(x)), .y(128), .width(.init(box - 4)), .height(34), .class(hl ? "cell on hl" : "cell on")) {}
                                SVG.text(.x(.init(x + box / 2 - 2)), .y(151), .textAnchor("middle"), .class("bit on")) { forms.csr.vertex(atIndex: target) }
                                SVG.text(.x(.init(x + box / 2 - 2)), .y(182), .textAnchor("middle"), .class("idx")) { "\(j)" }
                            }
                        }
                    }
                    p(.class("note")) {
                        if let v = selected {
                            "\(friendNames[v])’s run is targets[\(offsets[v]) ..< \(offsets[v + 1])]: "
                            + (offsets[v] == offsets[v + 1] ? "empty." : (offsets[v] ..< offsets[v + 1]).map { forms.csr.vertex(atIndex: targets[$0]) }.joined(separator: ", ") + ".")
                        } else {
                            "Pick a person to see their run."
                        }
                    }
                }
            }
        }
    }
}

/// One square of the matrix: a button that flips the edge from `row` to `column`.
@View
struct MatrixCell {
    var row: Int
    var column: Int
    var on: Bool
    var highlighted: Bool

    var body: some View {
        let (r, c) = (row, column)
        td(.class(highlighted ? "colhl" : "")) {
            button(.type(.button), .class(on ? "on" : ""), .custom(name: "aria-label", value: "\(friendNames[r]) to \(friendNames[c]): \(on ? 1 : 0)")) {
                on ? "1" : "0"
            }
            .attributes(.disabled, when: r == c)
            .onClick { representations.toggle(r, c) }
        }
    }
}

@View
struct RepresentationsCodePanel {
    var body: some View {
        let model = representations
        CodePanel(
            snippets: [
                .representationsImports,
                Snippet(lines: ["let people = [" + friendNames.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "let arrows = ["]
                    + model.arrows.map { "    (\"\($0.0)\", \"\($0.1)\")," } + ["]"]),
                model.undirected ? .representationsFriends : .representationsFollows, .representationsRead,
            ],
            results: readBack(model.forms))
    }
}

enum RepresentationsPage {
    static func mount() {
        mountView(RepresentationsLab(), in: "app")
        mountView(RepresentationsCodePanel(), in: "code")
    }
}
