import AdjacencyListModule
import ElementaryUI
import GraphProducts
import GraphProtocols
import Reactivity

/// The squares of the board and where they sit, in SVG units of the 640 × 470 view box.
let boardSquares: [(name: String, x: Double, y: Double)] = {
    var spots: [(String, Double, Double)] = []
    for (r, rank) in ["1", "2", "3"].enumerated() {
        for (f, file) in ["a", "b", "c", "d"].enumerated() {
            spots.append((file + rank, 140 + Double(f) * 120, 370 - Double(r) * 130))
        }
    }
    return spots
}()

/// The index in `boardSquares` of each square.
let squareIndex: [String: Int] = Dictionary(uniqueKeysWithValues: boardSquares.enumerated().map { ($0.element.name, $0.offset) })

/// The four products, their names and the piece each one moves like.
let boardKinds: [(name: String, piece: String, rule: String)] = [
    ("Cartesian", "a rook taking one step", "change the file or the rank by one step, not both"),
    ("tensor", "a bishop taking one step", "change the file and the rank, one step each"),
    ("strong", "a king", "change the file, the rank, or both, one step each"),
    ("lexicographic", "a courier", "change the file by one step and land on any rank, or keep the file and change the rank by one"),
]

/// Whether a move changes the file, the rank, or both.
func boardMoveKind(_ move: (String, String)) -> String {
    let fileChanged = move.0.first != move.1.first
    let rankChanged = move.0.last != move.1.last
    let rankJump = rankChanged && abs(Int(String(move.0.last!))! - Int(String(move.1.last!))!) > 1
    return fileChanged && rankChanged ? (rankJump ? "file and a jump in rank" : "file and rank") : (fileChanged ? "file only" : "rank only")
}

/// The products page's state: the product shown and the playback over its moves.
@Reactive
final class ProductsModel {
    var kind = 0
    @ReactiveIgnored let playback = Playback(millisecondsPerStep: 500, scrubID: "scrub-products")

    init() {
        playback.reset(count: boardMoves(0).count)
    }

    func choose(kind: Int) {
        self.kind = kind
        playback.reset(count: boardMoves(kind).count)
        setProperty(id: "products-kind", "value", to: "\(kind)")
    }
}

let productsModel = ProductsModel()

/// The squares a step from b2 in each product.
func boardNeighbours(_ kind: Int) -> [String] {
    let b2 = Pair("b", "2")
    let squares: [Pair<String, String>]
    switch kind {
    case 0: squares = Array(cartesianProductView(files, ranks).neighbors(of: b2))
    case 1: squares = Array(tensorProductView(files, ranks).neighbors(of: b2))
    case 2: squares = Array(strongProductView(files, ranks).neighbors(of: b2))
    default: squares = Array(lexicographicProductView(files, ranks).neighbors(of: b2))
    }
    return squares.map { $0.first + $0.second }
}

/// The sentence for one move.
func describeMove(_ move: (String, String), number: Int, of total: Int) -> String {
    "Move \(number) of \(total): \(move.0) to \(move.1), changing the \(boardMoveKind(move))."
}

