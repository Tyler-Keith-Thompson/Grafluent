// Conformances beyond Graph (api.md, "All four"): Codable in the adjacency-list format (vertices,
// then edges as pairs of vertex offsets), so a `Tree` or `Forest` decodes what an
// `UndirectedAdjacencyList` encodes and an `Arborescence` what an `AdjacencyList` encodes; decoding
// re-checks the invariant and rejects a repeated vertex with DecodingError.dataCorrupted.
// `CustomStringConvertible` in the form every representation shares (`[0, 1, 2]; [0–1, 1–2]`), so a
// tree prints as the adjacency list copied from it. `Sendable` when the vertex is, the views
// included. Values used here are the catalog's sources; the expected values are each type's own
// round trip or the adjacency list's output. Case IDs (TS-nnn) refer to the catalog; see README.md.

import AdjacencyListModule
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing
import Trees

@Suite("Tree conformances: Codable, descriptions, Sendable", .tags(.conformance))
struct TreeConformanceTests {
    @Test("All four round-trip through JSON and property lists, with Int and String vertices")
    func roundTrip() throws {
        // E1 (TS-200), rooted at 4 (TS-218), its arborescence (TS-607), TS-401's forest, TS-244's names.
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let rooted = RootedTree(tree, root: 4)
        let arborescence = Arborescence(rooted)
        let forestPairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let forest = try #require(Forest(vertices: [5, 4, 3], edges: forestPairs.map { UndirectedEdge($0.0, $0.1) }))
        let names: [(String, String)] = [("ann", "bob"), ("ann", "cy"), ("cy", "dee")]
        let namedTree = try #require(Tree(edges: names.map { UndirectedEdge($0.0, $0.1) }))
        let named = RootedTree(namedTree, root: "dee")

        let decodedTree = try JSONDecoder().decode(Tree<Int>.self, from: JSONEncoder().encode(tree))
        #expect(decodedTree == tree)
        #expect(Array(decodedTree.vertices) == Array(tree.vertices))
        #expect(Array(decodedTree.edges) == Array(tree.edges))
        let decodedRooted = try JSONDecoder().decode(RootedTree<Int>.self, from: JSONEncoder().encode(rooted))
        #expect(decodedRooted == rooted)
        #expect(decodedRooted.root == 4)
        #expect(Array(decodedRooted.preorder) == [4, 1, 0, 2, 5, 3, 6])
        let decodedArborescence = try JSONDecoder().decode(Arborescence<Int>.self, from: JSONEncoder().encode(arborescence))
        #expect(decodedArborescence == arborescence)
        #expect(Array(decodedArborescence.edges) == Array(arborescence.edges))
        let decodedForest = try JSONDecoder().decode(Forest<Int>.self, from: JSONEncoder().encode(forest))
        #expect(decodedForest == forest)
        #expect(Array(decodedForest.vertices) == [5, 4, 3, 0, 1, 2])
        let decodedNamed = try PropertyListDecoder().decode(RootedTree<String>.self, from: PropertyListEncoder().encode(named))
        #expect(decodedNamed == named)
        #expect(Array(decodedNamed.preorder) == ["dee", "cy", "ann", "bob"])
        let empty = try JSONDecoder().decode(Forest<Int>.self, from: JSONEncoder().encode(Forest<Int>()))
        #expect(empty.trees.isEmpty)
    }

