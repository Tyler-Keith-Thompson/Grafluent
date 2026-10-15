// snippet: traversal-imports
import AdjacencyListModule
import GraphProtocols
import Traversal
// snippet end

// snippet: traversal-news
let tells = [
    DirectedEdge(from: "Ana", to: "Ben"),
    DirectedEdge(from: "Ana", to: "Cy"),
    DirectedEdge(from: "Ana", to: "Dee"),
    DirectedEdge(from: "Ben", to: "Eli"),
    DirectedEdge(from: "Cy", to: "Eli"),
    DirectedEdge(from: "Cy", to: "Fay"),
    DirectedEdge(from: "Dee", to: "Fay"),
    DirectedEdge(from: "Eli", to: "Gus"),
    DirectedEdge(from: "Fay", to: "Gus"),
    DirectedEdge(from: "Fay", to: "Hal"),
    DirectedEdge(from: "Gus", to: "Ivy"),
    DirectedEdge(from: "Hal", to: "Ivy"),
    DirectedEdge(from: "Ivy", to: "Ana"),
]

let friends = AdjacencyList<String> {
    for edge in tells { edge }
}
// snippet end

// snippet: traversal-office
let doors = [
    DirectedEdge(from: "Reception", to: "Kitchen"),
    DirectedEdge(from: "Reception", to: "Meeting room"),
    DirectedEdge(from: "Kitchen", to: "Archive"),
    DirectedEdge(from: "Kitchen", to: "Server room"),
    DirectedEdge(from: "Archive", to: "Reception"),
    DirectedEdge(from: "Archive", to: "Server room"),
    DirectedEdge(from: "Meeting room", to: "Archive"),
    DirectedEdge(from: "Meeting room", to: "Lounge"),
    DirectedEdge(from: "Lounge", to: "Print room"),
    DirectedEdge(from: "Print room", to: "Server room"),
]

let office = AdjacencyList<String> {
    for door in doors { door }
}
// snippet end

/// Every event of a breadth-first search of the friends from `start`.
func newsBreadthFirst(from start: String) -> [BreadthFirstSearchEvent<String>] {
    // snippet: traversal-bfs
    let events = Array(friends.lazy.breadthFirstSearch(from: start))  // →
    // snippet end
    return events
}

/// Every event of a depth-first search of the office from `start`.
func officeDepthFirst(from start: String) -> [DepthFirstSearchEvent<String>] {
    // snippet: traversal-dfs
    let events = Array(office.lazy.depthFirstSearch(from: start))  // →
    // snippet end
    return events
}
