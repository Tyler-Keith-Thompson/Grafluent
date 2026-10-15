import Centrality
import GraphProtocols
import ElementaryUI
import Reactivity

let webSpots: [(name: String, x: Double, y: Double)] = [
    ("Home", 320, 200), ("Blog", 150, 90), ("Recipes", 140, 300), ("About", 500, 70),
    ("Shop", 500, 320), ("Forum", 330, 385),
]
let webPages = webSpots.map(\.name)
let startingLinks: [(String, String)] = [
    ("Home", "Blog"), ("Home", "Shop"), ("Home", "About"), ("Blog", "Recipes"), ("Blog", "Home"),
    ("Recipes", "Blog"), ("Recipes", "Home"), ("About", "Home"), ("Shop", "Home"), ("Shop", "Recipes"),
    ("Forum", "Recipes"), ("Forum", "Blog"),
]

@Reactive
final class PageRankModel {
    var links = startingLinks
    /// Twentieths: 17 is a damping factor of 0.85.
    var damping = 17
    var selected: Int?
    var seed: UInt64 = 1
    var outcome: Result<[Double], NoConvergence> = .success([])
    var visits: [(page: String, jumped: Bool)] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 140)

    init() { rerun() }

    func rerun() {
        outcome = ranks(pages: webPages, links: links, damping: Double(damping) / 20)
        visits = surf(pages: webPages, links: links, damping: Double(damping) / 20, seed: seed)
        playback.reset(count: visits.count)
    }

    func toggle(_ a: String, _ b: String) {
        if let i = links.firstIndex(where: { $0 == (a, b) }) { links.remove(at: i) } else { links.append((a, b)) }
        rerun()
    }

    func tap(_ v: Int) {
        if let u = selected, u != v {
            toggle(webPages[u], webPages[v])
            selected = nil
        } else {
            selected = selected == v ? nil : v
        }
    }
}

let pageRankModel = PageRankModel()

func dampingText(_ twentieths: Int) -> String {
    guard twentieths < 20 else { return "1.0" }
    let hundredths = twentieths * 5
    return "0." + (hundredths < 10 ? "0" : "") + "\(hundredths)"
}

/// `x` to two decimal places.
func twoPlaces(_ x: Double) -> String {
    let n = Int((x * 100).rounded())
    return "\(n / 100)." + (n % 100 < 10 ? "0" : "") + "\(n % 100)"
}

/// `x` to three decimal places.
func threePlaces(_ x: Double) -> String {
    let n = Int((x * 1000).rounded())
    let r = n % 1000
    return "\(n / 1000)." + (r < 10 ? "00" : r < 100 ? "0" : "") + "\(r)"
}