    @Test("Tree and Forest decode an UndirectedAdjacencyList's encoding; Arborescence an AdjacencyList's")
    func adjacencyListFormat() throws {
        // TS-030's tree, TS-019's forest, TS-063's arborescence.
        let treePairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
        let list = UndirectedAdjacencyList(edges: treePairs.map { UndirectedEdge($0.0, $0.1) })
        let tree = try JSONDecoder().decode(Tree<Int>.self, from: JSONEncoder().encode(list))
        #expect(tree == Tree(edges: treePairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(Array(tree.edges) == Array(list.edges))
        let forestPairs: [(Int, Int)] = [(0, 1), (2, 3)]
        let forestList = UndirectedAdjacencyList(vertices: [9], edges: forestPairs.map { UndirectedEdge($0.0, $0.1) })
        let forest = try JSONDecoder().decode(Forest<Int>.self, from: JSONEncoder().encode(forestList))
        #expect(Array(forest.vertices) == [9, 0, 1, 2, 3])
        #expect(forest.trees.count == 3)
        let arcs: [(Int, Int)] = [(1, 2), (0, 1)]
        let digraph = AdjacencyList(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let arborescence = try JSONDecoder().decode(Arborescence<Int>.self, from: JSONEncoder().encode(digraph))
        #expect(Array(arborescence.edges) == arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(arborescence.root == 0)
        // And the other way: what a Tree encodes, an UndirectedAdjacencyList decodes.
        let back = try JSONDecoder().decode(UndirectedAdjacencyList<Int>.self, from: JSONEncoder().encode(tree))
        #expect(Array(back.vertices) == Array(tree.vertices))
        #expect(Array(back.edges) == Array(tree.edges))
        let arcsBack = try JSONDecoder().decode(AdjacencyList<Int>.self, from: JSONEncoder().encode(arborescence))
        #expect(Array(arcsBack.edges) == Array(arborescence.edges))
    }

    @Test("Decoding a graph that breaks the invariant, or repeats a vertex, throws dataCorrupted")
    func decodeInvalid() {
        func expectCorrupted<T: Decodable>(_ type: T.Type, _ json: String) {
            do {
                _ = try JSONDecoder().decode(type, from: Data(json.utf8))
                Issue.record("decoded \(T.self) from \(json)")
            } catch DecodingError.dataCorrupted {
                // Expected.
            } catch {
                Issue.record("\(T.self) from \(json): \(error)")
            }
        }
        // A triangle (TS-015), the null graph (TS-002), two isolated vertices (TS-012), a loop (TS-007).
        expectCorrupted(Tree<Int>.self, #"{"vertices":[0,1,2],"edges":[0,1,1,2,2,0]}"#)
        expectCorrupted(Tree<Int>.self, #"{"vertices":[],"edges":[]}"#)
        expectCorrupted(Tree<Int>.self, #"{"vertices":[0,1],"edges":[]}"#)
        expectCorrupted(Tree<Int>.self, #"{"vertices":[0],"edges":[0,0]}"#)
        // A repeated vertex, an endpoint out of range, an odd edge list.
        expectCorrupted(Tree<Int>.self, #"{"vertices":[0,0,1],"edges":[0,2,1,2]}"#)
        expectCorrupted(Tree<Int>.self, #"{"vertices":[0,1],"edges":[0,5]}"#)
        expectCorrupted(Tree<Int>.self, #"{"vertices":[0,1],"edges":[0]}"#)
        // A forest with a parallel pair (TS-412) or a repeated vertex.
        expectCorrupted(Forest<Int>.self, #"{"vertices":[0,1,2,3],"edges":[0,1,2,3,2,3]}"#)
        expectCorrupted(Forest<Int>.self, #"{"vertices":[0,0],"edges":[]}"#)
        // Arcs that are not an arborescence: an in-tree (TS-053), a root beside a 2-cycle (TS-068).
        expectCorrupted(Arborescence<Int>.self, #"{"vertices":[1,0,2],"edges":[0,1,2,1]}"#)
        expectCorrupted(Arborescence<Int>.self, #"{"vertices":[0,1,2,3],"edges":[0,1,2,3,3,2]}"#)
        expectCorrupted(Arborescence<Int>.self, #"{"vertices":[0,0],"edges":[0,1]}"#)
    }

    @Test("A RootedTree whose encoding names a different root decodes to that root, and every root round-trips")
    func rootedRoundTripAtEveryRoot() throws {
        // E2 (TS-224) at each of its roots.
        let pairs: [(Int, Int)] = [(4, 2), (0, 2), (2, 1), (1, 3)]
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        for root in tree.vertices {
            let rooted = RootedTree(tree, root: root)
            let decoded = try JSONDecoder().decode(RootedTree<Int>.self, from: JSONEncoder().encode(rooted))
            #expect(decoded == rooted, "root \(root)")
            #expect(decoded.root == root)
            #expect(Array(decoded.preorder) == Array(rooted.preorder), "root \(root)")
            #expect(Array(decoded.edges) == Array(rooted.edges), "root \(root)")
        }
    }

    @Test("description is the form every representation shares: a tree prints as the adjacency list copied from it")
    func descriptions() throws {
        // TS-030's tree, TS-401's forest, TS-063's arborescence and TS-244's names.
        let pairs: [(Int, Int)] = [(0, 1), (2, 3), (1, 2)]
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(String(describing: tree) == String(describing: UndirectedAdjacencyList(tree)))
        let forestPairs: [(Int, Int)] = [(0, 1), (2, 3), (3, 4)]
        let forest = try #require(Forest(vertices: [5, 4, 3], edges: forestPairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(String(describing: forest) == String(describing: UndirectedAdjacencyList(forest)))
        let arcs: [(Int, Int)] = [(1, 2), (0, 1)]
        let arborescence = try #require(Arborescence(edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) }))
        #expect(String(describing: arborescence) == String(describing: AdjacencyList(arborescence)))
        let names: [(String, String)] = [("ann", "bob"), ("ann", "cy"), ("cy", "dee")]
        let named = try #require(Tree(edges: names.map { UndirectedEdge($0.0, $0.1) }))
        #expect(String(describing: named) == String(describing: UndirectedAdjacencyList(named)))
        let rooted = RootedTree(named, root: "dee")
        #expect(!String(describing: rooted).isEmpty)
        // debugDescription names the type.
        #expect(String(reflecting: tree).contains("Tree"))
        #expect(String(reflecting: rooted).contains("RootedTree"))
        #expect(String(reflecting: arborescence).contains("Arborescence"))
        #expect(String(reflecting: forest).contains("Forest"))
    }

    @Test("Sendable when the vertex is: the values and their views cross into a Task")
    func sendable() async throws {
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let rooted = RootedTree(tree, root: 0)
        let arborescence = Arborescence(rooted)
        let forest = Forest(tree)
        let preorder = rooted.preorder
        let children = rooted.children(of: 1)
        let trees = forest.trees
        let ancestors = arborescence.ancestors(of: 6)
        let descendants = rooted.descendants(of: 1)
        let summary = await Task {
            [tree.edgeCount, rooted.height, arborescence.depth(of: 6), forest.trees.count,
             preorder.count, children.count, trees.count, Array(ancestors).count, descendants.count]
        }.value
        #expect(summary == [6, 3, 3, 1, 7, 2, 1, 3, 3])
        func requireSendable<T: Sendable>(_: T) {}
        requireSendable(tree)
        requireSendable(rooted)
        requireSendable(arborescence)
        requireSendable(forest)
        requireSendable(preorder)
        requireSendable(trees)
        requireSendable(children)
        requireSendable(ancestors)
    }

    @Test("Generic code over Graph and BidirectionalDirectedGraph sees the same counts")
    func genericCode() throws {
        func degreeSum<G: Graph>(_ graph: G) -> Int { graph.vertices.reduce(0) { $0 + graph.degree(of: $1) } }
        func inDegreeSum<G: BidirectionalDirectedGraph>(_ graph: G) -> Int { graph.vertices.reduce(0) { $0 + graph.inDegree(of: $1) } }
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (4, 6)]
        let tree = try #require(Tree(edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(degreeSum(tree) == 12)
        #expect(degreeSum(RootedTree(tree, root: 3)) == 12)
        #expect(degreeSum(Forest(tree)) == 12)
        #expect(inDegreeSum(Arborescence(RootedTree(tree, root: 3))) == 6)
        #expect(degreeSum(Arborescence(RootedTree(tree, root: 3)).undirected) == 12)
    }
}
