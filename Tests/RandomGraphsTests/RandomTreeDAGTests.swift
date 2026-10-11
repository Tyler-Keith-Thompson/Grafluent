// Random trees and random DAGs for fixed seeds (catalog RG-095 – RG-106): a Prüfer code of n − 2
// draws, decoded by Tree(pruferSequence:); G(n, p) and G(n, m) oriented upward, with 0..<n as the
// topological order.
// Generated from cases.md by swiftgen.py; see README.md.

import AdjacencyListModule
import DirectedAcyclicGraphModule
import GraphProtocols
import Multigraphs
import RandomGraphs
import StableGraphs
import Testing
import Trees

@Suite("RandomGraphs random trees and DAGs exact outputs")
struct RandomTreeDAGTests {
    @Test("RG-095 n 1: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:)")
    func rg095() {
        // Tree<Int>.random(vertexCount: 1, using: &Xoshiro256StarStar(seed: 0)) → n 1; m 0; code []; E []; draws 0; = NetworkX
        var generator = Xoshiro256StarStar(seed: 0)
        let tree = Tree<Int>.random(vertexCount: 1, using: &generator)
        #expect(tree.vertexCount == 1 && tree.edgeCount == 0)
        #expect(Array(tree.vertices) == Array(0 ..< 1))
        // Tree(pruferSequence:)'s order: edge k joins the k-th leaf removed to the k-th code element.
        #expect(tree.edges.map { [$0.u, $0.v] } == [] as [[Int]])
        #expect((0 ..< 1).map { tree.degree(of: $0) } == [0] as [Int])
        #expect(tree.pruferSequence == nil)
        var expected = Xoshiro256StarStar(seed: 0)
        for _ in 0 ..< 0 { _ = expected.next() }
        #expect(generator == expected, "0 draws")
    }

    @Test("RG-096 n 2: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:)")
    func rg096() {
        // Tree<Int>.random(vertexCount: 2, using: &Xoshiro256StarStar(seed: 0)) → n 2; m 1; code []; E [0–1]; draws 0; = NetworkX
        var generator = Xoshiro256StarStar(seed: 0)
        let tree = Tree<Int>.random(vertexCount: 2, using: &generator)
        #expect(tree.vertexCount == 2 && tree.edgeCount == 1)
        #expect(Array(tree.vertices) == Array(0 ..< 2))
        // Tree(pruferSequence:)'s order: edge k joins the k-th leaf removed to the k-th code element.
        #expect(tree.edges.map { [$0.u, $0.v] } == [[0, 1]] as [[Int]])
        #expect((0 ..< 2).map { tree.degree(of: $0) } == [1, 1] as [Int])
        #expect(tree.pruferSequence == [])
        var expected = Xoshiro256StarStar(seed: 0)
        for _ in 0 ..< 0 { _ = expected.next() }
        #expect(generator == expected, "0 draws")
    }

    @Test("RG-097 n 6: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:)")
    func rg097() {
        // Tree<Int>.random(vertexCount: 6, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 5; code [4, 5, 0, 3]; E [1–4, 2–5, 4–0, 0–3, 3–5]; draws 4; = NetworkX
        var generator = Xoshiro256StarStar(seed: 0)
        let tree = Tree<Int>.random(vertexCount: 6, using: &generator)
        #expect(tree.vertexCount == 6 && tree.edgeCount == 5)
        #expect(Array(tree.vertices) == Array(0 ..< 6))
        // Tree(pruferSequence:)'s order: edge k joins the k-th leaf removed to the k-th code element.
        #expect(tree.edges.map { [$0.u, $0.v] } == [[1, 4], [2, 5], [4, 0], [0, 3], [3, 5]] as [[Int]])
        #expect((0 ..< 6).map { tree.degree(of: $0) } == [2, 1, 1, 2, 2, 2] as [Int])
        #expect(tree.pruferSequence == [4, 5, 0, 3])
        var expected = Xoshiro256StarStar(seed: 0)
        for _ in 0 ..< 4 { _ = expected.next() }
        #expect(generator == expected, "4 draws")
    }

