// snippet: networkmodels-imports
import AdjacencyListModule
import Cliques
import GraphDrawing
import GraphProtocols
import RandomGraphs
import ShortestPaths
// snippet end

// The two random networks of the network models page and what it measures on them. The marked
// regions are its code panels.

/// A Barabási–Albert network of `people` vertices, each newcomer making `links` links, from
/// `seed`, and a drawing of it.
func richGetRicher(people: Int, links: Int, seed: UInt64) -> (network: UndirectedAdjacencyList<Int>, drawing: Drawing<Int>) {
    // snippet: networkmodels-barabasi
    var generator = Xoshiro256StarStar(seed: seed)
    let network = UndirectedAdjacencyList<Int>.barabasiAlbert(vertexCount: people, edgesPerVertex: links, using: &generator)
    let degrees = network.vertices.map { network.degree(of: $0) }
    let biggest = degrees.max()!                                             // →
    // snippet end
    _ = biggest
    var placer = Xoshiro256StarStar(seed: seed)
    let drawing = network.fruchtermanReingoldLayout(iterations: 150, weight: { _ in 1.0 }, using: &placer)
    return (network, drawing)
}

/// A Watts–Strogatz ring of `people`, each joined to `neighbors` nearest, with each link
/// rewired with probability `p`, from `seed`: the network, its average clustering, and the
/// average number of links between two people who can reach each other.
func smallWorld(people: Int, neighbors: Int, p: Double, seed: UInt64) -> (network: UndirectedAdjacencyList<Int>, clustering: Double, separation: Double) {
    // snippet: networkmodels-watts
    var generator = Xoshiro256StarStar(seed: seed)
    let ring = UndirectedAdjacencyList<Int>.wattsStrogatz(vertexCount: people, nearestNeighborCount: neighbors, rewiringProbability: p, using: &generator)
    let clustering = ring.averageClustering()                                // →
    let hops = ring.directedView.floydWarshallShortestPaths { _ in 1 }!
    var total = 0, pairs = 0
    for a in 0 ..< people {
        for b in 0 ..< people where a != b {
            if let d = hops.distance(from: a, to: b) { total += d; pairs += 1 }
        }
    }
    let separation = Double(total) / Double(pairs)                           // →
    // snippet end
    return (ring, clustering, separation)
}
