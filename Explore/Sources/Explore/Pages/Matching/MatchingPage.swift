import ElementaryUI
import Reactivity

let applicants = ["Ana", "Ben", "Cy", "Dee", "Eli"]
let jobs = ["Barista", "Cashier", "Driver", "Florist", "Gardener"]
let startingSkills: [(String, String)] = [
    ("Ana", "Barista"), ("Ana", "Cashier"), ("Ben", "Barista"), ("Cy", "Cashier"), ("Cy", "Driver"),
    ("Cy", "Florist"), ("Dee", "Driver"), ("Eli", "Driver"),
]

@Reactive
final class MatchingModel {
    var canDo = startingSkills
    var selected: Int?
    /// The hires after each applicant arrives: `rounds[k - 1]` has the first `k`.
    var rounds: [[(applicant: String, job: String)]] = []
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1100)

    init() { rerun() }

    func rerun() {
        rounds = arrivals(applicants: applicants, jobs: jobs, canDo: canDo)
        playback.reset(count: rounds.count)
        playback.show(rounds.count)
    }

    func toggle(_ applicant: String, _ job: String) {
        if let i = canDo.firstIndex(where: { $0 == (applicant, job) }) { canDo.remove(at: i) } else { canDo.append((applicant, job)) }
        rerun()
    }

    /// What happened when applicant `k` (from 1) arrived: hired straight into a free job,
    /// hired after earlier hires moved, or left out.
    func arrival(_ k: Int) -> (kind: String, text: String) {
        let now = rounds[k - 1], before = k > 1 ? rounds[k - 2] : []
        let name = applicants[k - 1]
        guard let job = now.first(where: { $0.applicant == name })?.job else {
            return ("none", "\(name) arrives. No chain of swaps frees a job \(name) can do, so \(name) is left out.")
        }
        let moved = before.filter { old in !now.contains { $0 == old } }
        if moved.isEmpty { return ("direct", "\(name) arrives and takes the free \(job.lowercased()) job.") }
        let moves = moved.map { old in "\(old.applicant) moves from \(old.job.lowercased()) to \(now.first { $0.applicant == old.applicant }!.job.lowercased())" }
        return ("chain", "\(name) arrives and takes \(job.lowercased()) after a chain of swaps: " + moves.joined(separator: ", ") + ".")
    }

    /// Nodes 0..<5 are applicants, 5..<10 jobs: pick one of each to toggle the pair.
    func tap(_ v: Int) {
        guard let u = selected, (u < 5) != (v < 5) else {
            selected = selected == v ? nil : v
            return
        }
        let (a, j) = u < 5 ? (u, v - 5) : (v, u - 5)
        toggle(applicants[a], jobs[j])
        selected = nil
    }
}

let matchingModel = MatchingModel()

