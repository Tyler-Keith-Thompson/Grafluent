// findKuratowskiSubgraph() (catalog PL-131 – PL-151): nil when planar; otherwise a subdivision of K₅ or
// K₃,₃ made of the graph's edges, checked against the definition, pinned where it is unique, and its
// kind pinned where only one kind occurs.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("findKuratowskiSubgraph()")
struct KuratowskiSubgraphTests {
    @Test("PL-131 planar: nil: findKuratowskiSubgraph()")
    func pl131() {
        // U: K(4); findKuratowskiSubgraph() → nil
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        #expect(graph.findKuratowskiSubgraph() == nil)
        #expect(graph.isPlanar && graph.planarEmbedding() != nil)
    }

    @Test("PL-132 empty: nil: findKuratowskiSubgraph()")
    func pl132() {
        // U:; findKuratowskiSubgraph() → nil
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [] as [Int])
        #expect(graph.findKuratowskiSubgraph() == nil)
        #expect(graph.isPlanar && graph.planarEmbedding() != nil)
    }

    @Test("PL-133 K5: findKuratowskiSubgraph()")
    func pl133() throws {
        // U: K(5); findKuratowskiSubgraph() → K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [0, 1, 2, 3, 4]
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k5)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(witness.branchVertices == [0, 1, 2, 3, 4])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-134 K3,3: findKuratowskiSubgraph()")
    func pl134() throws {
        // U: KB(0..2;3..5); findKuratowskiSubgraph() → K₃,₃: edges [0, 1, 2, 3, 4, 5, 6, 7, 8]; branch vertices [0, 1, 2, 3, 4, 5]
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: [UndirectedEdge(0, 3),
            UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(witness.branchVertices == [0, 1, 2, 3, 4, 5])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-135 K5 subdivided: findKuratowskiSubgraph()")
    func pl135() throws {
        // U: sd(K(5)); findKuratowskiSubgraph() → K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]; branch vertices [0, 1, 2, 3, 4]
        let graph = Pseudograph<Int>(vertices: 0 ..< 15, edges: [UndirectedEdge(0, 5), UndirectedEdge(5, 1),
            UndirectedEdge(0, 6), UndirectedEdge(6, 2), UndirectedEdge(0, 7), UndirectedEdge(7, 3),
            UndirectedEdge(0, 8), UndirectedEdge(8, 4), UndirectedEdge(1, 9), UndirectedEdge(9, 2),
            UndirectedEdge(1, 10), UndirectedEdge(10, 3), UndirectedEdge(1, 11), UndirectedEdge(11, 4),
            UndirectedEdge(2, 12), UndirectedEdge(12, 3), UndirectedEdge(2, 13), UndirectedEdge(13, 4),
            UndirectedEdge(3, 14), UndirectedEdge(14, 4)])
        #expect(graph.vertexCount == 15 && graph.edgeCount == 20)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k5)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19])
        #expect(witness.branchVertices == [0, 1, 2, 3, 4])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-136 K3,3 subdivided: findKuratowskiSubgraph()")
    func pl136() throws {
        // U: sd(KB(0..2;3..5)); findKuratowskiSubgraph() → K₃,₃: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17]; branch vertices [0, 1, 2, 3, 4, 5]
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14], edges: [UndirectedEdge(0, 6),
            UndirectedEdge(6, 3), UndirectedEdge(0, 7), UndirectedEdge(7, 4), UndirectedEdge(0, 8),
            UndirectedEdge(8, 5), UndirectedEdge(1, 9), UndirectedEdge(9, 3), UndirectedEdge(1, 10),
            UndirectedEdge(10, 4), UndirectedEdge(1, 11), UndirectedEdge(11, 5), UndirectedEdge(2, 12),
            UndirectedEdge(12, 3), UndirectedEdge(2, 13), UndirectedEdge(13, 4), UndirectedEdge(2, 14),
            UndirectedEdge(14, 5)])
        #expect(graph.vertexCount == 15 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2, 6, 7, 8, 9, 10, 11, 12, 13, 14])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17])
        #expect(witness.branchVertices == [0, 1, 2, 3, 4, 5])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-137 K5 with a pendant path: findKuratowskiSubgraph()")
    func pl137() throws {
        // U: K(5), 4-5, 5-6; findKuratowskiSubgraph() → K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [0, 1, 2, 3, 4]
        let graph = Pseudograph<Int>(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 6)])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k5)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(witness.branchVertices == [0, 1, 2, 3, 4])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-138 K4 and a disjoint K5: findKuratowskiSubgraph()")
    func pl138() throws {
        // U: K(4), K(4..8); findKuratowskiSubgraph() → K₅: edges [6, 7, 8, 9, 10, 11, 12, 13, 14, 15]; branch vertices [4, 5, 6, 7, 8]
        let graph = Pseudograph<Int>(vertices: 0 ..< 9, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 7), UndirectedEdge(4, 8),
            UndirectedEdge(5, 6), UndirectedEdge(5, 7), UndirectedEdge(5, 8), UndirectedEdge(6, 7),
            UndirectedEdge(6, 8), UndirectedEdge(7, 8)])
        #expect(graph.vertexCount == 9 && graph.edgeCount == 16)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k5)
        #expect(witness.edges == [6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
        #expect(witness.branchVertices == [4, 5, 6, 7, 8])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-139 K5 with loops: findKuratowskiSubgraph()")
    func pl139() throws {
        // U: K(5), 0-0, 1-1, 2-2, 3-3, 4-4; findKuratowskiSubgraph() → K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [0, 1, 2, 3, 4]
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4),
            UndirectedEdge(0, 0), UndirectedEdge(1, 1), UndirectedEdge(2, 2), UndirectedEdge(3, 3),
            UndirectedEdge(4, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k5)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(witness.branchVertices == [0, 1, 2, 3, 4])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-140 K3,3 with every edge doubled: findKuratowskiSubgraph()")
    func pl140() throws {
        // U: 0=3, 0=4, 0=5, 1=3, 1=4, 1=5, 2=3, 2=4, 2=5; findKuratowskiSubgraph() → some K₃,₃ subdivision (not unique; the graph has no K₅ subdivision)
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: [UndirectedEdge(0, 3),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 4), UndirectedEdge(0, 5),
            UndirectedEdge(0, 5), UndirectedEdge(1, 3), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(1, 5), UndirectedEdge(2, 3),
            UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 4), UndirectedEdge(2, 5),
            UndirectedEdge(2, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-141 K3,3 plus an edge inside a side: findKuratowskiSubgraph()")
    func pl141() throws {
        // U: KB(0..2;3..5), 0-1; findKuratowskiSubgraph() → K₃,₃: edges [0, 1, 2, 3, 4, 5, 6, 7, 8]; branch vertices [0, 1, 2, 3, 4, 5]
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: [UndirectedEdge(0, 3),
            UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(2, 5),
            UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 1, 2])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        #expect(witness.branchVertices == [0, 1, 2, 3, 4, 5])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-142 K6: both kinds: findKuratowskiSubgraph()")
    func pl142() throws {
        // U: K(6); findKuratowskiSubgraph() → some K₅ or K₃,₃ subdivision (one of 76; kind not pinned)
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 2),
            UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(2, 3),
            UndirectedEdge(2, 4), UndirectedEdge(2, 5), UndirectedEdge(3, 4), UndirectedEdge(3, 5),
            UndirectedEdge(4, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-143 K3,4: findKuratowskiSubgraph()")
    func pl143() throws {
        // U: KB(0..2;3..6); findKuratowskiSubgraph() → some K₃,₃ subdivision (one of 4; the graph has no K₅ subdivision)
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 6, 1, 2], edges: [UndirectedEdge(0, 3),
            UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(0, 6), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(1, 5), UndirectedEdge(1, 6), UndirectedEdge(2, 3),
            UndirectedEdge(2, 4), UndirectedEdge(2, 5), UndirectedEdge(2, 6)])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 3, 4, 5, 6, 1, 2])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-144 Petersen graph: findKuratowskiSubgraph()")
    func pl144() throws {
        // U: nx(petersen); findKuratowskiSubgraph() → some K₃,₃ subdivision (one of 25; the graph has no K₅ subdivision)
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 4),
            UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6), UndirectedEdge(2, 3),
            UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9),
            UndirectedEdge(5, 7), UndirectedEdge(5, 8), UndirectedEdge(6, 8), UndirectedEdge(6, 9),
            UndirectedEdge(7, 9)])
        #expect(graph.vertexCount == 10 && graph.edgeCount == 15)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-145 Wagner graph: findKuratowskiSubgraph()")
    func pl145() throws {
        // U: C(0..7), 0-4, 1-5, 2-6, 3-7; findKuratowskiSubgraph() → some K₃,₃ subdivision (one of 4; the graph has no K₅ subdivision)
        let graph = Pseudograph<Int>(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 6),
            UndirectedEdge(6, 7), UndirectedEdge(7, 0), UndirectedEdge(0, 4), UndirectedEdge(1, 5),
            UndirectedEdge(2, 6), UndirectedEdge(3, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-146 Heawood graph: findKuratowskiSubgraph()")
    func pl146() throws {
        // U: nx(heawood); findKuratowskiSubgraph() → some K₃,₃ subdivision (not unique; the graph has no K₅ subdivision)
        let graph = Pseudograph<Int>(vertices: 0 ..< 14, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 13),
            UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 10), UndirectedEdge(2, 3),
            UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 12), UndirectedEdge(4, 5),
            UndirectedEdge(4, 9), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(6, 11),
            UndirectedEdge(7, 8), UndirectedEdge(8, 9), UndirectedEdge(8, 13), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11), UndirectedEdge(11, 12), UndirectedEdge(12, 13)])
        #expect(graph.vertexCount == 14 && graph.edgeCount == 21)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-147 K4,4: findKuratowskiSubgraph()")
    func pl147() throws {
        // U: KB(0..3;4..7); findKuratowskiSubgraph() → some K₃,₃ subdivision (one of 160; the graph has no K₅ subdivision)
        let graph = Pseudograph<Int>(vertices: [0, 4, 5, 6, 7, 1, 2, 3], edges: [UndirectedEdge(0, 4),
            UndirectedEdge(0, 5), UndirectedEdge(0, 6), UndirectedEdge(0, 7), UndirectedEdge(1, 4),
            UndirectedEdge(1, 5), UndirectedEdge(1, 6), UndirectedEdge(1, 7), UndirectedEdge(2, 4),
            UndirectedEdge(2, 5), UndirectedEdge(2, 6), UndirectedEdge(2, 7), UndirectedEdge(3, 4),
            UndirectedEdge(3, 5), UndirectedEdge(3, 6), UndirectedEdge(3, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 16)
        #expect(Array(graph.vertices) == [0, 4, 5, 6, 7, 1, 2, 3])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k33)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-148 Q4: findKuratowskiSubgraph()")
    func pl148() throws {
        // U: Q(4); findKuratowskiSubgraph() → some K₅ or K₃,₃ subdivision (not unique; kind not pinned)
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 2, 0, 4, 0, 8, 1, 3, 1, 5, 1, 9, 2, 3, 2, 6, 2, 10, 3, 7, 3, 11, 4, 5,
            4, 6, 4, 12, 5, 7, 5, 13, 6, 7, 6, 14, 7, 15, 8, 9, 8, 10, 8, 12, 9, 11, 9, 13, 10, 11, 10, 14,
            11, 15, 12, 13, 12, 14, 13, 15, 14, 15]
        let graph = Pseudograph<Int>(vertices: 0 ..< 16, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 16 && graph.edgeCount == 32)
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-149 maximal planar plus one edge: findKuratowskiSubgraph()")
    func pl149() throws {
        // U: tri(30,1), 3-4; findKuratowskiSubgraph() → some K₅ or K₃,₃ subdivision (not unique; kind not pinned)
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 2, 1, 2, 0, 3, 1, 3, 2, 3, 0, 4, 1, 4, 2, 4, 0, 5, 1, 5, 3, 5, 1, 6,
            3, 6, 5, 6, 1, 7, 2, 7, 4, 7, 1, 8, 4, 8, 7, 8, 2, 9, 4, 9, 7, 9, 1, 10, 3, 10, 6, 10, 0, 11,
            2, 11, 3, 11, 1, 12, 3, 12, 10, 12, 0, 13, 2, 13, 4, 13, 2, 14, 4, 14, 9, 14, 1, 15, 2, 15,
            7, 15, 4, 16, 7, 16, 8, 16, 4, 17, 7, 17, 9, 17, 4, 18, 7, 18, 16, 18, 3, 19, 6, 19, 10, 19,
            3, 20, 10, 20, 19, 20, 4, 21, 9, 21, 14, 21, 0, 22, 2, 22, 13, 22, 4, 23, 9, 23, 17, 23, 0, 24,
            1, 24, 4, 24, 7, 25, 16, 25, 18, 25, 2, 26, 3, 26, 11, 26, 0, 27, 3, 27, 11, 27, 3, 28, 10, 28,
            12, 28, 1, 29, 3, 29, 12, 29, 3, 4]
        let graph = Pseudograph<Int>(vertices: 0 ..< 30, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 30 && graph.edgeCount == 85)
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-150 two K5s sharing a vertex: findKuratowskiSubgraph()")
    func pl150() throws {
        // U: K(5), K(4..8); findKuratowskiSubgraph() → some K₅ subdivision (one of 2; the graph has no K₃,₃ subdivision)
        let graph = Pseudograph<Int>(vertices: 0 ..< 9, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 7), UndirectedEdge(4, 8),
            UndirectedEdge(5, 6), UndirectedEdge(5, 7), UndirectedEdge(5, 8), UndirectedEdge(6, 7),
            UndirectedEdge(6, 8), UndirectedEdge(7, 8)])
        #expect(graph.vertexCount == 9 && graph.edgeCount == 20)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k5)
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }

    @Test("PL-151 K5 with vertices out of order: findKuratowskiSubgraph()")
    func pl151() throws {
        // U: [4, 2, 0, 3, 1] K(5); findKuratowskiSubgraph() → K₅: edges [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]; branch vertices [4, 2, 0, 3, 1]
        let graph = Pseudograph<Int>(vertices: [4, 2, 0, 3, 1], edges: [UndirectedEdge(0, 1),
            UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2),
            UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4),
            UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [4, 2, 0, 3, 1])
        let witness = try #require(graph.findKuratowskiSubgraph())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Edges: ascending positions of the graph, no loop, no two copies of one pair.
        #expect(witness.edges == witness.edges.sorted() && Set(witness.edges).count == witness.edges.count)
        #expect(witness.edges.allSatisfy { graph.edges.indices.contains($0) && graph.edges[$0].u != graph.edges[$0].v })
        #expect(Set(witness.edges.map { Set([graph.edges[$0].u, graph.edges[$0].v]) }).count == witness.edges.count)
        // Branch vertices: K₅ five in vertices order; K₃,₃ the side holding the first, then the other,
        // each in vertices order. Paths: one per pair (K₃,₃: across), i < j lexicographic.
        let branch = witness.branchVertices
        let order = branch.map { indexOf[$0]! }
        var pairs: [(Int, Int)] = []
        switch witness.kind {
        case .k5:
            #expect(branch.count == 5 && order == order.sorted() && witness.paths.count == 10)
            for i in 0 ..< 5 { for j in i + 1 ..< 5 { pairs.append((i, j)) } }
        case .k33:
            #expect(branch.count == 6 && witness.paths.count == 9)
            #expect(order.count == 6 && order[0] == order.min() && Array(order[0 ..< 3]) == order[0 ..< 3].sorted() && Array(order[3...]) == order[3...].sorted())
            for i in 0 ..< 3 { for j in 3 ..< 6 { pairs.append((i, j)) } }
        }
        #expect(Set(branch).count == branch.count && branch.allSatisfy { graph.contains($0) })
        // Each path joins its pair through the graph's edges; inner vertices are not branch vertices and
        // belong to one path only; the paths use every witness edge once.
        var inner = Set<Int>()
        var used: [Int] = []
        for (path, (i, j)) in zip(witness.paths, pairs) {
            #expect(path.vertices.first == branch[i] && path.vertices.last == branch[j], "path \(i)–\(j)")
            #expect(path.edges.count == path.vertices.count - 1)
            for (k, p) in path.edges.enumerated() {
                #expect(Set([graph.edges[p].u, graph.edges[p].v]) == Set([path.vertices[k], path.vertices[k + 1]]), "path \(i)–\(j) step \(k)")
            }
            for v in path.vertices.dropFirst().dropLast() {
                #expect(!branch.contains(v) && inner.insert(v).inserted, "inner vertex \(v)")
            }
            used += path.edges
        }
        #expect(used.sorted() == witness.edges)
        #expect(witness.kind == .k5)
        #expect(witness.edges == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9])
        #expect(witness.branchVertices == [4, 2, 0, 3, 1])
        // A second call gives the same witness.
        let again = try #require(graph.findKuratowskiSubgraph())
        #expect(again.kind == witness.kind && again.edges == witness.edges && again.branchVertices == witness.branchVertices && again.paths == witness.paths)
        #expect(!graph.isPlanar && graph.planarEmbedding() == nil)
        #expect(!witness.description.isEmpty)
    }
}
