// snippet: pagerank-imports
import AdjacencyListModule
import Centrality
import GraphProtocols
import Traversal
// snippet end

/// Each page's PageRank, in `pages` order, or the error when the iteration did not settle.
func ranks(pages: [String], links: [(String, String)], damping: Double) -> Result<[Double], NoConvergence> {
    do throws(NoConvergence) {
        // snippet: pagerank-rank
        let web = AdjacencyList<String> {
            for page in pages { page }
            for (from, to) in links { DirectedEdge(from: from, to: to) }
        }
        let ranks = try web.pageRank(dampingFactor: damping, maxIterations: 1000)
        let scores = pages.map { ranks.score(of: $0) }  // →
        // snippet end
        return .success(scores)
    } catch {
        return .failure(error)
    }
}

/// A random number generator that replays from its seed (SplitMix64).
struct SplitMix64: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// The first 200 pages a random surfer visits, each marked when the surfer jumped there rather
/// than following a link.
func surf(pages: [String], links: [(String, String)], damping: Double, seed: UInt64) -> [(page: String, jumped: Bool)] {
    // snippet: pagerank-surf
    let web = AdjacencyList<String> {
        for page in pages { page }
        for (from, to) in links { DirectedEdge(from: from, to: to) }
    }
    // A surfer jumps to a random page, follows links while a coin with odds `damping` says
    // keep going, then jumps again.
    var generator = SplitMix64(seed: seed)
    var visits: [(page: String, jumped: Bool)] = []
    while visits.count < 200 {
        var clicks = 0
        while clicks < 50, Double.random(in: 0 ..< 1, using: &generator) < damping { clicks += 1 }
        // One draw of 64 bits picks the page, so a seed gives the same surfer on every platform.
        let jump = pages[Int(generator.next() % UInt64(pages.count))]
        let walk = web.randomWalk(from: jump, length: clicks, using: &generator)
        visits += walk.enumerated().map { (page: $0.element, jumped: $0.offset == 0) }
    }
    // snippet end
    return Array(visits.prefix(200))
}