@View
struct MatchingLab {
    var body: some View {
        let model = matchingModel
        let canDo = model.canDo
        let playback = model.playback
        let k = playback.k
        let pairs = k > 0 ? model.rounds[k - 1] : []
        let present = Set(applicants.prefix(k))
        let hired = Set(pairs.map(\.applicant)), filled = Set(pairs.map(\.job))
        let isMatched = { (a: String, j: String) in pairs.contains { $0 == (a, j) } }
        let nodes = applicants.enumerated().map { n, name in
            CanvasNode(x: 120, y: 50 + Double(n) * 80, name: name, badge: String(name.prefix(1)), radius: 18,
                       classes: (hired.contains(name) ? "visited" : present.contains(name) ? "free" : "dim") + (model.selected == n ? " selected" : "")
                           + (n == k - 1 ? " current" : ""), nameAbove: true)
        } + jobs.enumerated().map { n, name in
            CanvasNode(x: 520, y: 50 + Double(n) * 80, name: name, badge: String(name.prefix(1)), radius: 18,
                       classes: (filled.contains(name) ? "visited" : "free") + (model.selected == n + 5 ? " selected" : ""), nameAbove: true)
        }
        let edges = canDo.map { a, j in
            CanvasEdge(from: applicants.firstIndex(of: a)!, to: 5 + jobs.firstIndex(of: j)!, classes: isMatched(a, j) ? "matched" : present.contains(a) ? "" : "ghost")
        }
        let idle = applicants.filter { !hired.contains($0) }
        let finished = k == model.rounds.count
        div {
            section(.class("lab"), .custom(name: "aria-label", value: "Applicants and jobs")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Applicants in one column, jobs in the other, and a line for each job an applicant can do", width: 640, height: 430,
                                nodes: nodes, edges: edges, onNode: { matchingModel.tap($0) },
                                onEdge: { i in
                                    let (a, j) = matchingModel.canDo[i]
                                    matchingModel.toggle(a, j)
                                }, nodeAction: "Pick")
                    div(.class("legend")) {
                        span { i(.class("line matched")) {}; "hired for that job" }
                        span { i(.class("line")) {}; "could do it" }
                        span { i(.class("dot")) {}; "dashed ring: left without a match" }
                    }
                    p(.class("note")) {
                        if let selected = model.selected {
                            "\(selected < 5 ? applicants[selected] : jobs[selected - 5]) is picked: click someone on the other side to add or remove that pairing."
                        } else {
                            "Click an applicant, then a job, to say they can or can’t do it. Clicking a line removes it."
                        }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { finished ? "\(pairs.count) of \(applicants.count) hired" : "\(k) of \(applicants.count) applicants have arrived" }
                        div(.class("queue")) {
                            for pair in pairs {
                                div(.class("qrow plain")) {
                                    span { pair.applicant }
                                    span { pair.job }
                                }
                            }
                        }
                        p(.class("narration")) {
                            if k == 0 {
                                "The applicants arrive one at a time. Each one takes a free job if there is one; if not, look for a chain of swaps that frees one."
                            } else if !finished {
                                model.arrival(k).text
                            } else if idle.isEmpty {
                                "Everyone has a job, and no job has two people: a perfect matching."
                            } else {
                                "No arrangement hires more than \(pairs.count). "
                                let stuck = applicants.filter { a in canDo.filter { $0.0 == a }.count == 1 }
                                let rivals = Dictionary(grouping: stuck, by: { a in canDo.first { $0.0 == a }!.1 }).filter { $0.value.count > 1 }
                                if let rival = rivals.first {
                                    "\(rival.value.joined(separator: " and ")) can only be a \(rival.key.lowercased()), and there is one \(rival.key.lowercased()) job."
                                } else {
                                    "\(idle.joined(separator: ", ")) \(idle.count == 1 ? "is" : "are") left over."
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
                    button(.type(.button)) { "Teach Eli to garden" }
                        .attributes(.disabled, when: canDo.contains { $0 == ("Eli", "Gardener") })
                        .onClick { matchingModel.toggle("Eli", "Gardener") }
                    button(.type(.button)) { "Reset" }
                        .onClick {
                            matchingModel.canDo = startingSkills
                            matchingModel.selected = nil
                            matchingModel.rerun()
                        }
                }
                Timeline(
                    playback: playback,
                    marbles: model.rounds.indices.map { i in
                        let arrival = model.arrival(i + 1)
                        let letter = String(applicants[i].prefix(1))
                        switch arrival.kind {
                        case "direct": return Marble(kind: "m-blue", radius: 11, letter: letter, title: arrival.text)
                        case "chain": return Marble(kind: "m-ring", radius: 11, letter: "", title: arrival.text)
                        default: return Marble(kind: "m-red", radius: 9, letter: letter, title: arrival.text)
                        }
                    },
                    legend: [(Marble(kind: "m-blue", radius: 6), "takes a free job"), (Marble(kind: "m-ring", radius: 5), "hired after a chain of swaps"),
                             (Marble(kind: "m-red", radius: 5), "left out")])
            }
        }
    }
}

@View
struct MatchingCodePanel {
    var body: some View {
        let canDo = matchingModel.canDo
        let pairs = matchingModel.rounds.last ?? []
        CodePanel(
            snippets: [
                .matchingImports,
                Snippet(lines: [
                    "let applicants = [" + applicants.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
                    "let jobs = [" + jobs.map { "\"\($0)\"" }.joined(separator: ", ") + "]",
                    "let canDo = [",
                ] + canDo.map { "    (\"\($0.0)\", \"\($0.1)\")," } + ["]"]),
                .matchingHire, .matchingArrivals,
            ],
            results: ["\(pairs.count) pairs: " + pairs.map { "\($0.applicant)–\($0.job)" }.joined(separator: ", ")])
    }
}

enum MatchingPage {
    static func mount() {
        mountView(MatchingLab(), in: "app")
        mountView(MatchingCodePanel(), in: "code")
        mountView(NamesStrip(names: [Names.konig]), in: "names")
    }
}
