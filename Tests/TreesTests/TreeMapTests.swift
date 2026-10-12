// Attached maps (GraphProtocols' `PropertyGraph`) on `Tree`, `RootedTree`, `Arborescence` and
// `Forest`: a vertex map holds one value per vertex index (the order of `vertices`), an edge map
// one per edge position, every value the map's default until it is set. The trees are immutable,
// so nothing moves a value. The tests check defaults, writes by index and by vertex (`String`
// vertices, so by-vertex reads go through the lookup), the `checked` subscripts, `values(of:)`,
// copy-on-write, traps (in child processes), that equality, hashing and coding ignore maps, that a
// conversion is a new graph with no maps and its own generation, and a model of the maps as
// dictionaries keyed by vertex and edge. See README.md.

import Foundation
import GrafluentTestSupport
import GraphProtocols
import PropertyBased
import Testing
import Trees

@Suite("Tree attached maps")
struct TreeMapTests {
    @Test("Tree: defaults, writes by index and by vertex, checked reads, values(of:)")
    func tree() throws {
        // a – b – c, b – d: edges at positions 0, 1, 2 in the given order.
        var tree = Tree(edges: [UndirectedEdge("a", "b"), UndirectedEdge("c", "b"), UndirectedEdge("b", "d")])!
        let weights = tree.addEdgeMap(default: 1.0)
        let depths = tree.addVertexMap(of: Int.self)
        #expect(tree.edges.indices.map { tree[weights, ofEdgeAt: $0] } == [1, 1, 1])
        #expect(tree.vertices.map { tree[depths, of: $0] } == [nil, nil, nil, nil])
        tree[weights, ofEdgeAt: 1] = 2.5
        tree[depths, of: "c"] = 2
        tree[depths, ofVertexAt: tree.vertexIndex(of: "a")] = 0
        #expect(tree.edges.indices.map { tree[weights, ofEdgeAt: $0] } == [1, 2.5, 1])
        #expect(tree[depths, ofVertexAt: tree.vertexIndex(of: "c")] == 2 && tree[depths, of: "a"] == 0)
        #expect(try tree[depths, checked: "c"] == 2)
        #expect(try tree[depths, checkedVertexAt: 3] == nil)
        #expect(try tree[weights, checkedEdgeAt: 1] == 2.5)
        #expect(throws: VertexNotFound.self) { try tree[depths, checked: "z"] }
        #expect(throws: VertexNotFound.self) { try tree[depths, checkedVertexAt: 4] }
        #expect(throws: EdgeNotFound.self) { try tree[weights, checkedEdgeAt: 3] }
        #expect(throws: EdgeNotFound.self) { try tree[weights, checkedEdgeAt: -1] }

        let w = tree.values(of: weights)
        #expect(tree.incidentEdges(of: "b").map { w[$0] } == [1, 2.5, 1] && w.defaultValue == 1)
        let d = tree.values(of: depths)
        #expect(d[tree.vertexIndex(of: "c")] == 2)
        tree[weights, ofEdgeAt: 0] = 9
        #expect(w[0] == 1 && tree.values(of: weights)[0] == 9)

        let extra = tree.addEdgeMap(default: "e")
        tree.removeEdgeMap(weights)
        tree.removeVertexMap(depths)
        #expect(tree[extra, ofEdgeAt: 2] == "e")
    }

