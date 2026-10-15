// snippet: randomwalks-imports
import AdjacencyListModule
import GraphProtocols
import RandomGraphs
import Traversal
import Walks
// snippet end

// The park of the random walks page and the walks it asks for. The marked regions are its code
// panels.

// snippet: randomwalks-park
let parkPaths = [
    // The woods
    UndirectedEdge("Ash", "Birch"), UndirectedEdge("Ash", "Cedar"), UndirectedEdge("Birch", "Cedar"),
    UndirectedEdge("Birch", "Elm"), UndirectedEdge("Cedar", "Elm"), UndirectedEdge("Cedar", "Fir"),
    UndirectedEdge("Elm", "Fir"), UndirectedEdge("Elm", "Oak"), UndirectedEdge("Fir", "Oak"),
    // The river path
    UndirectedEdge("Oak", "Ford"), UndirectedEdge("Ford", "Mill"), UndirectedEdge("Mill", "Weir"),
    // The beach
    UndirectedEdge("Weir", "Bay"), UndirectedEdge("Bay", "Cove"), UndirectedEdge("Bay", "Dune"),
    UndirectedEdge("Cove", "Dune"), UndirectedEdge("Cove", "Reef"), UndirectedEdge("Dune", "Reef"),
    UndirectedEdge("Dune", "Sand"), UndirectedEdge("Reef", "Sand"), UndirectedEdge("Reef", "Tide"),
    UndirectedEdge("Sand", "Tide"),
]

let park = UndirectedAdjacencyList<String> {
    for path in parkPaths { path }
}
// snippet end

/// A seeded node2vec walk of `length` steps from Ash.
func parkWalk(p: Double, q: Double, length: Int, seed: UInt64) -> Walk<String, Int> {
    // snippet: randomwalks-walk
    var generator = Xoshiro256StarStar(seed: seed)
    let walk = park.randomWalk(from: "Ash", length: length, returnParameter: p, inOutParameter: q, using: &generator)
    let places = walk.vertices                      // →
    let distinct = Set(walk.vertices).count         // →
    // snippet end
    _ = (places, distinct)
    return walk
}
