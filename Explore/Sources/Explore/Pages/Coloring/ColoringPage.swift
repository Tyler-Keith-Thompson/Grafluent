import ColoringModule
import ElementaryUI
import Reactivity

let courseSpots: [(name: String, x: Double, y: Double)] = [
    ("Art", 230, 50), ("Biology", 336, 94), ("Chemistry", 380, 200), ("Drama", 336, 306),
    ("English", 230, 350), ("French", 124, 306), ("Geography", 80, 200), ("History", 124, 94),
]
let courses = courseSpots.map(\.name)
let startingClashes: [(String, String)] = [
    ("Art", "Drama"), ("Art", "French"), ("Art", "History"), ("Chemistry", "Biology"), ("Chemistry", "French"),
    ("Chemistry", "History"), ("English", "Biology"), ("English", "Drama"), ("English", "History"),
    ("Geography", "Biology"), ("Geography", "Drama"), ("Geography", "French"),
]

/// The orders greedy colouring can go in, each with its snippet; an order is `nil` when it
/// doesn't apply (two groups, when the clashes don't split the exams in two).
let coloringOrders: [(name: String, order: (Exams, [String]) -> [String]?, snippet: Snippet)] = [
    ("Alphabetical", alphabeticalOrder, .coloringAlphabetical),
    ("Busiest first (Welsh–Powell)", busiestFirstOrder, .coloringBusiest),
    ("One group, then the other", groupByGroupOrder, .coloringGroups),
]

/// The page's sums: the exams, the order, greedy's colouring and the fewest slots.
struct ColoringRun {
    var exams: Exams
    var order: [String]?
    var greedy: Coloring<Exams>?
    var fewest: (count: Int, coloring: Coloring<Exams>)
}

@Reactive
final class ColoringModel {
    var clashes = startingClashes
    /// An offset in `coloringOrders`.
    var method = 0
    var showFewest = false
    var selected: Int?
    var run: ColoringRun
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 800)

    init() {
        let exams = examGraph(courses: courses, clashes: startingClashes)
        run = ColoringRun(exams: exams, order: nil, greedy: nil, fewest: fewestSlots(exams))
        rerun()
    }

    func rerun() {
        let exams = examGraph(courses: courses, clashes: clashes)
        let order = coloringOrders[method].order(exams, courses)
        run = ColoringRun(exams: exams, order: order, greedy: order.map { greedyInOrder(exams, order: $0) }, fewest: fewestSlots(exams))
        playback.reset(count: order?.count ?? 0)
        playback.show(order?.count ?? 0)
    }

    func toggle(_ a: String, _ b: String) {
        if let i = clashes.firstIndex(where: { $0 == (a, b) || $0 == (b, a) }) { clashes.remove(at: i) } else { clashes.append((a, b)) }
        rerun()
    }

    func tap(_ v: Int) {
        if let u = selected, u != v {
            toggle(courses[u], courses[v])
            selected = nil
        } else {
            selected = selected == v ? nil : v
        }
    }
}

let coloringModel = ColoringModel()

let slotNames = ["Mon 9:00", "Mon 14:00", "Tue 9:00", "Tue 14:00", "Wed 9:00", "Wed 14:00", "Thu 9:00", "Thu 14:00"]

