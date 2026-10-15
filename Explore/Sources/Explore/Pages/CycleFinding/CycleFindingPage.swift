import ElementaryUI
import FunctionalGraphs
import GraphProtocols
import Reactivity

/// Where each page is drawn, in SVG units of the 680 × 400 view box: the tail in a row, the loop
/// in a ring, and the pages that lead into them nearby.
let readingSpots: [(x: Double, y: Double)] = [
    (60, 215), (130, 215), (200, 215), (270, 215), (345, 215), (431, 96), (571, 142), (571, 288), (431, 334),
    (200, 330), (110, 330), (640, 45),
]

/// `A` for page 0, `B` for page 1, and so on.
func pageName(_ v: Int) -> String { String(UnicodeScalar(UInt8(65 + v))) }

/// One step of either search, with where both runners are afterwards.
struct RunnerStep {
    var tortoise: Int
    var hare: Int
    var kind: String
    var text: String
    /// The root and cycle length, once known.
    var root: Int?
    var length: Int?
}

@Reactive
final class CycleFindingModel {
    var brent = false
    var floydSteps: [RunnerStep] = []
    var brentSteps: [RunnerStep] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 800, scrubID: "scrub-cyclefinding")

    init() {
        let (floyd, brent) = cycleSearches()
        var t = 0, h = 0, root: Int?, length: Int?, phase = 1
        floydSteps = floyd.map { event in
            switch event {
            case .step(let a, let b):
                t = a; h = b
                let text = phase == 1
                    ? "The tortoise steps to \(pageName(a)), the hare two pages to \(pageName(b))."
                    : phase == 2 ? "Both step one page. The tortoise goes to \(pageName(a)), and the hare to \(pageName(b))." : "The hare walks the loop alone, to \(pageName(b))."
                return RunnerStep(tortoise: t, hare: h, kind: "step", text: text, root: root, length: length)
            case .meet(let v):
                phase = 2
                let s = RunnerStep(tortoise: t, hare: h, kind: "meet", text: "They meet at \(pageName(v)). The hare has lapped the tortoise, so both are on the loop. Now the tortoise goes back to A.", root: root, length: length)
                t = 0
                return s
            case .root(let v, let tail):
                phase = 3
                root = v
                return RunnerStep(tortoise: t, hare: h, kind: "root", text: "Moving one page each, they meet at \(pageName(v)). That is the first page of the loop, \(tail) clicks from A.", root: root, length: length)
            case .cycle(let n):
                length = n
                return RunnerStep(tortoise: t, hare: h, kind: "cycle", text: "The hare is back at \(pageName(root ?? 0)) after \(n) steps. So the loop is \(n) pages long.", root: root, length: length)
            }
        }
        t = 0; h = 0; root = nil; length = nil
        brentSteps = brent.map { event in
            switch event {
            case .step(let a, let b):
                let waits = a == t
                t = a; h = b
                let text = waits
                    ? "The hare steps to \(pageName(b)). The tortoise waits at \(pageName(a))."
                    : "Both step one page. The tortoise goes to \(pageName(a)), and the hare to \(pageName(b))."
                return RunnerStep(tortoise: t, hare: h, kind: "step", text: text, root: root, length: length)
            case .teleport(let v, let power):
                t = v
                return RunnerStep(tortoise: t, hare: h, kind: "teleport", text: "No meeting yet. The tortoise jumps to the hare at \(pageName(v)). The hare may now run \(power) steps before the next jump.", root: root, length: length)
            case .cycle(let n):
                length = n
                let s = RunnerStep(tortoise: t, hare: h, kind: "cycle", text: "The hare reaches the waiting tortoise after \(n) steps. So the loop is \(n) pages long. Now both start again at A, with the hare \(n) pages ahead.", root: root, length: length)
                t = 0
                return s
            case .root(let v, let tail):
                root = v
                return RunnerStep(tortoise: t, hare: h, kind: "root", text: "Staying \(length ?? 0) apart, they meet at \(pageName(v)). That is the first page of the loop, \(tail) clicks from A.", root: root, length: length)
            }
        }
        playback.reset(count: floydSteps.count)
    }

    var steps: [RunnerStep] { brent ? brentSteps : floydSteps }

    func choose(brent: Bool) {
        self.brent = brent
        playback.reset(count: steps.count)
    }
}

let cycleFindingModel = CycleFindingModel()

