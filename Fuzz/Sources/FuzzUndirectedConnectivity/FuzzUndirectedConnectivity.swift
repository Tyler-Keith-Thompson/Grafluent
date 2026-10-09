// Undirected connectivity against brute force, on multigraphs of at most 8 vertices with
// self-loops and parallel edges: a bridge is an edge whose removal adds a component, an
// articulation point a vertex whose removal does; two edges meeting at v are in the same block
// exactly when their far ends stay connected without v (closed under transitivity); the
// bi-edge-connected components are the components without the bridges. Checked on a simple graph
// (UndirectedAdjacencyList), a multigraph (the undirected view of a directed AdjacencyList, whose
// opposite arcs are parallel edges), and the multigraph as written through a conformer without
// vertex indices. Orders are checked exactly: they are canonical.

import AdjacencyListModule
import Connectivity
import FuzzSupport
import GraphProtocols

/// An undirected multigraph with no vertex indices.
struct PlainGraph: Graph {
    let vertices: [Int]
    let edges: [UndirectedEdge<Int>]
    func incidentEdges(of vertex: Int) -> [Int] {
        edges.indices.flatMap { k -> [Int] in
            let e = edges[k]
            return e.u == vertex && e.v == vertex ? [k, k] : e.u == vertex || e.v == vertex ? [k] : []
        }
    }
    func neighbors(of vertex: Int) -> [Int] { incidentEdges(of: vertex).map { edges[$0].oppositeVertex(to: vertex) } }
    func contains(_ vertex: Int) -> Bool { vertices.contains(vertex) }
}

@main
enum FuzzUndirectedConnectivity {
    static func main() { runFuzzer(fuzz) }

    /// Component labels of vertices 0..<n (labels by first vertex) using the edges not excluded,
    /// with `removed` deleted (it gets label −1).
    static func components(_ n: Int, _ edges: [(Int, Int)], skipEdge: Int = -1, removed: Int = -1) -> [Int] {
        var label = [Int](repeating: -1, count: n)
        var next = 0
        for s in 0 ..< n where s != removed && label[s] < 0 {
            label[s] = next
            var stack = [s]
            while let x = stack.popLast() {
                for (k, e) in edges.enumerated() where k != skipEdge && e.0 != removed && e.1 != removed {
                    for (a, b) in [(e.0, e.1), (e.1, e.0)] where a == x && label[b] < 0 {
                        label[b] = next
                        stack.append(b)
                    }
                }
            }
            next += 1
        }
        return label
    }

    static func count(_ labels: [Int]) -> Int { Set(labels.filter { $0 >= 0 }).count }

