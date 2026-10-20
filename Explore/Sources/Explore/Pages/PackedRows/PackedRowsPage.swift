import ElementaryUI
import GraphProtocols
import PackedCompressedSparseRowModule
import Reactivity

let packedSpots: [(name: String, x: Double, y: Double)] = [("Ana", 110, 70), ("Ben", 310, 70), ("Cy", 375, 170), ("Dee", 310, 270), ("Eli", 110, 270), ("Fay", 45, 170)]
let packedNames = packedSpots.map(\.name)
let startingFollows6: [(String, String)] = [("Ana", "Ben"), ("Ana", "Cy"), ("Ben", "Cy"), ("Cy", "Ana"), ("Dee", "Cy")]
let packedStartStory = "Built in one go, so the rows sit packed end to end with no spare cells. Pick someone and add a follow to see the storage change."

@Reactive
final class PackedRowsModel {
    var follows = packedFollows(people: packedNames, arrows: startingFollows6)
    /// The person whose row is highlighted, and from whom a click on another person adds or
    /// removes a follow.
    var selected: Int? = 0
    /// What the last change did to the storage.
    var story = packedStartStory
    /// The follows in the order they were added, for the code panel.
    var arrows = startingFollows6

    func toggle(_ a: Int, _ b: Int) {
        guard a != b else { return }
        let (who, whom) = (packedNames[a], packedNames[b])
        let before = cells(of: follows)
        let added = toggleFollow(&follows, who, whom)
        let after = cells(of: follows)
        if added { arrows.append((who, whom)) } else { arrows.removeAll { $0 == (who, whom) } }
        story = describe(before: before, after: after, row: a, added: added, whom: whom)
    }

    func tap(_ v: Int) {
        if let u = selected, u != v { toggle(u, v) } else { selected = selected == v ? nil : v }
    }

    func fill() {
        var stories: [String] = []
        for a in 0 ..< packedNames.count {
            for b in 0 ..< packedNames.count where a != b && !follows.contains(edge: DirectedEdge(from: packedNames[a], to: packedNames[b])) {
                let before = cells(of: follows)
                _ = toggleFollow(&follows, packedNames[a], packedNames[b])
                arrows.append((packedNames[a], packedNames[b]))
                let after = cells(of: follows)
                if after.capacity != before.capacity { stories.append(describe(before: before, after: after, row: a, added: true, whom: packedNames[b])) }
            }
        }
        story = (stories.last ?? "Everyone follows everyone now.") + " Every follow went in without rebuilding anything else."
    }

    func reset() {
        follows = packedFollows(people: packedNames, arrows: startingFollows6)
        arrows = startingFollows6
        story = packedStartStory
    }

    private func describe(before: StorageCells, after: StorageCells, row: Int, added: Bool, whom: String) -> String {
        let name = packedNames[row]
        let rowBefore = before.rows[row], rowAfter = after.rows[row]
        if !added {
            let shrank = after.capacity < before.capacity
            return "\(whom) came out of \(name)’s row. The row’s last entry moved into the hole, and the cell is spare again. "
                + (shrank ? "Fewer than a quarter of the cells were in use, so the storage halved to \(after.capacity)." : "Nothing else moved.")
        }
        if before.rows.allSatisfy({ $0.count == $0.capacity }) && before.capacity == before.used {
            return "The rows had no spare cells, so the whole storage was laid out again: \(after.capacity) cells, and every row got spare cells after it in proportion to its size. The next follows go straight into those."
        }
        if after.capacity > before.capacity {
            return "\(name)’s row was full, and so was every window around it, the whole storage over seven tenths used. It doubled to \(after.capacity) cells, and every row was laid out again with spare cells in proportion to its size."
        }
        if rowBefore.start == rowAfter.start && rowBefore.capacity == rowAfter.capacity {
            return "\(name) had a spare cell, so \(whom) went straight into it. Nothing else moved."
        }
        let moved = after.rows.indices.filter { after.rows[$0].start != before.rows[$0].start || after.rows[$0].capacity != before.rows[$0].capacity }
        let first = moved.min() ?? row, last = moved.max() ?? row
        let from = after.rows[first].start, to = after.rows[last].start + after.rows[last].capacity
        let span = first == last ? "\(packedNames[first])’s row" : "the rows from \(packedNames[first]) to \(packedNames[last])"
        return "\(name)’s row was full. The smallest window around it that was not too full, \(span) over cells \(from) to \(to - 1), was laid out again to spread its spare cells. Nothing outside it moved."
    }
}

let packedRows = PackedRowsModel()