@View
struct ColoringLab {
    var body: some View {
        let model = coloringModel
        let run = model.run
        let playback = model.playback
        let k = playback.k
        let order = run.order ?? []
        let coloured = Set(order.prefix(k))
        let current = k > 0 ? order[k - 1] : ""
        let finished = k == order.count && run.greedy != nil
        let used = run.greedy.map { g in Set(order.prefix(k).map { g.color(of: $0) }).count } ?? 0
        let nodes = courseSpots.enumerated().map { v, spot in
            let colour = coloured.contains(spot.name) ? run.greedy.map { $0.color(of: spot.name) } : nil
            return CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: colour.map { "\($0 + 1)" } ?? "", radius: 18,
                              classes: (colour.map { "pal\($0 % 8)" } ?? "") + (model.selected == v ? " selected" : "") + (spot.name == current ? " current" : ""),
                              nameAbove: spot.y < 200)
        }
        let edges = model.clashes.map { a, b in
            CanvasEdge(from: courses.firstIndex(of: a)!, to: courses.firstIndex(of: b)!,
                       classes: current != "" && (a == current || b == current) && coloured.contains(a) && coloured.contains(b) ? "tree" : "")
        }
        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Exam clashes")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Eight exams; a line joins two exams that share a student", width: 460, height: 390,
                                nodes: nodes, edges: edges, onNode: { coloringModel.tap($0) },
                                onEdge: { i in
                                    let (a, b) = coloringModel.clashes[i]
                                    coloringModel.toggle(a, b)
                                }, nodeAction: "Pick")
                    p(.class("note")) {
                        if let selected = model.selected {
                            "\(courses[selected]) is picked: click another exam to add or remove a clash."
                        } else {
                            "A line means some student sits both exams, so they need different slots. The number in each exam is its slot. Click two exams to add a clash; click a line to remove it."
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Slots needed" : "Exam \(k) of \(order.count)" }
                        div(.class("stat")) {
                            div(.class(finished && used > run.fewest.count ? "bad" : "good")) { span(.class("num")) { "\(used)" }; "greedy so far" }
                            div(.class("good")) { span(.class("num")) { "\(run.fewest.count)" }; "fewest possible" }
                        }
                        p(.class("narration")) {
                            if run.greedy == nil {
                                "These clashes don’t split the exams into two groups, so this order doesn’t exist. Pick another."
                            } else if k == 0 {
                                "Go through the exams in order, giving each the first slot none of its clashing exams already has."
                            } else if !finished {
                                coloringStepText(run, current)
                            } else if used > run.fewest.count {
                                "This order needs \(used) slots. \(run.fewest.count) is enough: the fewest-slot timetable is below."
                            } else {
                                "This order finds the fewest slots, \(run.fewest.count)."
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Timetable with the fewest slots" }
                        div(.class("queue")) {
                            for (slot, exams) in run.fewest.coloring.colorClasses.enumerated() {
                                div(.class("qrow plain")) {
                                    span(.class("chip pal\(slot % 8)")) { slot < slotNames.count ? slotNames[slot] : "Slot \(slot + 1)" }
                                    span { exams.joined(separator: ", ") }
                                }
                            }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    label(.class("field"), .for("method")) {
                        "Order "
                        select(.id("method")) {
                            for (n, method) in coloringOrders.enumerated() {
                                option(.value("\(n)")) { method.name }.attributes(.selected, when: n == model.method)
                            }
                        }
                        .onInput { event in
                            if let value = event.targetValue, let n = Int(value) {
                                coloringModel.method = n
                                coloringModel.rerun()
                            }
                        }
                    }
                    button(.type(.button)) { "Reset" }
                        .onClick {
                            coloringModel.clashes = startingClashes
                            coloringModel.selected = nil
                            coloringModel.rerun()
                        }
                }
                Timeline(
                    playback: playback,
                    marbles: order.map { exam in
                        let colour = run.greedy!.color(of: exam)
                        return Marble(kind: "m-pal\(colour % 8)", radius: 11, letter: "\(colour + 1)", title: coloringStepText(run, exam))
                    },
                    legend: [(Marble(kind: "m-pal0", radius: 6), "an exam gets a slot; the number is the slot")])
            }
        }
    }
}

/// The sentence for colouring `exam`: the slots its clashing exams already hold, and the one it gets.
func coloringStepText(_ run: ColoringRun, _ exam: String) -> String {
    guard let order = run.order, let greedy = run.greedy, let at = order.firstIndex(of: exam) else { return "" }
    let earlier = Set(order[..<at])
    let taken = Set(run.exams.neighbors(of: exam).filter { earlier.contains($0) }.map { greedy.color(of: $0) + 1 }).sorted()
    let slot = greedy.color(of: exam) + 1
    return taken.isEmpty
        ? "\(exam): nothing it clashes with has a slot yet, so slot 1."
        : "\(exam) clashes with exams in slot\(taken.count == 1 ? "" : "s") \(taken.map(String.init).joined(separator: ", ")), so it gets slot \(slot)."
}

/// A colouring as its count and its classes.
func colourText(_ c: Coloring<Exams>) -> String {
    "\(c.colorCount) colours: " + c.colorClasses.map { "{" + $0.joined(separator: ", ") + "}" }.joined(separator: " ")
}

@View
struct ColoringCodePanel {
    var body: some View {
        let model = coloringModel
        let run = model.run
        let method = coloringOrders[model.method]
        let orderResult = run.order.map { "[" + $0.map { "\"\($0)\"" }.joined(separator: ", ") + "]" } ?? "nil"
        CodePanel(
            snippets: [
                .coloringImports,
                Snippet(lines: ["let courses = [" + courses.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "let clashes = ["]
                    + model.clashes.map { "    (\"\($0.0)\", \"\($0.1)\")," } + ["]"]),
                .coloringExams, method.snippet, .coloringOrder, .coloringExact,
            ],
            results: (method.snippet.lines.contains { $0.hasSuffix("// →") } ? [orderResult] : [])
                + [run.greedy.map(colourText) ?? "not run", "\(run.fewest.count)", colourText(run.fewest.coloring)])
    }
}

enum ColoringPage {
    static func mount() {
        Application(ColoringLab()).mount(in: "#app")
        Application(ColoringCodePanel()).mount(in: "#code")
        Application(NamesStrip(names: [Names.welshPowell, Names.brelaz, Names.brooks, Names.konig])).mount(in: "#names")
    }
}
