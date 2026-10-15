// snippet: communities-imports
import AdjacencyListModule
import CommunityDetection
import GraphProtocols
// snippet end

// The school of the communities page and the calls it makes. The marked regions are its code
// panel.

// snippet: communities-school
let friendships = [
    UndirectedEdge("Ada", "Bo"), UndirectedEdge("Ada", "Cal"), UndirectedEdge("Ada", "Dot"),
    UndirectedEdge("Bo", "Cal"), UndirectedEdge("Bo", "Dot"), UndirectedEdge("Cal", "Dot"),
    UndirectedEdge("Eve", "Finn"), UndirectedEdge("Eve", "Gia"), UndirectedEdge("Finn", "Gia"),
    UndirectedEdge("Finn", "Hugo"), UndirectedEdge("Gia", "Hugo"),
    UndirectedEdge("Ivy", "Jay"), UndirectedEdge("Ivy", "Kim"), UndirectedEdge("Jay", "Kim"),
    UndirectedEdge("Jay", "Leo"), UndirectedEdge("Kim", "Leo"), UndirectedEdge("Ivy", "Leo"),
    UndirectedEdge("Dot", "Eve"), UndirectedEdge("Hugo", "Ivy"), UndirectedEdge("Cal", "Kim"),
]

let school = UndirectedAdjacencyList<String> {
    for pair in friendships { pair }
}
// snippet end

typealias SchoolLouvainEvent = LouvainEvent<DirectedView<UndirectedAdjacencyList<String>>>

/// Every event of Louvain on the school, its communities, and their modularity.
func schoolCommunities() -> (events: [SchoolLouvainEvent], clubs: [[String]], score: Double) {
    // snippet: communities-louvain
    let events = Array(school.louvainEvents())     // →
    let clubs = school.louvainCommunities()        // →
    let score = school.modularity(of: clubs)       // →
    // snippet end
    return (events, clubs.map(Array.init), score)
}
