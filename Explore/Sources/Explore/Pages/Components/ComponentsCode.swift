// snippet: components-imports
import AdjacencyListModule
import Connectivity
import GraphProtocols
import Traversal
// snippet end

import CompressedSparseRowModule

/// The islands' groups, and the breadth-first searches that find them: one from each island no
/// earlier search reached.
func islandGroups(islands names: [String], bridges: [(String, String)]) -> (groups: [[String]], searches: [[BreadthFirstSearchEvent<String>]]) {
    // snippet: components-islands
    let islands = UndirectedAdjacencyList<String> {
        for island in names { island }
        for (a, b) in bridges { UndirectedEdge(a, b) }
    }
    let groups = islands.connectedComponents()  // →

    // The same groups, one search at a time: each search reaches exactly one group.
    var reached = Set<String>()
    var searches: [[BreadthFirstSearchEvent<String>]] = []
    for island in names where !reached.contains(island) {
        let search = Array(islands.directedView.lazy.breadthFirstSearch(from: island))
        for case .discover(let found) in search { reached.insert(found) }
        searches.append(search)
    }
    // snippet end
    return (groups.map(Array.init), searches)
}

/// The neighbourhoods of the one-way streets, and the condensation's edges between them.
func neighbourhoods(corners: [String], oneWay: [(String, String)]) -> (groups: [[String]], links: CompressedSparseRow, events: [DepthFirstSearchEvent<String>]) {
    // snippet: components-streets
    let streets = AdjacencyList<String> {
        for corner in corners { corner }
        for (from, to) in oneWay { DirectedEdge(from: from, to: to) }
    }
    let neighbourhoods = streets.stronglyConnectedComponents()  // →
    let condensation = streets.condensation()
    let links = condensation.graph.edgeCount                     // →
    let events = Array(streets.lazy.depthFirstSearch())               // →
    // snippet end
    _ = links
    return (neighbourhoods.map(Array.init), condensation.graph, events)
}