/// The board with the product's moves drawn one at a time.
@View
struct ProductsLab {
    var body: some View {
        let model = productsModel
        let playback = model.playback
        let k = playback.k
        let kind = boardKinds[model.kind]
        let moves = boardMoves(model.kind)
        let current = k > 0 ? moves[k - 1] : nil
        let touched = Set(moves.prefix(k).flatMap { [squareIndex[$0.0]!, squareIndex[$0.1]!] })
        let nodes = boardSquares.enumerated().map { v, spot in
            CanvasNode(x: spot.x, y: spot.y, name: spot.name, radius: 15,
                       classes: current.map { squareIndex[$0.0]! == v || squareIndex[$0.1]! == v } == true ? "current" : (touched.contains(v) ? "visited" : ""))
        }
        let edges = moves.prefix(k).enumerated().map { n, move in
            CanvasEdge(from: squareIndex[move.0]!, to: squareIndex[move.1]!, classes: n == k - 1 ? "current" : "tree")
        }

        div {
            section(.class("lab"), .custom(name: "aria-label", value: "The moves of a graph product on a board")) {
                div(.class("panel stage")) {
                    GraphCanvas(label: "A board of four files and three ranks, with the moves of the \(kind.name) product drawn so far", width: 640, height: 470,
                                nodes: nodes, edges: edges)
                    div(.class("legend")) {
                        span { i(.class("line current")) {}; "the move just drawn" }
                        span { i(.class("line tree")) {}; "an earlier move" }
                    }
                }
                div(.class("side")) {
                    div(.class("panel"), .custom(name: "aria-live", value: "polite")) {
                        span(.class("label")) { k == 0 ? "The \(kind.name) product" : (k == moves.count ? "All \(moves.count) moves" : "Move \(k) of \(moves.count)") }
                        p(.class("narration")) {
                            if k == 0 {
                                "Files a to d are a path of four; ranks 1 to 3 are a path of three. Their \(kind.name) product has a square for every file and rank, and it moves like \(kind.piece): \(kind.rule). Press Step to draw its moves."
                            } else {
                                describeMove(current!, number: k, of: moves.count)
                                if k == moves.count { " That is every move of the \(kind.name) product: \(moves.count) in all, from \(boardSquares.count) squares." }
                            }
                        }
                    }
                    div(.class("panel")) {
                        div(.class("buttons")) {
                            label(.class("field"), .for("products-kind")) {
                                "Product: "
                                select(.id("products-kind")) {
                                    for (n, kind) in boardKinds.enumerated() {
                                        option(.value("\(n)")) { kind.name }.attributes(.selected, when: model.kind == n)
                                    }
                                }
                                .onInput { event in
                                    if let value = event.targetValue, let n = Int(value) { productsModel.choose(kind: n) }
                                }
                            }
                        }
                    }
                    div(.class("panel")) {
                        span(.class("label")) { "The four products" }
                        div(.class("queue")) {
                            for (n, kind) in boardKinds.enumerated() {
                                div(.class(n == model.kind ? "qrow top" : "qrow plain")) {
                                    span { "\(kind.name): \(kind.piece)" }
                                    span(.class("num")) { "\(boardMoves(n).count) moves" }
                                }
                            }
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
                    marbles: moves.enumerated().map { n, move in
                        let what = boardMoveKind(move)
                        return Marble(kind: what == "file only" ? "m-pal0" : (what == "rank only" ? "m-pal1" : "m-pal2"), radius: 6, letter: "",
                                      title: describeMove(move, number: n + 1, of: moves.count))
                    },
                    legend: [(Marble(kind: "m-pal0", radius: 6), "a move along a file"), (Marble(kind: "m-pal1", radius: 6), "a move along a rank"), (Marble(kind: "m-pal2", radius: 6), "a move that changes both")])
                p(.class("note")) { "The product is a lazy view. Each step draws one more of its edges, in the order the view lists them." }
            }
        }
    }
}

/// The lab's code panel.
@View
struct ProductsCodePanel {
    var body: some View {
        let model = productsModel
        let moves = boardMoves(model.kind)
        let from = boardNeighbours(model.kind)
        let quoted = "[" + from.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        switch model.kind {
        case 0: CodePanel(snippets: [.productsImports, .productsBoard, .productsCartesian], results: ["\(boardSquares.count)", "\(moves.count)", quoted])
        case 1: CodePanel(snippets: [.productsImports, .productsBoard, .productsTensor], results: ["\(moves.count)", quoted])
        case 2: CodePanel(snippets: [.productsImports, .productsBoard, .productsStrong], results: ["\(moves.count)", quoted])
        default: CodePanel(snippets: [.productsImports, .productsBoard, .productsLexicographic], results: ["\(moves.count)", quoted])
        }
    }
}

enum ProductsPage {
    static func mount() {
        mountView(ProductsLab(), in: "app")
        mountView(ProductsCodePanel(), in: "code")
    }
}