    @Test("RootedTree, Arborescence and Forest keep maps by the same positions")
    func otherTypes() throws {
        var rooted = RootedTree(parents: [nil, 0, 0, 1])!
        let r = rooted.addVertexMap(default: 0)
        let re = rooted.addEdgeMap(default: 0)
        for v in rooted.preorder { rooted[r, of: v] = rooted.depth(of: v) }
        rooted[re, ofEdgeAt: rooted.parentEdge(of: 3)!] = 7
        #expect(rooted.vertices.map { rooted[r, of: $0] } == [0, 1, 1, 2])
        #expect(try rooted[re, checkedEdgeAt: 2] == 7 && rooted.values(of: re)[2] == 7)
        #expect(throws: VertexNotFound.self) { try rooted[r, checked: 4] }
        #expect(throws: VertexNotFound.self) { try rooted[r, checkedVertexAt: 4] }
        #expect(throws: VertexNotFound.self) { try rooted[r, checkedVertexAt: -1] }
        #expect(try rooted[r, checkedVertexAt: 3] == 2)
        #expect(throws: EdgeNotFound.self) { try rooted[re, checkedEdgeAt: 3] }

        var arborescence = Arborescence(rooted)
        let a = arborescence.addEdgeMap(default: 1)
        let av = arborescence.addVertexMap(default: "")
        arborescence[a, ofEdgeAt: arborescence.inEdges(of: 2).first!] = 5
        arborescence[av, ofVertexAt: 3] = "leaf"
        #expect(arborescence.edges.indices.map { arborescence[a, ofEdgeAt: $0] } == [1, 5, 1])
        #expect(try arborescence[av, checked: 3] == "leaf" && arborescence.values(of: av)[3] == "leaf")
        #expect(throws: VertexNotFound.self) { try arborescence[av, checkedVertexAt: -1] }
        #expect(throws: VertexNotFound.self) { try arborescence[av, checkedVertexAt: 4] }
        #expect(throws: EdgeNotFound.self) { try arborescence[a, checkedEdgeAt: 3] }

        var forest = Forest(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(3, 4)])!
        let f = forest.addVertexMap(default: -1)
        let fe = forest.addEdgeMap(of: String.self)
        for v in forest.vertices { forest[f, of: v] = forest.component(of: v) }
        forest[fe, ofEdgeAt: 1] = "3–4"
        #expect(forest.vertices.map { forest[f, of: $0] } == [0, 0, 1, 2, 2])
        #expect(try forest[fe, checkedEdgeAt: 1] == "3–4" && forest.values(of: fe)[0] == nil)
        #expect(throws: VertexNotFound.self) { try forest[f, checked: 5] }
        #expect(throws: VertexNotFound.self) { try forest[f, checkedVertexAt: 5] }
        #expect(throws: VertexNotFound.self) { try forest[f, checkedVertexAt: -1] }
        #expect(try forest[f, checkedVertexAt: 4] == 2)
        #expect(throws: EdgeNotFound.self) { try forest[fe, checkedEdgeAt: 2] }
        forest.removeVertexMap(f)
        forest.removeEdgeMap(fe)

