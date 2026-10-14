// `feasibleCirculation(supply:lowerBound:capacity:)`, `feasibleCirculation(lowerBound:capacity:)`
// and `findCirculationBarrier` (catalog §Circulation): whether a flow exists exactly; a returned
// flow checked here for its bounds and the supplies (any one); the barrier exactly, and checked here
// to violate Gale's condition; the closures' calls in order. Directed rows are `AdjacencyList`, or
// `DirectedPseudograph` when an edge repeats; undirected rows `UndirectedAdjacencyList`, or
// `Pseudograph` with parallel edges; each built by inserting the row's vertices, then its edges in
// order, so positions are the catalog's. In-test checks number vertices by their index in
// `vertices`. Generated from cases.md by swiftgen.py, which re-evaluates each row with ref.py's
// models; see README.md.

import AdjacencyListModule
import Flows
import GraphProtocols
import Multigraphs
import Testing

@Suite("Feasible flows with lower bounds")
struct CirculationTests {
    @Test("FL-570 no vertices: feasible")
    func fl570() throws {
        // V []; E []; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = []
        let lowerBounds: [Int] = []
        let capacities: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == [Int](repeating: 0, count: n))
        #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-571 no edges: feasible")
    func fl571() throws {
        // V [0, 1]; E []; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = []
        let lowerBounds: [Int] = []
        let capacities: [Int] = []
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == [Int](repeating: 0, count: n))
        #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-572 cycle within its bounds: 2 on every edge: feasible")
    func fl572() throws {
        // V [0, 1, 2]; E [0→1 1..3, 1→2 2..4, 2→0 0..5]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let lowerBounds: [Int] = [1, 2, 0]
        let capacities: [Int] = [3, 4, 5]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == [Int](repeating: 0, count: n))
        #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-573 cycle, one lower bound past another's capacity: barrier [1]")
    func fl573() throws {
        // V [0, 1, 2]; E [0→1 4..6, 1→2 0..3, 2→0 0..9]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let lowerBounds: [Int] = [4, 0, 0]
        let capacities: [Int] = [6, 3, 9]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        #expect(result == nil)
        let barrier = try #require(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
        #expect(barrier == [1] as [Int])
        // Gale's condition fails for it: its supply exceeds the capacity out of it less the lower bounds
        // into it.
        let inBarrier = vertexList.map { barrier.contains($0) }
        var out: Int = 0, into: Int = 0
        for k in pairs.indices {
            if inBarrier[ends[k].0] && !inBarrier[ends[k].1] { out += capacities[k] }
            if !inBarrier[ends[k].0] && inBarrier[ends[k].1] { into += lowerBounds[k] }
        }
        // Every supply is zero.
        #expect(0 > out - into)
    }

    @Test("FL-574 a lower bound on an edge no cycle carries: barrier [1]")
    func fl574() throws {
        // V [0, 1]; E [0→1 1..2]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1)]
        let lowerBounds: [Int] = [1]
        let capacities: [Int] = [2]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        #expect(result == nil)
        let barrier = try #require(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
        #expect(barrier == [1] as [Int])
        // Gale's condition fails for it: its supply exceeds the capacity out of it less the lower bounds
        // into it.
        let inBarrier = vertexList.map { barrier.contains($0) }
        var out: Int = 0, into: Int = 0
        for k in pairs.indices {
            if inBarrier[ends[k].0] && !inBarrier[ends[k].1] { out += capacities[k] }
            if !inBarrier[ends[k].0] && inBarrier[ends[k].1] { into += lowerBounds[k] }
        }
        // Every supply is zero.
        #expect(0 > out - into)
    }

