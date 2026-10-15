// snippet: edgecoloring-imports
import AdjacencyListModule
import ColoringModule
import GraphProtocols
// snippet end

// The league of the edge colouring page and the two schedules it makes. The marked regions are
// its code panel.

let leagueTeams = ["Lions", "Tigers", "Bears", "Wolves", "Hawks", "Owls", "Foxes", "Sharks"]

/// Every team in the first `count` playing every other once: the league, and the round of each
/// match from Misra and Gries's colouring and from the circle method, checked.
func roundRobin(count n: Int) -> (league: UndirectedAdjacencyList<String>, colouring: [Int], circle: [Int], circleIsProper: Bool) {
    // snippet: edgecoloring-league
    let teams = leagueTeams.prefix(n)
    let league = UndirectedAdjacencyList<String> {
        for (i, home) in teams.enumerated() {
            for away in teams.dropFirst(i + 1) { UndirectedEdge(home, away) }
        }
    }
    // snippet end
    // snippet: edgecoloring-vizing
    let rounds = league.edgeColoring()
    let roundCount = rounds.colorCount                      // →
    let firstRound = rounds.colorClasses[0].map { league.edges[$0] }  // →
    // snippet end
    _ = (roundCount, firstRound)
    // snippet: edgecoloring-circle
    // Seat the teams round a table, one seat fixed (an empty seat when the count is odd: a bye),
    // and turn the others one place each round. Facing seats play.
    let seats = n.isMultiple(of: 2) ? n : n + 1
    var round: [UndirectedEdge<String>: Int] = [:]
    for r in 0 ..< seats - 1 {
        let ring = [seats - 1] + (0 ..< seats - 1).map { (r + $0) % (seats - 1) }
        for k in 0 ..< seats / 2 where ring[k] < n && ring[seats - 1 - k] < n {
            round[UndirectedEdge(teams[ring[k]], teams[ring[seats - 1 - k]])] = r
        }
    }
    let proper = league.isEdgeColoring { round[league.edges[$0]]! }   // →
    // snippet end
    return (league, league.edges.indices.map { rounds.color(ofEdgeAt: $0) }, league.edges.indices.map { round[league.edges[$0]]! }, proper)
}
