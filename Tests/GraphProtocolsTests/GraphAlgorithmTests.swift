// Algorithms written once against Graph give the same answers on every conformer. Each test
// declares its algorithm as a local generic function. Expected values were computed with NetworkX,
// not with Grafluent. Case IDs (UG-Ann) refer to the catalog in README.md.

import AdjacencyListModule
import GraphProtocols
import GrafluentTestSupport
import Testing
import Traversal

@Suite("Generic algorithms on every undirected conformer")
struct GraphAlgorithmTests {
    @Test("UG-A01 breadth-first distances")
    func breadthFirstDistances() {
        func distances<G: Graph>(_ g: G, from source: G.Vertex) -> [G.Vertex: Int] {
            var distance = [source: 0]
            var queue = [source]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in g.neighbors(of: v) where distance[w] == nil {
                    distance[w] = distance[v]! + 1
                    queue.append(w)
                }
            }
            return distance
        }
        let cases: [(UndirectedFixture<Int>, [Int: Int])] = [
            (.petersen, [0: 0, 1: 1, 4: 1, 5: 1, 2: 2, 3: 2, 6: 2, 7: 2, 8: 2, 9: 2]),
            (.cube, [0: 0, 1: 1, 2: 1, 4: 1, 3: 2, 5: 2, 6: 2, 7: 3]),
            (.house, [0: 0, 1: 1, 2: 1, 3: 2, 4: 2]),
            (.karate, [
                0: 0, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1, 10: 1, 11: 1, 12: 1, 13: 1, 17: 1, 19: 1, 21: 1, 31: 1,
                9: 2, 16: 2, 24: 2, 25: 2, 27: 2, 28: 2, 30: 2, 32: 2, 33: 2,
                14: 3, 15: 3, 18: 3, 20: 3, 22: 3, 23: 3, 26: 3, 29: 3,
            ]),
        ]
        for (fixture, expected) in cases {
            #expect(distances(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges), from: 0) == expected, "\(fixture.name)")
            #expect(distances(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges), from: 0) == expected, "\(fixture.name)")
        }
    }

    @Test("UG-A02 breadth-first layers")
    func breadthFirstLayers() {
        func layers<G: Graph>(_ g: G, from source: G.Vertex) -> [Set<G.Vertex>] {
            var seen: Set = [source]
            var current = [source]
            var result: [Set<G.Vertex>] = []
            while !current.isEmpty {
                result.append(Set(current))
                var next: [G.Vertex] = []
                for v in current {
                    for w in g.neighbors(of: v) where seen.insert(w).inserted { next.append(w) }
                }
                current = next
            }
            return result
        }
        let cases: [(UndirectedFixture<Int>, [Set<Int>])] = [
            (.petersen, [[0], [1, 4, 5], [2, 3, 6, 7, 8, 9]]),
            (.cube, [[0], [1, 2, 4], [3, 5, 6], [7]]),
            (.cycle5, [[0], [1, 4], [2, 3]]),
        ]
        for (fixture, expected) in cases {
            #expect(layers(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges), from: 0) == expected, "\(fixture.name)")
            #expect(layers(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges), from: 0) == expected, "\(fixture.name)")
        }
    }

    @Test("UG-A03 depth-first preorder with neighbors visited in ascending order")
    func depthFirstPreorder() {
        func preorder<G: Graph>(_ g: G, from source: G.Vertex) -> [G.Vertex] where G.Vertex: Comparable {
            var seen = Set<G.Vertex>()
            var order: [G.Vertex] = []
            func visit(_ v: G.Vertex) {
                guard seen.insert(v).inserted else { return }
                order.append(v)
                for w in g.neighbors(of: v).sorted() { visit(w) }
            }
            visit(source)
            return order
        }
        let cases: [(UndirectedFixture<Int>, [Int])] = [
            (.petersen, [0, 1, 2, 3, 4, 9, 6, 8, 5, 7]),
            (.cube, [0, 1, 3, 2, 6, 4, 5, 7]),
            (.house, [0, 1, 3, 2, 4]),
            (.karate, [0, 1, 2, 3, 7, 12, 13, 33, 8, 30, 32, 14, 15, 18, 20, 22, 23, 25, 24, 27, 31, 28, 29, 26, 9, 19, 17, 21, 4, 6, 5, 10, 16, 11]),
        ]
        for (fixture, expected) in cases {
            #expect(preorder(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges), from: 0) == expected, "\(fixture.name)")
            #expect(preorder(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges), from: 0) == expected, "\(fixture.name)")
        }
    }

    @Test("UG-A04 connected components by union–find over edges")
    func connectedComponents() {
        func components<G: Graph>(_ g: G) -> Set<Set<G.Vertex>> {
            var parent: [G.Vertex: G.Vertex] = [:]
            for v in g.vertices { parent[v] = v }
            func root(_ v: G.Vertex) -> G.Vertex {
                var v = v
                while parent[v]! != v { v = parent[v]! }
                return v
            }
            for e in g.edges {
                let (a, b) = (root(e.u), root(e.v))
                if a != b { parent[a] = b }
            }
            var groups: [G.Vertex: Set<G.Vertex>] = [:]
            for v in g.vertices { groups[root(v), default: []].insert(v) }
            return Set(groups.values)
        }
        let seven = UndirectedFixture<Int>.components7
        let expected: Set<Set<Int>> = [[0, 1, 2], [3, 4], [5], [6]]
        #expect(components(UndirectedAdjacencyList(vertices: seven.vertices, edges: seven.edges)) == expected)
        #expect(components(ReferencePseudograph(vertices: seven.vertices, edges: seven.edges)) == expected)
        for fixture in [UndirectedFixture<Int>.petersen, .karate] {
            #expect(components(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)).count == 1, "\(fixture.name)")
            #expect(components(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges)).count == 1, "\(fixture.name)")
        }
    }

    @Test("UG-A05 undirected depth-first search classifies each edge once, by position, as tree or back")
    func undirectedEdgeClasses() {
        // Boost's undirected_dfs: edges are marked by position, so an edge is never seen again
        // from its other end, and there are no forward or cross edges.
        func classes<G: Graph>(_ g: G, from source: G.Vertex) -> (tree: Int, back: Int) {
            var discovered = Set<G.Vertex>()
            var used = Set<G.Edges.Index>()
            var tree = 0
            var back = 0
            func visit(_ v: G.Vertex) {
                discovered.insert(v)
                for e in g.incidentEdges(of: v) where used.insert(e).inserted {
                    let w = g.oppositeVertex(to: v, acrossEdgeAt: e)
                    if discovered.contains(w) {
                        back += 1
                    } else {
                        tree += 1
                        visit(w)
                    }
                }
            }
            visit(source)
            return (tree, back)
        }
        let k4 = UndirectedFixture<Int>.k4
        let loop = UndirectedFixture<Int>.singleSelfLoop
        for result in [classes(UndirectedAdjacencyList(edges: k4.edges), from: 0), classes(ReferencePseudograph(edges: k4.edges), from: 0)] {
            // m − n + c = 6 − 4 + 1 back edges.
            #expect(result.tree == 3)
            #expect(result.back == 3)
        }
        for result in [classes(UndirectedAdjacencyList(edges: loop.edges), from: 0), classes(ReferencePseudograph(edges: loop.edges), from: 0)] {
            #expect(result.tree == 0)
            #expect(result.back == 1)
        }
        let doubled = classes(ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)]), from: 0)
        #expect(doubled.tree == 1)
        #expect(doubled.back == 1)
        // The directed search over the two-arc view classifies arcs, not edges (CLRS §22.3).
        var counts = [0, 0, 0, 0]
        for event in UndirectedAdjacencyList(edges: k4.edges).directed.depthFirstSearch(from: 0) {
            switch event {
            case .treeEdge: counts[0] += 1
            case .backEdge: counts[1] += 1
            case .forwardEdge: counts[2] += 1
            case .crossEdge: counts[3] += 1
            case .discover, .finish: break
            }
        }
        #expect(counts == [3, 6, 3, 0])
    }

    @Test("UG-A06 bridges by edge position, so a doubled edge is never a bridge")
    func bridges() {
        func bridges<G: Graph>(_ g: G) -> Set<UndirectedEdge<G.Vertex>> {
            var order: [G.Vertex: Int] = [:]
            var low: [G.Vertex: Int] = [:]
            var result = Set<UndirectedEdge<G.Vertex>>()
            func visit(_ v: G.Vertex, through parentEdge: G.Edges.Index?) {
                order[v] = order.count
                low[v] = order[v]
                for e in g.incidentEdges(of: v) where e != parentEdge {
                    let w = g.oppositeVertex(to: v, acrossEdgeAt: e)
                    if let seen = order[w] {
                        low[v] = min(low[v]!, seen)
                    } else {
                        visit(w, through: e)
                        low[v] = min(low[v]!, low[w]!)
                        if low[w]! > order[v]! { result.insert(g.edges[e]) }
                    }
                }
            }
            for v in g.vertices where order[v] == nil { visit(v, through: nil) }
            return result
        }
        let cases: [(UndirectedFixture<Int>, Set<UndirectedEdge<Int>>)] = [
            (.path4, [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)]),
            (.karate, [UndirectedEdge(0, 11)]),
            (.petersen, []), (.cube, []), (.house, []), (.k4, []), (.cycle5, []),
        ]
        for (fixture, expected) in cases {
            #expect(bridges(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(bridges(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
        }
        // NetworkX MultiGraph([(0, 1), (1, 2), (1, 2)]): only 0–1.
        let parallel = UndirectedFixture<Int>.parallelPath
        #expect(bridges(ReferencePseudograph(edges: parallel.edges)) == [UndirectedEdge(0, 1)])
        // Collapsed to a simple path, both edges are bridges.
        #expect(bridges(UndirectedAdjacencyList(edges: parallel.edges)) == [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
    }

    @Test("UG-A07 an Euler circuit exists when the graph is connected and every degree is even", .tags(.selfLoops))
    func eulerCircuitCondition() {
        func isEulerian<G: Graph>(_ g: G) -> Bool {
            guard let start = g.vertices.first else { return false }
            guard g.vertices.allSatisfy({ g.degree(of: $0).isMultiple(of: 2) }) else { return false }
            var seen: Set = [start]
            var stack = [start]
            while let v = stack.popLast() {
                for w in g.neighbors(of: v) where seen.insert(w).inserted { stack.append(w) }
            }
            return seen.count == g.vertexCount
        }
        let cases: [(UndirectedFixture<Int>, Bool)] = [(.singleSelfLoop, true), (.k3WithLoop, true), (.cycle5, true), (.k4, false)]
        for (fixture, expected) in cases {
            #expect(isEulerian(UndirectedAdjacencyList(edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(isEulerian(ReferencePseudograph(edges: fixture.edges)) == expected, "\(fixture.name)")
        }
        // NetworkX MultiGraph([(0, 1), (1, 2), (2, 0), (0, 1)]): degrees 3, 3, 2.
        let doubled = ReferencePseudograph(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(0, 1)])
        #expect(!isEulerian(doubled))
        #expect(isEulerian(UndirectedAdjacencyList(doubled)))
    }

    @Test("UG-A08 two-coloring by breadth-first search", .tags(.selfLoops))
    func bipartite() {
        func isBipartite<G: Graph>(_ g: G) -> Bool {
            var color: [G.Vertex: Bool] = [:]
            for s in g.vertices where color[s] == nil {
                color[s] = false
                var queue = [s]
                var head = 0
                while head < queue.count {
                    let v = queue[head]
                    head += 1
                    for w in g.neighbors(of: v) {
                        if let c = color[w] {
                            if c == color[v]! { return false }
                        } else {
                            color[w] = !color[v]!
                            queue.append(w)
                        }
                    }
                }
            }
            return true
        }
        let cases: [(UndirectedFixture<Int>, Bool)] = [
            (.cube, true), (.path4, true),
            (.petersen, false), (.cycle5, false), (.k4, false), (.house, false), (.singleSelfLoop, false),
        ]
        for (fixture, expected) in cases {
            #expect(isBipartite(UndirectedAdjacencyList(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
            #expect(isBipartite(ReferencePseudograph(vertices: fixture.vertices, edges: fixture.edges)) == expected, "\(fixture.name)")
        }
    }

    @Test("UG-A09 the same distances and components through existentials")
    func throughExistentials() {
        func distances(_ g: any Graph<Int>, from source: Int) -> [Int: Int] {
            var distance = [source: 0]
            var queue = [source]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in g.neighbors(of: v) where distance[w] == nil {
                    distance[w] = distance[v]! + 1
                    queue.append(w)
                }
            }
            return distance
        }
        func componentCount(_ g: any Graph<Int>) -> Int {
            var parent: [Int: Int] = [:]
            for v in g.vertices { parent[v] = v }
            func root(_ v: Int) -> Int {
                var v = v
                while parent[v]! != v { v = parent[v]! }
                return v
            }
            for e in g.edges {
                let (a, b) = (root(e.u), root(e.v))
                if a != b { parent[a] = b }
            }
            return Set(g.vertices.map(root)).count
        }
        let petersen = UndirectedFixture<Int>.petersen
        let seven = UndirectedFixture<Int>.components7
        let petersens: [any Graph<Int>] = [
            UndirectedAdjacencyList(edges: petersen.edges),
            ReferencePseudograph(edges: petersen.edges),
            AdjacencyList(UndirectedAdjacencyList(edges: petersen.edges).directed).undirected,
        ]
        for g in petersens {
            #expect(distances(g, from: 0) == [0: 0, 1: 1, 4: 1, 5: 1, 2: 2, 3: 2, 6: 2, 7: 2, 8: 2, 9: 2])
            #expect(componentCount(g) == 1)
        }
        let sevens: [any Graph<Int>] = [
            UndirectedAdjacencyList(vertices: seven.vertices, edges: seven.edges),
            ReferencePseudograph(vertices: seven.vertices, edges: seven.edges),
            AdjacencyList(UndirectedAdjacencyList(vertices: seven.vertices, edges: seven.edges).directed).undirected,
        ]
        for g in sevens {
            #expect(componentCount(g) == 4)
            #expect(distances(g, from: 3) == [3: 0, 4: 1])
        }
    }
}