    @Test("FL-575 zero lower bounds: the zero flow: feasible")
    func fl575() throws {
        // V [0, 1, 2]; E [0→1 0..3, 1→2 0..3]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let lowerBounds: [Int] = [0, 0]
        let capacities: [Int] = [3, 3]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == [Int](repeating: 0, count: n))
        #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-576 self-loop carries its lower bound: feasible")
    func fl576() throws {
        // V [0, 1]; E [0→0 2..5, 0→1 0..1, 1→0 0..1]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 0)]
        let lowerBounds: [Int] = [2, 0, 0]
        let capacities: [Int] = [5, 1, 1]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == [Int](repeating: 0, count: n))
        #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-577 parallel edges share the demand: feasible")
    func fl577() throws {
        // V [0, 1]; E [0→1 1..1, 0→1 0..2, 1→0 3..3]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let lowerBounds: [Int] = [1, 0, 3]
        let capacities: [Int] = [1, 2, 3]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == [Int](repeating: 0, count: n))
        #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-578 two cycles through a bottleneck: barrier [b, c, d]")
    func fl578() throws {
        // V [a, b, c, d]; E [a→b 2..4, b→a 0..1, b→c 0..1, c→d 1..3, d→c 1..3, c→b 0..5]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(String, String)] = [("a", "b"), ("b", "a"), ("b", "c"), ("c", "d"), ("d", "c"), ("c", "b")]
        let lowerBounds: [Int] = [2, 0, 0, 1, 1, 0]
        let capacities: [Int] = [4, 1, 1, 3, 3, 5]
        let graph = AdjacencyList<String>(vertices: ["a", "b", "c", "d"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["a", "b", "c", "d"] as [String])
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        #expect(result == nil)
        let barrier = try #require(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
        #expect(barrier == ["b", "c", "d"] as [String])
        // Gale's condition fails for it: its supply exceeds the capacity out of it less the lower bounds
        // into it.
        let inBarrier = vertexList.map { barrier.contains($0) }
        var out: Int = 0, into: Int = 0
        for k in pairs.indices {
            if inBarrier[ends[k].0] && !inBarrier[ends[k].1] { out += capacities[k] }
            if !inBarrier[ends[k].0] && inBarrier[ends[k].1] { into += lowerBounds[k] }
        }
        // Every supply is zero.
        #expect(0 > out - into)
    }

    @Test("FL-579 supplies: a feasible transport: feasible")
    func fl579() throws {
        // V [s, a, b, t]; E [s→a 1..3, s→b 0..2, a→t 0..3, b→t 1..2, a→b 0..1]; supply [s: 4, t: -4]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("s", "b"), ("a", "t"), ("b", "t"), ("a", "b")]
        let lowerBounds: [Int] = [1, 0, 0, 1, 0]
        let capacities: [Int] = [3, 2, 3, 2, 1]
        let supplies: [Int] = [4, 0, 0, -4]
        let graph = AdjacencyList<String>(vertices: ["s", "a", "b", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "a", "b", "t"] as [String])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(supply: { vertex in
            asked.append("supply \(vertex)")
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // The supplies in vertex order, then each edge's lower bound and capacity in position order.
        #expect(asked == vertexList.map { "supply \($0)" } + pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == supplies)
        #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-580 supplies: the source cannot send its supply: barrier {s}: barrier [s]")
    func fl580() throws {
        // V [s, a, t]; E [s→a 0..2, a→t 0..5]; supply [s: 3, t: -3]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("a", "t")]
        let lowerBounds: [Int] = [0, 0]
        let capacities: [Int] = [2, 5]
        let supplies: [Int] = [3, 0, -3]
        let graph = AdjacencyList<String>(vertices: ["s", "a", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "a", "t"] as [String])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(supply: { vertex in
            asked.append("supply \(vertex)")
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // The supplies in vertex order, then each edge's lower bound and capacity in position order.
        #expect(asked == vertexList.map { "supply \($0)" } + pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        #expect(result == nil)
        let barrier = try #require(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
        #expect(barrier == ["s"] as [String])
        // Gale's condition fails for it: its supply exceeds the capacity out of it less the lower bounds
        // into it.
        let inBarrier = vertexList.map { barrier.contains($0) }
        var out: Int = 0, into: Int = 0, supplied: Int = 0
        for k in pairs.indices {
            if inBarrier[ends[k].0] && !inBarrier[ends[k].1] { out += capacities[k] }
            if !inBarrier[ends[k].0] && inBarrier[ends[k].1] { into += lowerBounds[k] }
        }
        for v in 0 ..< n where inBarrier[v] { supplied += supplies[v] }
        #expect(supplied > out - into)
    }

    @Test("FL-581 supplies: a lower bound above the supply, returned on a back edge: feasible")
    func fl581() throws {
        // V [s, a, t]; E [s→a 0..4, a→t 3..4, t→a 0..1]; supply [s: 2, t: -2]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(String, String)] = [("s", "a"), ("a", "t"), ("t", "a")]
        let lowerBounds: [Int] = [0, 3, 0]
        let capacities: [Int] = [4, 4, 1]
        let supplies: [Int] = [2, 0, -2]
        let graph = AdjacencyList<String>(vertices: ["s", "a", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "a", "t"] as [String])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(supply: { vertex in
            asked.append("supply \(vertex)")
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // The supplies in vertex order, then each edge's lower bound and capacity in position order.
        #expect(asked == vertexList.map { "supply \($0)" } + pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == supplies)
        #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-582 supplies with zero lower bounds: a transportation problem: feasible")
    func fl582() throws {
        // V [0, 1, 2, 3, 4]; E [0→2 0..2, 0→3 0..2, 1→3 0..1, 1→4 0..3, 2→4 0..1]; supply [0: 3, 1: 2, 2: -1, 3: -2, 4: -2]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (1, 3), (1, 4), (2, 4)]
        let lowerBounds: [Int] = [0, 0, 0, 0, 0]
        let capacities: [Int] = [2, 2, 1, 3, 1]
        let supplies: [Int] = [3, 2, -1, -2, -2]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(supply: { vertex in
            asked.append("supply \(vertex)")
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // The supplies in vertex order, then each edge's lower bound and capacity in position order.
        #expect(asked == vertexList.map { "supply \($0)" } + pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == supplies)
        #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-583 negative lower bound: flow against the edge: feasible")
    func fl583() throws {
        // V [0, 1]; E [0→1 -3..-1, 0→1 0..2]; supply [0: -1, 1: 1]; feasibleCirculation(supply:lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1)]
        let lowerBounds: [Int] = [-3, 0]
        let capacities: [Int] = [-1, 2]
        let supplies: [Int] = [-1, 1]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(supply: { vertex in
            asked.append("supply \(vertex)")
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // The supplies in vertex order, then each edge's lower bound and capacity in position order.
        #expect(asked == vertexList.map { "supply \($0)" } + pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == supplies)
        #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-584 Double bounds: feasible")
    func fl584() throws {
        // Double V [0, 1, 2]; E [0→1 0.5..1.5, 1→2 0.25..1.0, 2→0 0.75..2.0]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let lowerBounds: [Double] = [0.5, 0.25, 0.75]
        let capacities: [Double] = [1.5, 1.0, 2.0]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Double](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == [Double](repeating: 0, count: n))
        #expect(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }

    @Test("FL-585 Double, infeasible: barrier [1]")
    func fl585() throws {
        // Double V [0, 1, 2]; E [0→1 1.25..1.5, 1→2 0.25..1.0, 2→0 0.0..2.0]; feasibleCirculation(lowerBound:capacity:)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
        let lowerBounds: [Double] = [1.25, 0.25, 0.0]
        let capacities: [Double] = [1.5, 1.0, 2.0]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        #expect(result == nil)
        let barrier = try #require(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
        #expect(barrier == [1] as [Int])
        // Gale's condition fails for it: its supply exceeds the capacity out of it less the lower bounds
        // into it.
        let inBarrier = vertexList.map { barrier.contains($0) }
        var out: Double = 0, into: Double = 0
        for k in pairs.indices {
            if inBarrier[ends[k].0] && !inBarrier[ends[k].1] { out += capacities[k] }
            if !inBarrier[ends[k].0] && inBarrier[ends[k].1] { into += lowerBounds[k] }
        }
        // Every supply is zero.
        #expect(0 > out - into)
    }

    @Test("FL-586 lcg(8 vertices, 20 edges, seed 77): barrier [1, 2, 4, 5, 6]")
    func fl586() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7]; E [7→5 2..4, 3→6 2..3, 1→4 1..2, 3→3 0..1, 7→2 2..3, 3→7 0..1, 2→1 0..3, 2→1 1..3, 1→4 0..2, 0→2 1..4, 7→6 0..0, 1→2 2..4, 2→3 1..1, 5→2 1..4, 2→6 0..2, 6→1 1..1, 0→4 2.…
        let pairs: [(Int, Int)] = [(7, 5), (3, 6), (1, 4), (3, 3), (7, 2), (3, 7), (2, 1), (2, 1), (1, 4), (0, 2), (7, 6), (1, 2), (2, 3), (5, 2), (2, 6), (6, 1), (0, 4), (0, 7), (3, 0), (3, 6)]
        let lowerBounds: [Int] = [2, 2, 1, 0, 2, 0, 0, 1, 0, 1, 0, 2, 1, 1, 0, 1, 2, 2, 1, 2]
        let capacities: [Int] = [4, 3, 2, 1, 3, 1, 3, 3, 2, 4, 0, 4, 1, 4, 2, 1, 4, 3, 1, 4]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // Each edge's lower bound and then its capacity, in position order.
        #expect(asked == pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        #expect(result == nil)
        let barrier = try #require(graph.findCirculationBarrier(lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }))
        #expect(barrier == [1, 2, 4, 5, 6] as [Int])
        // Gale's condition fails for it: its supply exceeds the capacity out of it less the lower bounds
        // into it.
        let inBarrier = vertexList.map { barrier.contains($0) }
        var out: Int = 0, into: Int = 0
        for k in pairs.indices {
            if inBarrier[ends[k].0] && !inBarrier[ends[k].1] { out += capacities[k] }
            if !inBarrier[ends[k].0] && inBarrier[ends[k].1] { into += lowerBounds[k] }
        }
        // Every supply is zero.
        #expect(0 > out - into)
    }

    @Test("FL-587 lcg(9 vertices, 24 edges, seed 5), with supplies: feasible")
    func fl587() throws {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [7→8 0..1, 4→5 1..6, 5→6 1..6, 6→2 1..4, 2→3 0..1, 4→1 0..3, 0→5 1..6, 5→4 0..5, 8→3 1..5, 6→6 0..2, 8→0 0..5, 7→6 0..2, 2→1 0..1, 8→3 0..1, 4→7 1..4, 0→8 0..2, 1→7…
        let pairs: [(Int, Int)] = [(7, 8), (4, 5), (5, 6), (6, 2), (2, 3), (4, 1), (0, 5), (5, 4), (8, 3), (6, 6), (8, 0), (7, 6), (2, 1), (8, 3), (4, 7), (0, 8), (1, 7), (3, 8), (7, 2), (3, 5), (4, 4), (1, 5), (1, 0), (0, 4)]
        let lowerBounds: [Int] = [0, 1, 1, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0]
        let capacities: [Int] = [1, 6, 6, 4, 1, 3, 6, 5, 5, 2, 5, 2, 1, 1, 4, 2, 1, 4, 4, 1, 3, 4, 2, 2]
        let supplies: [Int] = [4, 0, 0, -2, 0, 0, 0, 0, -2]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        let n = vertexList.count
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        var asked: [String] = []
        let result = graph.feasibleCirculation(supply: { vertex in
            asked.append("supply \(vertex)")
            return supplies[vertexList.firstIndex(of: vertex)!]
        }, lowerBound: { position in
            asked.append("lower \(position)")
            return lowerBounds[position]
        }, capacity: { position in
            asked.append("capacity \(position)")
            return capacities[position]
        })
        // The supplies in vertex order, then each edge's lower bound and capacity in position order.
        #expect(asked == vertexList.map { "supply \($0)" } + pairs.indices.flatMap { ["lower \($0)", "capacity \($0)"] })
        let circulation = try #require(result)
        let flows = pairs.indices.map { circulation.flow(ofEdgeAt: $0) }
        #expect(pairs.indices.map { try? circulation.flow(checkedEdgeAt: $0) } == flows.map(Optional.some))
        #expect(Array(circulation.flowMap) == flows)
        // Within the bounds, a self-loop at its lower bound, and out − in = supply at every vertex.
        var balance = [Int](repeating: 0, count: n)
        for k in pairs.indices {
            #expect(lowerBounds[k] <= flows[k] && flows[k] <= capacities[k], "edge \(k)")
            if ends[k].0 == ends[k].1 { #expect(flows[k] == lowerBounds[k], "self-loop \(k)") }
            balance[ends[k].0] += flows[k]
            balance[ends[k].1] -= flows[k]
        }
        #expect(balance == supplies)
        #expect(graph.findCirculationBarrier(supply: { supplies[vertexList.firstIndex(of: $0)!] }, lowerBound: { lowerBounds[$0] }, capacity: { capacities[$0] }) == nil)
    }
}
