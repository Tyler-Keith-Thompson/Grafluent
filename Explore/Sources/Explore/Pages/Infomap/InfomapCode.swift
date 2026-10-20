// snippet: infomap-imports
import AdjacencyListModule
import CommunityDetection
import GraphProtocols
import RandomGraphs
// snippet end

// The trails and the calls the Infomap page makes. The marked regions are its code panels.

// snippet: infomap-trails
/// A park's footpaths: three clearings, each a knot of paths, joined by a few long trails.
let footways = [
    UndirectedEdge("A1", "A2"), UndirectedEdge("A1", "A3"), UndirectedEdge("A1", "A4"), UndirectedEdge("A2", "A3"),
    UndirectedEdge("A2", "A4"), UndirectedEdge("A3", "A4"),
    UndirectedEdge("B1", "B2"), UndirectedEdge("B1", "B3"), UndirectedEdge("B2", "B3"), UndirectedEdge("B2", "B4"),
    UndirectedEdge("B3", "B4"), UndirectedEdge("B4", "B5"), UndirectedEdge("B3", "B5"),
    UndirectedEdge("C1", "C2"), UndirectedEdge("C1", "C3"), UndirectedEdge("C2", "C3"), UndirectedEdge("C3", "C4"),
    UndirectedEdge("C2", "C4"),
    UndirectedEdge("A4", "B1"), UndirectedEdge("B5", "C1"), UndirectedEdge("A3", "C4"),
]

let trails = UndirectedAdjacencyList<String> {
    for footway in footways { footway }
}
// snippet end

/// The best partition over the trials, and the code length of each trial's own best.
func trailModules(trials: Int) -> (modules: [[String]], codeLength: Double, oneModule: Double, singletons: Double) {
    // snippet: infomap-run
    var generator = Xoshiro256StarStar(seed: 2)
    let modules = trails.infomapCommunities(trials: trials, using: &generator)
    let bits = trails.codeLength(of: modules)                           // →
    let oneModule = trails.codeLength(of: [Array(trails.vertices)])      // →
    let apart = trails.codeLength(of: trails.vertices.map { [$0] })     // →
    // snippet end
    return (modules.map(Array.init), bits, oneModule, apart)
}

/// The partitions the trials find one at a time, each from its own seed, with their code lengths.
func trailTrials(_ count: Int) -> [(modules: [[String]], codeLength: Double)] {
    (0 ..< count).map { trial in
        var generator = Xoshiro256StarStar(seed: UInt64(11 + trial))
        let modules = trails.infomapCommunities(trials: 1, using: &generator)
        return (modules.map(Array.init), trails.codeLength(of: modules))
    }
}

/// Louvain's partition of the same trails, and its code length, for comparison.
func trailLouvain() -> (modules: [[String]], codeLength: Double, modularity: Double) {
    // snippet: infomap-louvain
    let byModularity = trails.louvainCommunities()
    let bitsByModularity = trails.codeLength(of: byModularity)  // →
    let q = trails.modularity(of: byModularity)                 // →
    // snippet end
    return (byModularity.map(Array.init), bitsByModularity, q)
}
