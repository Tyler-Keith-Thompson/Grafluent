// `edgeDisjointPaths(from:to:)` and `vertexDisjointPaths(from:to:)` (catalog §EdgeDisjointPaths,
// §VertexDisjointPaths): as many paths as λ(s, t) and κ(s, t) (an edge from s to t one path); each a
// path from s to t along its edges, repeating no vertex, checked here; no edge, or no inner vertex,
// in two of them. Which paths is not pinned. Directed rows are `AdjacencyList`, or
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

@Suite("Disjoint paths")
struct DisjointPathsTests {
    @Test("FL-502 one edge: 1 path")
    func fl502() {
        // V [0, 1]; E [0→1]; edgeDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 1)
        #expect(paths.count == 1)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 1))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
        }
    }

    @Test("FL-503 one edge: 1 path")
    func fl503() {
        // V [0, 1]; E [0→1]; vertexDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 1)
        #expect(paths.count == 1)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 1))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-504 no path: 0 paths")
    func fl504() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; edgeDisjointPaths(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 3)
        #expect(paths.count == 0)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 3))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
        }
    }

    @Test("FL-505 no path: 0 paths")
    func fl505() {
        // undirected V [0, 1, 2, 3]; E [0–1, 2–3]; vertexDisjointPaths(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 3)
        #expect(paths.count == 0)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 3))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-506 K(2) with parallel edges: each copy an edge path, one vertex path: 3 paths")
    func fl506() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; edgeDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 1)
        #expect(paths.count == 3)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 1))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
        }
    }

    @Test("FL-507 K(2) with parallel edges: each copy an edge path, one vertex path: 1 path")
    func fl507() {
        // undirected V [0, 1]; E [0–1, 0–1, 1–0]; vertexDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 0)]
        let graph = Pseudograph<Int>(vertices: [0, 1] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 1)
        #expect(paths.count == 1)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 1))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-508 directed: adjacent pair: the edge counts as one path: 2 paths")
    func fl508() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; edgeDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 1)
        #expect(paths.count == 2)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 1))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
        }
    }

    @Test("FL-509 directed: adjacent pair: the edge counts as one path: 2 paths")
    func fl509() {
        // V [0, 1, 2]; E [0→1, 0→2, 2→1]; vertexDisjointPaths(from: 0, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (2, 1)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 1)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 1)
        #expect(paths.count == 2)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 1))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-510 directed: parallel arcs: 2 paths")
    func fl510() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; edgeDisjointPaths(from: 2, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 2)!
        let t = vertexList.firstIndex(of: 1)!
        let paths = graph.edgeDisjointPaths(from: 2, to: 1)
        #expect(paths.count == 2)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 2, to: 1))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
        }
    }

    @Test("FL-511 directed: parallel arcs: 1 path")
    func fl511() {
        // V [0, 1, 2]; E [0→1, 0→1, 1→2, 2→0, 2→0]; vertexDisjointPaths(from: 2, to: 1)
        let pairs: [(Int, Int)] = [(0, 1), (0, 1), (1, 2), (2, 0), (2, 0)]
        let graph = DirectedPseudograph<Int>(vertices: [0, 1, 2] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 2)!
        let t = vertexList.firstIndex(of: 1)!
        let paths = graph.vertexDisjointPaths(from: 2, to: 1)
        #expect(paths.count == 1)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 2, to: 1))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-512 two triangles sharing a vertex: 2 edge paths, 1 vertex path: 2 paths")
    func fl512() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; edgeDisjointPaths(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 4)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 4)
        #expect(paths.count == 2)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 4))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
        }
    }

    @Test("FL-513 two triangles sharing a vertex: 2 edge paths, 1 vertex path: 1 path")
    func fl513() {
        // undirected V [0, 1, 2, 3, 4]; E [0–1, 1–2, 0–2, 2–3, 3–4, 2–4]; vertexDisjointPaths(from: 0, to: 4)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 4)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 4)
        #expect(paths.count == 1)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 4))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-514 CLRS figure 26.1, unit: 2 paths")
    func fl514() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1, s→v2, v1→v3, v2→v1, v2→v4, v3→v2, v3→t, v4→v3, v4→t]; edgeDisjointPaths(from: s, to: t)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "s")!
        let t = vertexList.firstIndex(of: "t")!
        let paths = graph.edgeDisjointPaths(from: "s", to: "t")
        #expect(paths.count == 2)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: "s", to: "t"))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
        }
    }

    @Test("FL-515 CLRS figure 26.1, unit: 2 paths")
    func fl515() {
        // V [s, v1, v2, v3, v4, t]; E [s→v1, s→v2, v1→v3, v2→v1, v2→v4, v3→v2, v3→t, v4→v3, v4→t]; vertexDisjointPaths(from: s, to: t)
        let pairs: [(String, String)] = [("s", "v1"), ("s", "v2"), ("v1", "v3"), ("v2", "v1"), ("v2", "v4"), ("v3", "v2"), ("v3", "t"), ("v4", "v3"), ("v4", "t")]
        let graph = AdjacencyList<String>(vertices: ["s", "v1", "v2", "v3", "v4", "t"] as [String], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == ["s", "v1", "v2", "v3", "v4", "t"] as [String])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: "s")!
        let t = vertexList.firstIndex(of: "t")!
        let paths = graph.vertexDisjointPaths(from: "s", to: "t")
        #expect(paths.count == 2)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: "s", to: "t"))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-516 Petersen: 3 paths")
    func fl516() {
        // nx(petersen_graph); edgeDisjointPaths(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 7)
        #expect(paths.count == 3)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 7))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
        }
    }

    @Test("FL-517 Petersen: 3 paths")
    func fl517() {
        // nx(petersen_graph); vertexDisjointPaths(from: 0, to: 7)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (0, 5), (1, 2), (1, 6), (2, 3), (2, 7), (3, 4), (3, 8), (4, 9), (5, 7), (5, 8), (6, 8), (6, 9), (7, 9)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 7)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 7)
        #expect(paths.count == 3)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 7))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-518 grid(3,4): 2 paths")
    func fl518() {
        // grid(3,4); edgeDisjointPaths(from: 0, to: 11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 11)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 11)
        #expect(paths.count == 2)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 11))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
        }
    }

    @Test("FL-519 grid(3,4): 2 paths")
    func fl519() {
        // grid(3,4); vertexDisjointPaths(from: 0, to: 11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8), (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (9, 10), (10, 11)]
        let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int], edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        #expect(graph.edges.map { [$0.u, $0.v] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 11)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 11)
        #expect(paths.count == 2)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 11))
        // Each a path from s to t along its edges (an arc against the stored order when reversed), repeating
        // no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, arc) in path.edges.enumerated() {
                let (a, b) = arc.reversed ? (ends[arc.position].1, ends[arc.position].0) : ends[arc.position]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(arc.position).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-520 directed: bidirected C(5): 2 paths")
    func fl520() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; edgeDisjointPaths(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 2)
        #expect(paths.count == 2)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 2))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
        }
    }

    @Test("FL-521 directed: bidirected C(5): 2 paths")
    func fl521() {
        // V [0, 1, 2, 3, 4]; E [0→1, 1→2, 2→3, 3→4, 4→0, 1→0, 2→1, 3→2, 4→3, 0→4]; vertexDisjointPaths(from: 0, to: 2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0), (1, 0), (2, 1), (3, 2), (4, 3), (0, 4)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 2)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 2)
        #expect(paths.count == 2)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 2))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-522 self-loops and a cycle on the way: 1 path")
    func fl522() {
        // V [0, 1, 2, 3]; E [0→0, 0→1, 1→2, 2→1, 2→3, 1→1, 0→2]; edgeDisjointPaths(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let paths = graph.edgeDisjointPaths(from: 0, to: 3)
        #expect(paths.count == 1)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 0, to: 3))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
        }
    }

    @Test("FL-523 self-loops and a cycle on the way: 1 path")
    func fl523() {
        // V [0, 1, 2, 3]; E [0→0, 0→1, 1→2, 2→1, 2→3, 1→1, 0→2]; vertexDisjointPaths(from: 0, to: 3)
        let pairs: [(Int, Int)] = [(0, 0), (0, 1), (1, 2), (2, 1), (2, 3), (1, 1), (0, 2)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 0)!
        let t = vertexList.firstIndex(of: 3)!
        let paths = graph.vertexDisjointPaths(from: 0, to: 3)
        #expect(paths.count == 1)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 0, to: 3))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }

    @Test("FL-530 directed: a flow cycle the decomposition drops: 2 paths")
    func fl530() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [3→6, 5→8, 0→7, 7→0, 7→3, 8→4, 0→6, 5→7, 4→0]; edgeDisjointPaths(from: 5, to: 6)
        let pairs: [(Int, Int)] = [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 5)!
        let t = vertexList.firstIndex(of: 6)!
        let paths = graph.edgeDisjointPaths(from: 5, to: 6)
        #expect(paths.count == 2)
        // As many as the fewest edges separating s from t (Menger).
        #expect(paths.count == graph.edgeConnectivity(from: 5, to: 6))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
        }
    }

    @Test("FL-531 directed: a flow cycle the decomposition drops: 2 paths")
    func fl531() {
        // V [0, 1, 2, 3, 4, 5, 6, 7, 8]; E [3→6, 5→8, 0→7, 7→0, 7→3, 8→4, 0→6, 5→7, 4→0]; vertexDisjointPaths(from: 5, to: 6)
        let pairs: [(Int, Int)] = [(3, 6), (5, 8), (0, 7), (7, 0), (7, 3), (8, 4), (0, 6), (5, 7), (4, 0)]
        let graph = AdjacencyList<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int], edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let vertexList = Array(graph.vertices)
        #expect(vertexList == [0, 1, 2, 3, 4, 5, 6, 7, 8] as [Int])
        #expect(graph.edges.map { [$0.source, $0.target] } == pairs.map { [$0.0, $0.1] })
        // Edge ends as vertex indices (positions in `vertices`), in position order.
        let ends = pairs.map { (vertexList.firstIndex(of: $0.0)!, vertexList.firstIndex(of: $0.1)!) }
        let s = vertexList.firstIndex(of: 5)!
        let t = vertexList.firstIndex(of: 6)!
        let paths = graph.vertexDisjointPaths(from: 5, to: 6)
        #expect(paths.count == 2)
        // As many as κ(s, t), an edge from s to t counting as one path (Menger).
        #expect(paths.count == graph.vertexConnectivity(from: 5, to: 6))
        // Each a path from s to t along its edges, repeating no vertex; no edge in two of them.
        var usedEdges = Set<Int>()
        var usedInner = Set<Int>()
        for path in paths {
            let numbers = path.vertices.map { vertexList.firstIndex(of: $0)! }
            #expect(numbers.first == s && numbers.last == t && numbers.count == path.edges.count + 1)
            #expect(Set(numbers).count == numbers.count)
            for (i, edge) in path.edges.enumerated() {
                let (a, b) = ends[edge]
                #expect(a == numbers[i] && b == numbers[i + 1] && a != b)
                #expect(usedEdges.insert(edge).inserted)
            }
            for x in numbers.dropFirst().dropLast() { #expect(usedInner.insert(x).inserted) }
        }
    }
}