    @Test("RG-098 n 6: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:)")
    func rg098() {
        // Tree<Int>.random(vertexCount: 6, using: &Xoshiro256StarStar(seed: 1)) → n 6; m 5; code [5, 4, 4, 3]; E [0–5, 1–4, 2–4, 4–3, 3–5]; draws 4; = NetworkX
        var generator = Xoshiro256StarStar(seed: 1)
        let tree = Tree<Int>.random(vertexCount: 6, using: &generator)
        #expect(tree.vertexCount == 6 && tree.edgeCount == 5)
        #expect(Array(tree.vertices) == Array(0 ..< 6))
        // Tree(pruferSequence:)'s order: edge k joins the k-th leaf removed to the k-th code element.
        #expect(tree.edges.map { [$0.u, $0.v] } == [[0, 5], [1, 4], [2, 4], [4, 3], [3, 5]] as [[Int]])
        #expect((0 ..< 6).map { tree.degree(of: $0) } == [1, 1, 1, 2, 3, 2] as [Int])
        #expect(tree.pruferSequence == [5, 4, 4, 3])
        var expected = Xoshiro256StarStar(seed: 1)
        for _ in 0 ..< 4 { _ = expected.next() }
        #expect(generator == expected, "4 draws")
    }

    @Test("RG-099 n 6: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:)")
    func rg099() {
        // Tree<Int>.random(vertexCount: 6, using: &Xoshiro256StarStar(seed: 42)) → n 6; m 5; code [0, 3, 5, 5]; E [1–0, 0–3, 2–5, 3–5, 4–5]; draws 7; = NetworkX
        var generator = Xoshiro256StarStar(seed: 42)
        let tree = Tree<Int>.random(vertexCount: 6, using: &generator)
        #expect(tree.vertexCount == 6 && tree.edgeCount == 5)
        #expect(Array(tree.vertices) == Array(0 ..< 6))
        // Tree(pruferSequence:)'s order: edge k joins the k-th leaf removed to the k-th code element.
        #expect(tree.edges.map { [$0.u, $0.v] } == [[1, 0], [0, 3], [2, 5], [3, 5], [4, 5]] as [[Int]])
        #expect((0 ..< 6).map { tree.degree(of: $0) } == [2, 1, 1, 2, 1, 3] as [Int])
        #expect(tree.pruferSequence == [0, 3, 5, 5])
        var expected = Xoshiro256StarStar(seed: 42)
        for _ in 0 ..< 7 { _ = expected.next() }
        #expect(generator == expected, "7 draws")
    }

    @Test("RG-100 n 10: Prüfer code of n − 2 draws, decoded by Tree(pruferSequence:)")
    func rg100() {
        // Tree<Int>.random(vertexCount: 10, using: &Xoshiro256StarStar(seed: 0)) → n 10; m 9; code [9, 1, 6, 6, 8, 1, 1, 1]; E [0–9, 2–1, 3–6, 4–6, 5–8, 6–1, 7–1, 8–1, 1–9]; draws 13; = NetworkX
        var generator = Xoshiro256StarStar(seed: 0)
        let tree = Tree<Int>.random(vertexCount: 10, using: &generator)
        #expect(tree.vertexCount == 10 && tree.edgeCount == 9)
        #expect(Array(tree.vertices) == Array(0 ..< 10))
        // Tree(pruferSequence:)'s order: edge k joins the k-th leaf removed to the k-th code element.
        #expect(tree.edges.map { [$0.u, $0.v] } == [[0, 9], [2, 1], [3, 6], [4, 6], [5, 8], [6, 1], [7, 1], [8, 1], [1, 9]] as [[Int]])
        #expect((0 ..< 10).map { tree.degree(of: $0) } == [1, 5, 1, 1, 1, 1, 3, 1, 2, 2] as [Int])
        #expect(tree.pruferSequence == [9, 1, 6, 6, 8, 1, 1, 1])
        var expected = Xoshiro256StarStar(seed: 0)
        for _ in 0 ..< 13 { _ = expected.next() }
        #expect(generator == expected, "13 draws")
    }

