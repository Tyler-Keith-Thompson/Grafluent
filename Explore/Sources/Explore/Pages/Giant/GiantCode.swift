// snippet: giant-imports
import AdjacencyListModule
import Connectivity
import GraphDrawing
import GraphProtocols
import RandomGraphs
// snippet end

// The random friendships of the giant component page. The marked regions are its code panel.

/// `edgeCount` random friendships among `people`, from `seed`, in a random order: the first m of
/// them are a uniform G(n, m).
func friendshipOrder(people: Int, edgeCount: Int, seed: UInt64) -> [UndirectedEdge<Int>] {
    // snippet: giant-draw
    var generator = Xoshiro256StarStar(seed: seed)
    let drawn = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: people, edgeCount: edgeCount, using: &generator)
    // The edges come out sorted; shuffle them to add them one at a time.
    var order = Array(drawn.edges)
    for i in order.indices.reversed() {
        order.swapAt(i, Int(generator.next() % UInt64(i + 1)))
    }
    // snippet end
    return order
}

/// The groups of `people` after the first `added` friendships of `order`, largest first.
func friendshipGroups(people: Int, order: [UndirectedEdge<Int>], added: Int) -> [[Int]] {
    // snippet: giant-groups
    let school = UndirectedAdjacencyList<Int> {
        for person in 0 ..< people { person }
        for friendship in order.prefix(added) { friendship }
    }
    let groups = school.connectedComponents()
    let largest = groups.map(\.count).max()!  // →
    // snippet end
    _ = largest
    return groups.map(Array.init).sorted { ($1.count, $0[0]) < ($0.count, $1[0]) }
}

/// Where to draw each person: a force-directed drawing of the school with every friendship, so
/// the groups sit together all along. One extra, undrawn vertex is tied weakly to everyone, so
/// people without friends stay near the rest instead of drifting off.
func friendshipDrawing(people: Int, order: [UndirectedEdge<Int>], seed: UInt64) -> Drawing<Int> {
    // snippet: giant-layout
    let centre = people
    let everyone = UndirectedAdjacencyList<Int> {
        for person in 0 ..< people { UndirectedEdge(person, centre) }
        for friendship in order { friendship }
    }
    var placer = Xoshiro256StarStar(seed: seed)
    let drawing = everyone.fruchtermanReingoldLayout(iterations: 150, weight: { everyone.edges[$0].v == centre ? 0.15 : 1 }, using: &placer)
    // snippet end
    return drawing
}