@View
struct PackedRowsLab {
    var body: some View {
        let model = packedRows
        let selected = model.selected
        let storage = cells(of: model.follows)
        let n = packedNames.count
        let nodes = packedSpots.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: String(spot.name.prefix(1)), radius: 22,
                       classes: v == selected ? "visited selected" : "", nameAbove: spot.y < 150)
        }
        let edges = model.arrows.map { a, b in
            CanvasEdge(from: packedNames.firstIndex(of: a)!, to: packedNames.firstIndex(of: b)!, directed: true,
                       classes: selected.map { packedNames[$0] == a } ?? false ? "tree" : "",
                       bend: model.arrows.contains { $0 == (b, a) } ? 14 : 0)
        }
        let box = 30.0, left = 20.0
        let width = Int(left + Double(max(storage.capacity, 1)) * box + 12)
        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Six people and the storage of who follows whom")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Six people; an arrow from each person to everyone they follow",
                                width: 420, height: 320, nodes: nodes, edges: edges,
                                onNode: { packedRows.tap($0) },
                                onEdge: { i in
                                    let (a, b) = model.arrows[i]
                                    packedRows.toggle(packedNames.firstIndex(of: a)!, packedNames.firstIndex(of: b)!)
                                }, nodeAction: "Pick")
                    p(.class("note")) {
                        if let selected {
                            "\(packedNames[selected]) is picked. Click someone else to add or remove “\(packedNames[selected]) follows them”, or click \(packedNames[selected]) again to let go."
                        } else {
                            "Click a person to pick them, then someone else to add or remove a follow. Clicking an arrow removes it."
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel")) {
                        span(.class("label")) { "The storage" }
                        div(.class("stat")) {
                            div { span(.class("num")) { "\(storage.used)" }; "cells used" }
                            div { span(.class("num")) { "\(storage.capacity)" }; "cells in all" }
                        }
                        div(.class("buttons")) {
                            button(.type(.button)) { "Everyone follows everyone" }.onClick { packedRows.fill() }
                            button(.type(.button)) { "Start over" }.onClick { packedRows.reset() }
                        }
                        p(.class("note")) { model.story }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Rows" }
                        div(.class("adj")) {
                            for (v, row) in storage.rows.enumerated() {
                                div(.class(v == selected ? "hl" : "")) {
                                    b { row.name }
                                    " → " + (row.targets.isEmpty ? "·" : row.targets.joined(separator: ", "))
                                    + "  (\(row.count) of \(row.capacity) cells)"
                                }
                            }
                        }
                        p(.class("note")) { "Each row holds the people someone follows, then its spare cells." }
                    }
                }
            }
            div(.class("reps")) {
                div(.class("panel")) {
                    h3 { "The cells" }
                    p(.class("note")) {
                        "One array holds every row in order. A filled cell is a follow. An empty cell inside a row’s span is spare, kept so the row can grow in place. The bracket under each span names its row."
                    }
                    div(.class("csr-scroll")) {
                        SVG.svg(.class("csr"), .width(.init(width)), .viewBox(0, 0, .init(width), 120), .custom(name: "role", value: "img"),
                                .custom(name: "aria-label", value: "The rows packed into one array of cells with spare cells after each")) {
                            for c in 0 ..< storage.capacity {
                                let x = left + Double(c) * box
                                SVG.rect(.x(.init(x)), .y(30), .width(.init(box - 3)), .height(30), .class("cell")) {}
                                if c % 4 == 0 { SVG.text(.x(.init(x + box / 2 - 1.5)), .y(20), .textAnchor("middle"), .class("idx")) { "\(c)" } }
                            }
                            for (v, row) in storage.rows.enumerated() where row.capacity > 0 {
                                let hl = v == selected
                                let x0 = left + Double(row.start) * box, x1 = left + Double(row.start + row.capacity) * box - 3
                                for c in 0 ..< row.capacity {
                                    let x = left + Double(row.start + c) * box
                                    let on = c < row.count
                                    SVG.rect(.x(.init(x)), .y(30), .width(.init(box - 3)), .height(30), .class((on ? "cell on" : "cell") + (hl ? " hl" : ""))) {}
                                    if on { SVG.text(.x(.init(x + box / 2 - 1.5)), .y(51), .textAnchor("middle"), .class("bit on")) { String(row.targets[c].prefix(1)) } }
                                }
                                SVG.line(.x1(.init(x0)), .y1(70), .x2(.init(x1)), .y2(70), .class(hl ? "ptr hl" : "ptr")) {}
                                SVG.line(.x1(.init(x0)), .y1(64), .x2(.init(x0)), .y2(70), .class(hl ? "ptr hl" : "ptr")) {}
                                SVG.line(.x1(.init(x1)), .y1(64), .x2(.init(x1)), .y2(70), .class(hl ? "ptr hl" : "ptr")) {}
                                SVG.text(.x(.init((x0 + x1) / 2)), .y(88), .textAnchor("middle"), .class("idx")) { row.name }
                            }
                        }
                    }
                    p(.class("note")) {
                        if let v = selected {
                            let row = storage.rows[v]
                            row.capacity == 0
                                ? "\(row.name) owns no cells yet. The first follow added will find some."
                                : "\(row.name)’s row owns cells \(row.start) to \(row.start + row.capacity - 1): \(row.count) used, \(row.capacity - row.count) spare."
                        } else {
                            "Pick a person to see their row’s cells."
                        }
                    }
                    p(.class("note")) { "\(n) people, \(storage.used) follows, \(storage.capacity) cells." }
                }
            }
        }
    }
}

@View
struct PackedRowsCodePanel {
    var body: some View {
        let model = packedRows
        CodePanel(
            snippets: [
                .packedrowsImports,
                Snippet(lines: ["let people = [" + packedNames.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "let arrows = ["]
                    + startingFollows6.map { "    (\"\($0.0)\", \"\($0.1)\")," } + ["]"]),
                .packedrowsBuild,
                Snippet(lines: ["let who = \"\(model.arrows.last?.0 ?? "Ana")\", whom = \"\(model.arrows.last?.1 ?? "Ben")\""]),
                .packedrowsChange, .packedrowsRead,
            ],
            results: readBack(model.follows))
    }
}

enum PackedRowsPage {
    static func mount() {
        mountView(PackedRowsLab(), in: "app")
        mountView(PackedRowsCodePanel(), in: "code")
    }
}
