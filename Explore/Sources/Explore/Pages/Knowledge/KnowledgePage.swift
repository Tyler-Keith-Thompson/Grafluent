import ElementaryUI
import GraphProtocols
import Multigraphs
import Reactivity

/// Where each entity sits in the 640 × 470 view box; the extra spellings sit beside their entity.
let knowledgeSpots: [(name: String, x: Double, y: Double)] = [
    ("Ada Lovelace", 210, 170), ("Analytical Engine", 340, 250), ("Lord Byron", 130, 90), ("Charles Babbage", 350, 100),
    ("Difference Engine", 520, 90), ("Punched cards", 340, 380), ("Jacquard loom", 480, 440), ("Poetry", 40, 190),
    ("Greece", 40, 40), ("Logarithms", 610, 180), ("Royal Society", 510, 240), ("Isaac Newton", 610, 320),
    ("Alan Turing", 180, 340), ("Bletchley Park", 70, 430),
    ("A. Lovelace", 110, 270), ("Lovelace, Ada", 250, 30), ("Babbage", 460, 30), ("C. Babbage", 440, 170),
]

let knowledgeIndex: [String: Int] = Dictionary(uniqueKeysWithValues: knowledgeSpots.enumerated().map { ($0.element.name, $0.offset) })

/// The knowledge page's state: the merge count, the retrieval, and the playback over the stages.
@Reactive
final class KnowledgeModel {
    @ReactiveIgnored let merge = mergedCount()
    @ReactiveIgnored let retrieval = try! retrieveFacts(budget: 7)
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 1800, scrubID: "scrub-knowledge")

    init() {
        playback.reset(count: 4)
    }
}

let knowledgeModel = KnowledgeModel()

/// The vertices: every spelling before the merge, the entities after, ranked and then kept.
func knowledgeNodes(_ model: KnowledgeModel, stage k: Int) -> [CanvasNode] {
    let shown = k == 0 ? knowledgeSpots : Array(knowledgeSpots.prefix(14))
    return shown.map { spot in
        let rank = model.retrieval.ranks[spot.name] ?? 0
        let kept = model.retrieval.kept.contains(spot.name)
        let classes: String
        if k >= 2 && questionSeeds.contains(spot.name) { classes = "current" } else if k >= 3 && kept { classes = "done" } else if k >= 3 { classes = "faint" } else { classes = "" }
        return CanvasNode(x: spot.x, y: spot.y, name: spot.name, badge: k >= 2 ? shareText(rank) : "", radius: 13, classes: classes)
    }
}

/// The relations: between spellings before the merge, between entities after; kept ones picked out.
func knowledgeEdges(_ model: KnowledgeModel, stage k: Int) -> [CanvasEdge] {
    if k == 0 {
        return claims.map { CanvasEdge(from: knowledgeIndex[$0.subject]!, to: knowledgeIndex[$0.object]!, directed: true, label: $0.relation) }
    }
    return knowledgeGraph.edges.indices.map { position in
        let edge = knowledgeGraph.edges[position]
        let kept = model.retrieval.kept.contains(edge.source) && model.retrieval.kept.contains(edge.target)
        return CanvasEdge(from: knowledgeIndex[edge.source]!, to: knowledgeIndex[edge.target]!, directed: true,
                          label: knowledgeGraph[relationOf, ofEdgeAt: position], classes: k >= 3 ? (kept ? "tree" : "faint") : "")
    }
}

/// One stage's marble.
func knowledgeMarble(_ k: Int, _ model: KnowledgeModel) -> Marble {
    Marble(kind: k == 4 ? "m-done" : "m-current", radius: 7, letter: "\(k)", title: describeKnowledge(k, model))
}

/// The sentence for one stage.
func describeKnowledge(_ k: Int, _ model: KnowledgeModel) -> String {
    switch k {
    case 1: return "Merged: \(model.merge.spellings) spellings become \(model.merge.entities) entities, so each relation now joins the right pair."
    case 2:
        let top = model.retrieval.ranks.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key < $1.key) }.prefix(3).map { "\($0.key) \(shareText($0.value))" }
        return "Ranked from the question’s entities by personalised PageRank: \(nameList(top))."
    case 3: return "Retrieved: within two hops, the \(model.retrieval.kept.count) best-ranked entities and every relation among them."
    default: return "Written as one line per relation, ready to paste into a prompt."
    }
}

/// A knowledge graph from claims to a prompt, one stage a step.
@View
struct KnowledgeLab {
    var body: some View {
        let model = knowledgeModel
        let playback = model.playback
        let k = playback.k
        let nodes = knowledgeNodes(model, stage: k)
        let edges = knowledgeEdges(model, stage: k)

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "A knowledge graph from claims to a prompt")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "Entities and their relations, every spelling at first, merged, ranked from the question and cut to a budget", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("dot current")) {}; "named in the question" }
                        span { i(.class("dot done")) {}; "retrieved; number: rank from the question" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == 0 ? "As extracted" : (k == 4 ? "For the prompt" : "Stage \(k) of 4") }
                        p(.class("narration")) {
                            if k == 0 {
                                "An extractor turned a few paragraphs into \(claims.count) claims, each a subject, a relation and an object, and spelled two people three ways each. The question asks about Ada Lovelace and the Analytical Engine. Press Step to clean the graph, rank it from the question, cut it to a budget and write what remains."
                            } else {
                                describeKnowledge(k, model)
                            }
                        }
                    }
                    if k == 4 {
                        div(.class("panel")) {
                            span(.class("label")) { "subject | object | relation" }
                            pre(.class("paste-line")) { model.retrieval.prompt }
                        }
                    }
                }
            }
            section(.class("panel controls"), .custom(name: "aria-label", value: "Playback")) {
                div(.class("buttons")) {
                    PlaybackButtons(playback: playback)
                }
                Timeline(
                    playback: playback,
                    marbles: (1 ... 4).map { knowledgeMarble($0, model) },
                    legend: [(Marble(kind: "m-current", radius: 7), "merge, rank, retrieve"), (Marble(kind: "m-done", radius: 7), "write the prompt")])
                p(.class("note")) { "Each stage is one call: quotient(of:byKey:), pageRank(personalization:), egoGraphView(of:radius:undirected:maximumVertexCount:priority:) and writeEdgeList(to:columns:delimiter:edgeAttributes:)." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct KnowledgeCodePanel {
    var body: some View {
        let model = knowledgeModel
        CodePanel(
            snippets: [.knowledgeImports, .knowledgeClaims, .knowledgeMerge, .knowledgeGraph, Snippet(lines: ["let budget = 7"]), .knowledgeRetrieve],
            results: ["\(model.merge.entities)", "\(model.retrieval.kept)"])
    }
}

enum KnowledgePage {
    static func mount() {
        mountView(KnowledgeLab(), in: "app")
        mountView(KnowledgeCodePanel(), in: "code")
    }
}