    static func fuzz(_ input: inout FuzzInput) {
        let n = input.int(in: 1 ... 8)
        var raw: [(Int, Int)] = []
        while !input.isEmpty && raw.count < 20 {
            raw.append((input.int(below: n), input.int(below: n)))
        }

        func checkAll<G: Graph<Int>>(_ graph: G, _ edges: [(Int, Int)], _ rankOf: (G.Edges.Index) -> Int, _ name: String) {
            let base = components(n, edges)
            let componentCount = count(base)

            // Brute force.
            let bridges = edges.indices.filter { k in edges[k].0 != edges[k].1 && count(components(n, edges, skipEdge: k)) > componentCount }
            let points = (0 ..< n).filter { v in count(components(n, edges, removed: v)) > componentCount - (edges.contains { $0.0 == v || $0.1 == v } ? 0 : 1) }
            var blockOf = Array(edges.indices)
            func find(_ x: Int) -> Int { var x = x; while blockOf[x] != x { x = blockOf[x] }; return x }
            for v in 0 ..< n {
                let ends = edges.indices.filter { (edges[$0].0 == v || edges[$0].1 == v) && edges[$0].0 != edges[$0].1 }
                let without = components(n, edges, removed: v)
                for i in ends { for j in ends where i < j {
                    let a = edges[i].0 == v ? edges[i].1 : edges[i].0
                    let b = edges[j].0 == v ? edges[j].1 : edges[j].0
                    if without[a] == without[b] { blockOf[find(i)] = find(j) }
                } }
            }
            var blockFirst: [Int: [Int]] = [:]
            for k in edges.indices where edges[k].0 != edges[k].1 { blockFirst[find(k), default: []].append(k) }
            let blocks = blockFirst.values.map { $0.sorted() }.sorted { $0[0] < $1[0] }
            let noBridges = edges.indices.filter { !bridges.contains($0) }.map { edges[$0] }
            let biEdgeLabels = components(n, noBridges)
            let grouped: ([Int]) -> [[Int]] = { labels in
                Dictionary(grouping: 0 ..< n) { labels[$0] }.values.map { $0.sorted() }.sorted { $0[0] < $1[0] }
            }

            // The library.
            let mine = graph.connectedComponents().map(Array.init)
            check(mine == grouped(base), "\(name) connectedComponents \(mine)")
            check(graph.isConnected == (componentCount == 1), "\(name) isConnected")
            let myBridges = graph.bridges().map(rankOf)
            check(myBridges == bridges, "\(name) bridges \(myBridges), brute force \(bridges)")
            check(graph.hasBridges == !bridges.isEmpty, "\(name) hasBridges")
            check(graph.articulationPoints() == points, "\(name) articulationPoints \(graph.articulationPoints()), brute force \(points)")
            let found = graph.biconnectedComponents()
            let myBlocks = found.map { $0.map(rankOf) }
            check(myBlocks == blocks, "\(name) blocks \(myBlocks), brute force \(blocks)")
            for (b, block) in blocks.enumerated() {
                let vs = Set(block.flatMap { [edges[$0].0, edges[$0].1] }).sorted()
                check(Array(found.vertices(ofComponentAt: b)) == vs, "\(name) vertices of block \(b)")
            }
            for position in graph.edges.indices {
                let k = rankOf(position)
                let expected = edges[k].0 == edges[k].1 ? nil : blocks.firstIndex { $0.contains(k) }
                check(found.component(ofEdgeAt: position) == expected, "\(name) component(ofEdgeAt:) of edge \(k)")
            }
            for v in 0 ..< n {
                let expected = blocks.indices.filter { b in blocks[b].contains { edges[$0].0 == v || edges[$0].1 == v } }
                check(Array(found.components(containing: v)) == expected, "\(name) components(containing: \(v))")
            }
            let biconnected = n >= 2 && componentCount == 1 && points.isEmpty
            check(graph.isBiconnected == biconnected, "\(name) isBiconnected")
            check(graph.biEdgeConnectedComponents().map(Array.init) == grouped(biEdgeLabels), "\(name) biEdgeConnectedComponents")
            check(graph.isBiEdgeConnected == (n >= 2 && componentCount == 1 && bridges.isEmpty), "\(name) isBiEdgeConnected")

            let tree = graph.blockCutTree()
            check(tree.articulationPoints == points, "\(name) block–cut tree points")
            var treeEdges = 0
            for b in blocks.indices {
                let inside = Set(found.vertices(ofComponentAt: b))
                let expected = points.indices.filter { inside.contains(points[$0]) }
                check(Array(tree.articulationPoints(ofBlock: b)) == expected, "\(name) articulationPoints(ofBlock: \(b))")
                treeEdges += expected.count
            }
            check(tree.edgeCount == treeEdges, "\(name) block–cut tree edgeCount")
            // A forest: nodes − edges is the number of components with a non-loop edge.
            let withEdges = Set(edges.filter { $0.0 != $0.1 }.map { base[$0.0] }).count
            check(blocks.count + points.count - treeEdges == withEdges, "\(name) block–cut tree is not a forest")
            for (i, p) in points.enumerated() {
                check(tree.node(of: p) == .articulationPoint(i), "\(name) node(of: \(p))")
                check(Array(tree.blocks(ofArticulationPoint: i)) == Array(found.components(containing: p)), "\(name) blocks(ofArticulationPoint:)")
            }
        }

        var seen = Set<UndirectedEdge<Int>>()
        let simple = raw.filter { seen.insert(UndirectedEdge($0.0, $0.1)).inserted }
        checkAll(UndirectedAdjacencyList(vertices: 0 ..< n, edges: simple.map { UndirectedEdge($0.0, $0.1) }), simple, { $0 }, "UndirectedAdjacencyList")

        var seenArcs = Set<DirectedEdge<Int>>()
        let arcs = raw.filter { seenArcs.insert(DirectedEdge(from: $0.0, to: $0.1)).inserted }
        let view = AdjacencyList(vertices: 0 ..< n, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }).undirected
        let viewEdges = view.edges.map { ($0.u, $0.v) }
        let viewRanks = Dictionary(uniqueKeysWithValues: view.edges.indices.enumerated().map { ($1, $0) })
        checkAll(view, viewEdges, { viewRanks[$0]! }, "AdjacencyList.undirected")

        checkAll(PlainGraph(vertices: Array(0 ..< n), edges: raw.map { UndirectedEdge($0.0, $0.1) }), raw, { $0 }, "PlainGraph")
    }
}