        // A forest of no vertices takes maps too.
        var empty = Forest<Int>()
        let none = empty.addVertexMap(default: 0)
        #expect(throws: VertexNotFound.self) { try empty[none, checked: 0] }
    }

    @Test("A copy shares the maps until either writes", .tags(.copyOnWrite))
    func copiesAreIndependent() {
        var tree = Tree(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])!
        let weights = tree.addEdgeMap(default: 0)
        tree[weights, ofEdgeAt: 0] = 1
        var copy = tree
        copy[weights, ofEdgeAt: 0] = 2
        tree[weights, ofEdgeAt: 1] = 3
        #expect(tree[weights, ofEdgeAt: 0] == 1 && tree[weights, ofEdgeAt: 1] == 3)
        #expect(copy[weights, ofEdgeAt: 0] == 2 && copy[weights, ofEdgeAt: 1] == 0)
    }

    @Test("Equality, hashing and coding ignore maps; a decoded tree has none")
    func conformancesIgnoreMaps() throws {
        let plain = RootedTree(parents: [nil, 0, 1])!
        var mapped = plain
        let labels = mapped.addVertexMap(default: "x")
        mapped[labels, of: 2] = "y"
        _ = mapped.addEdgeMap(default: 0)
        #expect(mapped == plain && mapped.hashValue == plain.hashValue && mapped.description == plain.description)
        // Sorted keys: a keyed container's order is otherwise not deterministic.
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encoded = try encoder.encode(mapped)
        #expect(encoded == (try encoder.encode(plain)))
        #expect(try JSONDecoder().decode(RootedTree<Int>.self, from: encoded) == plain)
    }

    @Test("Generations: every initializer stamps one, a conversion included; copies share it")
    func generations() throws {
        let tree = Tree(edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])!
        let rooted = RootedTree(tree, root: 1)
        let arborescence = Arborescence(rooted)
        let forest = Forest(tree)
        let graphs: [GraphGeneration] = [
            tree.generation, Tree(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])!.generation,
            Tree(rooted).generation, Tree(pruferSequence: [1])!.generation,
            try JSONDecoder().decode(Tree<Int>.self, from: JSONEncoder().encode(tree)).generation,
            rooted.generation, RootedTree(parents: [nil, 0])!.generation, RootedTree(arborescence).generation,
            RootedTree(vertices: [0, 1]) { $0 == 0 ? nil : 0 }!.generation,
            arborescence.generation, Arborescence(edges: [DirectedEdge(from: 0, to: 1)])!.generation,
            Arborescence(parents: [nil, 0])!.generation,
            forest.generation, Forest<Int>().generation, Forest(edges: [UndirectedEdge(0, 1)])!.generation,
            forest.trees[0].generation, forest.trees[0].generation,
        ]
        for (k, generation) in graphs.enumerated() {
            for (j, other) in graphs.enumerated() where j != k {
                #expect(!generation.isCurrent(for: other), "\(k) against \(j)")
            }
        }
        #expect(tree.generation.isCurrent(for: tree) && rooted.generation.isCurrent(for: rooted))
        #expect(arborescence.generation.isCurrent(for: arborescence) && forest.generation.isCurrent(for: forest))
        var copy = tree
        _ = copy.addVertexMap(default: 0)
        #expect(tree.generation.isCurrent(for: copy))
    }

    @Test("Reading or writing outside the tree traps, and a converted tree has none of the maps", .tags(.precondition))
    func traps() async {
        await #expect(processExitsWith: .failure) {
            var tree = Tree(edges: [UndirectedEdge(0, 1)])!
            let weights = tree.addEdgeMap(default: 0)
            _ = tree[weights, ofEdgeAt: 1]
        }
        await #expect(processExitsWith: .failure) {
            var tree = Tree(edges: [UndirectedEdge(0, 1)])!
            let weights = tree.addEdgeMap(default: 0)
            tree[weights, ofEdgeAt: -1] = 1
        }
        await #expect(processExitsWith: .failure) {
            var tree = RootedTree(parents: [nil, 0])!
            let labels = tree.addVertexMap(default: 0)
            _ = tree[labels, ofVertexAt: 2]
        }
        await #expect(processExitsWith: .failure) {
            var tree = Arborescence(parents: [nil, 0])!
            let labels = tree.addVertexMap(default: 0)
            tree[labels, ofVertexAt: -1] = 1
        }
        await #expect(processExitsWith: .failure) {
            var forest = Forest(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])!
            let labels = forest.addVertexMap(default: 0)
            _ = forest[labels, of: 3]
        }
        await #expect(processExitsWith: .failure) {
            var forest = Forest(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])!
            let labels = forest.addVertexMap(default: 0)
            forest[labels, of: 7] = 1
        }
        await #expect(processExitsWith: .failure) {
            var rooted = RootedTree(parents: [nil, 0])!
            let weights = rooted.addEdgeMap(default: 0)
            _ = Arborescence(rooted)[weights, ofEdgeAt: 0]
        }
        await #expect(processExitsWith: .failure) {
            var tree = Tree(edges: [UndirectedEdge(0, 1)])!
            let labels = tree.addVertexMap(default: 0)
            _ = Forest(tree).values(of: labels)
        }
        await #expect(processExitsWith: .failure) {
            var tree = Tree(edges: [UndirectedEdge(0, 1)])!
            let labels = tree.addVertexMap(default: 0)
            tree.removeVertexMap(labels)
            _ = try? tree[labels, checked: 0]
        }
        // Without the faults: the same calls succeed.
        var tree = Tree(edges: [UndirectedEdge(0, 1)])!
        let weights = tree.addEdgeMap(default: 0)
        let labels = tree.addVertexMap(default: 0)
        tree[weights, ofEdgeAt: 0] = 1
        tree[labels, of: 1] = 2
        #expect(tree[weights, ofEdgeAt: 0] == 1 && tree[labels, ofVertexAt: 1] == 2)
    }

    @Test("Maps agree with dictionaries keyed by vertex and edge under random writes", .tags(.randomized))
    func modelOfMaps() async {
        // A tree grown from attachment choices: vertex i + 1 hangs from choice mod (i + 1).
        let choices = Gen.int(in: 0 ... 20).array(of: 0 ... 12)
        let writes = zip(Gen.int(in: 0 ... 40), Gen.int(in: -5 ... 5)).array(of: 0 ... 30)
        await propertyCheck(count: 200, input: choices, writes) { choices, writes in
            let edges = choices.enumerated().map { UndirectedEdge("v\($0.element % ($0.offset + 1))", "v\($0.offset + 1)") }
            let n = choices.count + 1
            var tree = Tree(vertices: (0 ..< n).map { "v\($0)" }, edges: edges)!
            let weights = tree.addEdgeMap(default: 0)
            let labels = tree.addVertexMap(of: Int.self)
            var weightOf: [UndirectedEdge<String>: Int] = [:]
            var labelOf: [String: Int] = [:]
            var copies: [(Tree<String>, [UndirectedEdge<String>: Int], [String: Int])] = []
            for (k, (target, value)) in writes.enumerated() {
                if k % 2 == 0, !edges.isEmpty {
                    let p = target % edges.count
                    tree[weights, ofEdgeAt: p] = value
                    weightOf[tree.edges[p]] = value
                } else {
                    let v = "v\(target % n)"
                    tree[labels, of: v] = value
                    labelOf[v] = value
                }
                if k % 5 == 0 { copies.append((tree, weightOf, labelOf)) }
            }
            copies.append((tree, weightOf, labelOf))
            for (copy, weightOf, labelOf) in copies {
                let w = copy.values(of: weights)
                for p in copy.edges.indices {
                    #expect(copy[weights, ofEdgeAt: p] == weightOf[copy.edges[p], default: 0] && w[p] == weightOf[copy.edges[p], default: 0])
                }
                let l = copy.values(of: labels)
                for v in copy.vertices {
                    #expect(copy[labels, of: v] == labelOf[v] && l[copy.vertexIndex(of: v)] == labelOf[v])
                }
            }
        }
    }
}
