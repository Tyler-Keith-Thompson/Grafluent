// snippet: astar-imports
import AdjacencyListModule
import GraphProtocols
import ShortestPaths
// snippet end

// The city grid and the two searches the A* page runs. The marked regions are its code panel.

// snippet: astar-block
/// A block of the city, by column and row.
struct Block: Hashable {
    var column: Int
    var row: Int

    /// The straight-line distance to `other`, in blocks.
    func distance(to other: Block) -> Double {
        let dx = Double(column - other.column), dy = Double(row - other.row)
        return (dx * dx + dy * dy).squareRoot()
    }

    /// The blocks one step east, south-east, south and south-west: each street once.
    var nextBlocks: [Block] {
        [(1, 0), (1, 1), (0, 1), (-1, 1)].map { Block(column: column + $0.0, row: row + $0.1) }
    }
}
// snippet end

typealias CitySearchEvent = AStarSearchEvent<Block, DirectedView<UndirectedAdjacencyList<Block>>.Edges.Index, Double>
typealias CityDijkstraEvent = DijkstraSearchEvent<Block, DirectedView<UndirectedAdjacencyList<Block>>.Edges.Index, Double>

/// What the A* page runs on one map: the city, the A* events, Dijkstra's events up to the café,
/// and the length of the route `aStarShortestPath` returns.
struct CityRun {
    var city: UndirectedAdjacencyList<Block>
    var aStar: [CitySearchEvent]
    var dijkstra: [CityDijkstraEvent]
    var route: Double?
}

/// Builds the city with `walls`, then runs A* (its guesses multiplied by `overestimate`) and
/// Dijkstra from `home` to `café`.
func cityRun(from home: Block, to café: Block, walls: Set<Block>, overestimate: Double) -> CityRun {
    // snippet: astar-city
    let isOpen = { (b: Block) in (0 ..< 13).contains(b.column) && (0 ..< 9).contains(b.row) && !walls.contains(b) }
    let city = UndirectedAdjacencyList<Block> {
        for column in 0 ..< 13 {
            for row in 0 ..< 9 {
                let a = Block(column: column, row: row)
                if isOpen(a) {
                    a
                    // A diagonal step needs both blocks beside it open: no cutting corners.
                    for b in a.nextBlocks {
                        if isOpen(b) && isOpen(Block(column: a.column, row: b.row)) && isOpen(Block(column: b.column, row: a.row)) {
                            UndirectedEdge(a, b)
                        }
                    }
                }
            }
        }
    }
    // snippet end

    // snippet: astar-search
    let events = Array(city.aStarSearch(from: home, to: café) { street in
        city.edges[street].u.distance(to: city.edges[street].v)
    } heuristic: { block in
        overestimate * block.distance(to: café)
    })  // →
    // snippet end

    // snippet: astar-dijkstra
    var dijkstra: [DijkstraSearchEvent<Block, DirectedView<UndirectedAdjacencyList<Block>>.Edges.Index, Double>] = []
    for event in city.dijkstraSearch(from: home, weight: { city.edges[$0].u.distance(to: city.edges[$0].v) }) {
        dijkstra.append(event)
        if case .examine(café, _) = event { break }  // Stop once the café is settled.
    }
    // snippet end

    // snippet: astar-route
    let route = city.aStarShortestPath(from: home, to: café) { street in
        city.edges[street].u.distance(to: city.edges[street].v)
    } heuristic: { block in
        overestimate * block.distance(to: café)
    }
    let walked = route?.distance  // →
    // snippet end
    return CityRun(city: city, aStar: events, dijkstra: dijkstra, route: walked)
}