@View
struct CycleFindingLab {
    var body: some View {
        let model = cycleFindingModel
        let playback = model.playback
        let k = playback.k
        let steps = model.steps
        let finished = k == steps.count
        let now = k > 0 ? steps[k - 1] : RunnerStep(tortoise: 0, hare: 0, kind: "", text: "", root: nil, length: nil)
        let loop = Set(4 ... 8)
        let nodes = readingSpots.indices.map { v in
            let both = now.tortoise == v && now.hare == v
            return CanvasNode(x: readingSpots[v].x, y: readingSpots[v].y, name: both ? "both" : now.tortoise == v ? "tortoise" : now.hare == v ? "hare" : "",
                              badge: pageName(v), radius: 17,
                              classes: (both ? "cut" : now.tortoise == v ? "pal2" : now.hare == v ? "pal1" : finished && loop.contains(v) ? "visited" : "")
                                  + (now.root == v ? " selected" : ""),
                              nameAbove: v == 5 || v == 6 || v == 11)
        }
        let edges = nextPage.indices.map { v in
            CanvasEdge(from: v, to: nextPage[v], directed: true, classes: finished && loop.contains(v) ? "tree" : "")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The reading list")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Twelve pages, an arrow from each to the page its Next link opens", width: 680, height: 400, nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot pal2")) {}; "the tortoise" }
                        span { i(.class("dot pal1")) {}; "the hare" }
                        span { i(.class("dot selected")) {}; "where the loop starts" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "Found" : k == 0 ? "\(steps.count) events to come" : "Event \(k) of \(steps.count)" }
                        p(.class("narration")) {
                            if k == 0 {
                                model.brent
                                    ? "Brent’s way. The hare runs ahead while the tortoise waits. Each time the hare has run a power of two steps, the tortoise jumps to it. Press Step."
                                    : "Floyd’s way. Both runners start at A. Each turn the tortoise clicks Next once and the hare twice. If the pages loop, the hare must catch the tortoise. Press Step."
                            } else {
                                now.text
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "Known so far" }
                        div(.class("stat")) {
                            div(.class(now.root != nil ? "good" : "")) {
                                span(.class("num")) { now.root.map(pageName) ?? "?" }
                                "first page of the loop"
                            }
                            div(.class(now.length != nil ? "good" : "")) {
                                span(.class("num")) { now.length.map { "\($0)" } ?? "?" }
                                "pages in the loop"
                            }
                        }
                        p(.class("note")) { "Either method keeps just two bookmarks, however long the list. It keeps no record of the pages seen." }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    div(.class("segmented"), .custom(name: "role", value: "group"), .custom(name: "aria-label", value: "Method")) {
                        button(.type(.button), .class(model.brent ? "" : "on")) { "Floyd" }
                            .onClick { cycleFindingModel.choose(brent: false) }
                        button(.type(.button), .class(model.brent ? "on" : "")) { "Brent" }
                            .onClick { cycleFindingModel.choose(brent: true) }
                    }
                }
                Timeline(
                    playback: playback,
                    marbles: steps.map { s in
                        switch s.kind {
                        case "step": Marble(kind: "m-grey", radius: 5, title: s.text)
                        case "teleport": Marble(kind: "m-violet", radius: 8, title: s.text)
                        case "meet": Marble(kind: "m-blue", radius: 9, title: s.text)
                        default: Marble(kind: "m-red", radius: 10, letter: s.kind == "root" ? pageName(s.root ?? 0) : "\(s.length ?? 0)", title: s.text)
                        }
                    },
                    legend: [
                        (Marble(kind: "m-grey", radius: 4), "a step"),
                        (Marble(kind: "m-violet", radius: 6), "the tortoise jumps"),
                        (Marble(kind: "m-blue", radius: 6), "they meet"),
                        (Marble(kind: "m-red", radius: 6), "the loop’s start or length"),
                    ])
                p(.class("note")) { "The events come from lazy.floydCycleDetection(from:) or lazy.brentCycleDetection(from:)." }
            }
        }
    }
}

@View
struct CycleFindingCodePanel {
    var body: some View {
        let (floyd, brent) = cycleSearches()
        CodePanel(
            snippets: [.cyclefindingImports, .cyclefindingPages, .cyclefindingFloyd, .cyclefindingBrent],
            results: [
                "\(floyd.count) events, ending " + floyd.suffix(2).map { "\($0)" }.joined(separator: ", "),
                "\(brent.count) events, ending " + brent.suffix(2).map { "\($0)" }.joined(separator: ", "),
            ])
    }
}

enum CycleFindingPage {
    static func mount() {
        mountView(CycleFindingLab(), in: "app")
        mountView(CycleFindingCodePanel(), in: "code")
    }
}