    @Test("RG-104 G(8, 0.4) on pairs u < v, oriented u → v (Barak–Erdős); the order 0..<n is topological")
    func rg104() {
        // DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &Xoshiro256StarStar(seed: 0)) → n 8; m 6; E [0→2, 0→5, 1→3, 1→4, 2→3, 6→7]; draws 7; = NetworkX
        func checkDAG(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 6 && graph.edges.count == 6, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 2], [0, 5], [1, 3], [1, 4], [2, 3], [6, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 2, 1, 0, 0, 0, 1, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 1, 2, 1, 1, 0, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 7 { _ = expected.next() }
            #expect(generator == expected, "\(type): 7 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<AdjacencyList<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 8), "DirectedAcyclicGraph<AdjacencyList<Int>>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<StableDirectedGraph<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 8), "DirectedAcyclicGraph<StableDirectedGraph<Int>>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<DirectedPseudograph<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 8), "DirectedAcyclicGraph<DirectedPseudograph<Int>>")
        }
        // The undirected procedure on the same stream: the same pairs, the same draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &generator)
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 2], [0, 5], [1, 3], [1, 4], [2, 3], [6, 7]] as [[Int]])
        }
    }

    @Test("RG-105 G(8, 0.4) on pairs u < v, oriented u → v (Barak–Erdős); the order 0..<n is topological")
    func rg105() {
        // DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &Xoshiro256StarStar(seed: 1)) → n 8; m 11; E [0→4, 0→5, 1→2, 1→3, 1→4, 1→5, 2→5, 2→6, 3→5, 4→6, 4→7]; draws 12; = NetworkX
        func checkDAG(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 8 && graph.edgeCount == 11 && graph.edges.count == 11, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 8), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 4], [0, 5], [1, 2], [1, 3], [1, 4], [1, 5], [2, 5], [2, 6], [3, 5], [4, 6], [4, 7]] as [[Int]], "\(type)")
            #expect((0 ..< 8).map { graph.outDegree(of: $0) } == [2, 4, 2, 1, 2, 0, 0, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 8)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 1, 1, 2, 4, 2, 1] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 1)
            for _ in 0 ..< 12 { _ = expected.next() }
            #expect(generator == expected, "\(type): 12 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<AdjacencyList<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 8), "DirectedAcyclicGraph<AdjacencyList<Int>>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<StableDirectedGraph<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 8), "DirectedAcyclicGraph<StableDirectedGraph<Int>>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<DirectedPseudograph<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 8), "DirectedAcyclicGraph<DirectedPseudograph<Int>>")
        }
        // The undirected procedure on the same stream: the same pairs, the same draws.
        do {
            var generator = Xoshiro256StarStar(seed: 1)
            let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 8, edgeProbability: 0.4, using: &generator)
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 4], [0, 5], [1, 2], [1, 3], [1, 4], [1, 5], [2, 5], [2, 6], [3, 5], [4, 6], [4, 7]] as [[Int]])
        }
    }

    @Test("RG-106 G(6, 5) on pairs u < v")
    func rg106() {
        // DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 6, edgeCount: 5, using: &Xoshiro256StarStar(seed: 0)) → n 6; m 5; E [0→3, 0→4, 2→5, 3→5, 4→5]; draws 17; = NetworkX
        func checkDAG(_ graph: some DirectedGraph<Int>, _ generator: Xoshiro256StarStar, _ type: String) {
            #expect(graph.vertexCount == 6 && graph.edgeCount == 5 && graph.edges.count == 5, "\(type)")
            #expect(Array(graph.vertices) == Array(0 ..< 6), "\(type)")
            #expect(graph.edges.map { [$0.source, $0.target] } == [[0, 3], [0, 4], [2, 5], [3, 5], [4, 5]] as [[Int]], "\(type)")
            #expect((0 ..< 6).map { graph.outDegree(of: $0) } == [2, 0, 1, 1, 1, 0] as [Int], "\(type)")
            var inDegrees = [Int](repeating: 0, count: 6)
            for edge in graph.edges { inDegrees[edge.target] += 1 }
            #expect(inDegrees == [0, 0, 0, 1, 1, 3] as [Int], "\(type)")
            var expected = Xoshiro256StarStar(seed: 0)
            for _ in 0 ..< 17 { _ = expected.next() }
            #expect(generator == expected, "\(type): 17 draws")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedAcyclicGraph<AdjacencyList<Int>>.erdosRenyi(vertexCount: 6, edgeCount: 5, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<AdjacencyList<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 6), "DirectedAcyclicGraph<AdjacencyList<Int>>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedAcyclicGraph<StableDirectedGraph<Int>>.erdosRenyi(vertexCount: 6, edgeCount: 5, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<StableDirectedGraph<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 6), "DirectedAcyclicGraph<StableDirectedGraph<Int>>")
        }
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = DirectedAcyclicGraph<DirectedPseudograph<Int>>.erdosRenyi(vertexCount: 6, edgeCount: 5, using: &generator)
            checkDAG(graph, generator, "DirectedAcyclicGraph<DirectedPseudograph<Int>>")
            #expect(Array(graph.topologicalOrder) == Array(0 ..< 6), "DirectedAcyclicGraph<DirectedPseudograph<Int>>")
        }
        // The undirected procedure on the same stream: the same pairs, the same draws.
        do {
            var generator = Xoshiro256StarStar(seed: 0)
            let graph = UndirectedAdjacencyList<Int>.erdosRenyi(vertexCount: 6, edgeCount: 5, using: &generator)
            #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3], [0, 4], [2, 5], [3, 5], [4, 5]] as [[Int]])
        }
    }
}
