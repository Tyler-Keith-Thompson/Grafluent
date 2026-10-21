// The code examples in README.md and the Grafluent DocC landing page, verbatim, each followed by
// assertions of the results its comments state. Change an example here and in the README together.

import Foundation
import Grafluent
import Testing

@Suite("README examples")
struct ReadmeExamplesTests {
    @Test("Build a graph and sort it topologically")
    func buildAndSort() {
        let steps = ["fetch", "compile", "test", "package"]
        var build = AdjacencyList<String> {
            for (step, next) in zip(steps, steps.dropFirst()) {
                DirectedEdge(from: step, to: next)
            }
            DirectedEdge(from: "compile", to: "package")
        }
        build.insert(edge: DirectedEdge(from: "package", to: "publish"))

        let next = Array(build.successors(of: "compile"))  // ["test", "package"]
        let order = build.topologicalSort()                // ["fetch", "compile", "test", "package", "publish"]

        #expect(next == ["test", "package"])
        #expect(order == ["fetch", "compile", "test", "package", "publish"])
    }

    @Test("Connected components")
    func components() {
        let friends = UndirectedAdjacencyList<String> {
            UndirectedEdge("ana", "ben")
            UndirectedEdge("ben", "cy")
            UndirectedEdge("dee", "eli")
            "fay"  // a vertex with no edges
        }
        let groups = friends.connectedComponents()

        let groupCount = groups.count                                             // 3
        let together = groups.component(of: "ana") == groups.component(of: "cy")  // true

        #expect(groupCount == 3)
        #expect(together)
        #expect(groups.component(of: "ana") != groups.component(of: "dee"))
    }

    @Test("Edge weights in an attached map, fed to Dijkstra")
    func weightedShortestPaths() {
        var roads = DirectedPseudograph<String>()
        let miles = roads.addEdgeMap(default: 0)
        for (from, to, length) in [("A", "B", 4), ("B", "C", 3), ("A", "C", 9)] {
            let edge = roads.insert(edge: DirectedEdge(from: from, to: to))
            roads[miles, ofEdgeAt: edge] = length
        }

        let lengths = roads.values(of: miles)
        let routes = roads.dijkstraShortestPaths(from: "A", weight: { lengths[$0] })
        let distance = routes.distance(to: "C")           // 7
        let stops = routes.path(to: "C").map(Array.init)  // ["A", "B", "C"]

        #expect(distance == 7)
        #expect(stops == ["A", "B", "C"])
    }

    @Test("A graph and its maps as one Codable value")
    func propertyGraphBundle() throws {
        var roads = DirectedPseudograph<String>()
        let miles = roads.addEdgeMap(default: 0)
        for (from, to, length) in [("A", "B", 4), ("B", "C", 3), ("A", "C", 9)] {
            let edge = roads.insert(edge: DirectedEdge(from: from, to: to))
            roads[miles, ofEdgeAt: edge] = length
        }

        let network = PropertyGraphBundle(roads, maps: miles)
        let data = try JSONEncoder().encode(network)
        var decoded = try JSONDecoder().decode(PropertyGraphBundle<DirectedPseudograph<String>, EdgeMap<Int>>.self, from: data)
        let same = decoded == network                                           // true
        let edge = decoded.graph.insert(edge: DirectedEdge(from: "C", to: "D"))
        decoded.graph[decoded.maps, ofEdgeAt: edge] = 2                         // maps stay in step

        #expect(same)
        #expect(decoded.graph[decoded.maps, ofEdgeAt: edge] == 2)
        let ab = decoded.graph.edges(from: "A", to: "B").first!
        #expect(decoded.graph[decoded.maps, ofEdgeAt: ab] == 4)
    }

    @Test("Typed errors and checked lookups")
    func typedErrors() throws {
        var plan = DirectedAcyclicGraph<AdjacencyList<String>>()
        try plan.insert(edge: DirectedEdge(from: "design", to: "build"))
        try plan.insert(edge: DirectedEdge(from: "build", to: "ship"))

        do {
            try plan.insert(edge: DirectedEdge(from: "ship", to: "design"))
        } catch .cycle {
            // Rejected. The graph is unchanged.
        } catch {
            // .selfLoop or .missingEndpoint
        }

        let edgeCount = plan.edgeCount                         // 2
        let missing = try? plan.successors(checked: "launch")  // nil: "launch" is not a vertex

        #expect(edgeCount == 2)
        #expect(missing == nil)
        #expect(throws: AcyclicEdgeError.cycle) {
            try plan.insert(edge: DirectedEdge(from: "ship", to: "design"))
        }
        #expect(throws: VertexNotFound.self) {
            try plan.successors(checked: "launch")
        }
    }

    @Test("Generators and distances")
    func generators() {
        let grid = UndirectedAdjacencyList<Int>.grid(dimensions: [3, 4])
        let vertexCount = grid.vertexCount  // 12
        let diameter = grid.diameter()      // 5

        #expect(vertexCount == 12)
        #expect(diameter == 5)
    }
}