@View
struct PageRankLab {
    var body: some View {
        let model = pageRankModel
        let outcome = model.outcome
        let scores: [Double] = (try? outcome.get()) ?? []
        let top = scores.max() ?? 1
        let playback = model.playback
        let k = playback.k
        let seen = model.visits.prefix(k)
        let counts = webPages.map { page in seen.filter { $0.page == page }.count }
        let here = k > 0 ? model.visits[k - 1] : nil
        let nodes = webSpots.enumerated().map { v, spot in
            let score = scores.isEmpty ? 1 / Double(webPages.count) : scores[v]
            return CanvasNode(x: spot.x, y: spot.y, name: spot.name, note: twoPlaces(score), radius: 10 + 70 * score,
                              classes: (score == top ? "frontier" : "visited") + (model.selected == v ? " selected" : "") + (here?.page == spot.name ? " current" : ""))
        }
        let previous = k > 1 ? model.visits[k - 2].page : ""
        let edges = model.links.map { a, b in
            CanvasEdge(from: webPages.firstIndex(of: a)!, to: webPages.firstIndex(of: b)!, directed: true,
                       classes: here.map { !$0.jumped && $0.page == b && previous == a } ?? false ? "active" : "",
                       bend: model.links.contains { $0 == (b, a) } ? 12 : 0)
        }
        let ranked = webPages.indices.sorted { (scores.isEmpty ? 0 : scores[$1], $0) < (scores.isEmpty ? 0 : scores[$0], $1) }
        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A tiny web")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Six web pages; an arrow for each link", width: 640, height: 440,
                                nodes: nodes, edges: edges, onNode: { pageRankModel.tap($0) },
                                onEdge: { i in
                                    let (a, b) = pageRankModel.links[i]
                                    pageRankModel.toggle(a, b)
                                }, nodeAction: "Pick")
                    p(.class("note")) {
                        if let selected = model.selected {
                            "\(webPages[selected]) is picked: click another page to add or remove a link to it."
                        } else {
                            "Bigger circle, higher rank. Click one page and then another to add a link; click an arrow to remove it."
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { "PageRank, highest first" }
                        if case .failure(let error) = outcome {
                            p(.class("narration")) { "The scores were still moving after \(error.iterations) rounds, so Grafluent threw NoConvergence." }
                        } else {
                            div(.class("bars")) {
                                for v in ranked {
                                    div(.class(scores[v] == top ? "bar top" : "bar")) {
                                        span { webPages[v] }
                                        span(.class("track")) {
                                            span(.class("fill"), .style("width: \(Int((scores[v] * 200).rounded()))%; display: block;")) {}
                                            span(.class("visits"), .style("left: \(k == 0 ? 0 : Int((Double(counts[v]) / Double(k) * 200).rounded()))%;")) {}
                                        }
                                        span(.class("num")) { threePlaces(scores[v]) }
                                    }
                                }
                            }
                        }
                        p(.class("note")) {
                            "Bars: PageRank, which adds up to 1. Black ticks: the share of the surfer’s \(k) visits so far on each page. The longer the surfer goes, the closer the ticks come to the bars."
                        }
                    }
                    div(.class("panel")) {
                        label(.class("field"), .for("damping")) {
                            "Damping "
                            input(.id("damping"), .type(.range), .min(0), .max(20), .value("\(model.damping)"))
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) {
                                        pageRankModel.damping = n
                                        pageRankModel.rerun()
                                    }
                                }
                            span(.class("num")) { dampingText(model.damping) }
                        }
                        p(.class("note")) {
                            "At \(dampingText(model.damping)) the surfer follows a link \(model.damping * 5)% of the time and jumps to a random page otherwise. At 0 every page scores the same."
                        }
                        div(.class("buttons")) {
                            button(.type(.button)) { "Reset" }
                                .onClick {
                                    pageRankModel.links = startingLinks
                                    pageRankModel.damping = 17
                                    pageRankModel.selected = nil
                                    setProperty(id: "damping", "value", to: "17")
                                    pageRankModel.rerun()
                                }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                    span(.class("spacer")) {}
                    button(.type(.button)) { "New surfer" }
                        .onClick {
                            pageRankModel.seed &+= 1
                            pageRankModel.rerun()
                            pageRankModel.playback.play()
                        }
                }
                Timeline(
                    playback: playback,
                    marbles: model.visits.map { visit in
                        visit.jumped
                            ? Marble(kind: "m-ring", radius: 9, title: "Bored: jump to \(visit.page).")
                            : Marble(kind: "m-blue", radius: 9, letter: String(visit.page.prefix(1)), title: "Follow a link to \(visit.page).")
                    },
                    legend: [(Marble(kind: "m-blue", radius: 6), "follow a link"), (Marble(kind: "m-ring", radius: 5), "jump to a random page")])
                p(.class("note")) { "A random surfer, step by step: Grafluent’s randomWalk follows the links, and the surfer jumps whenever the damping coin says stop." }
            }
        }
    }
}

@View
struct PageRankCodePanel {
    var body: some View {
        let model = pageRankModel
        let outcome = model.outcome
        let result: String = switch outcome {
        case .success(let scores): "[" + scores.map(threePlaces).joined(separator: ", ") + "]"
        case .failure(let error): "throws NoConvergence after \(error.iterations) iterations"
        }
        CodePanel(
            snippets: [
                .pagerankImports,
                Snippet(lines: ["let pages = [" + webPages.map { "\"\($0)\"" }.joined(separator: ", ") + "]", "let links = ["]
                    + model.links.map { "    (\"\($0.0)\", \"\($0.1)\")," } + ["]", "let damping = \(dampingText(model.damping))"]),
                .pagerankRank,
                Snippet(lines: ["let seed: UInt64 = \(model.seed)"]),
                .pagerankSurf,
            ],
            results: [result])
    }
}

enum PageRankPage {
    static func mount() {
        mountView(PageRankLab(), in: "app")
        mountView(PageRankCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.kleinberg]), in: "names")
    }
}
