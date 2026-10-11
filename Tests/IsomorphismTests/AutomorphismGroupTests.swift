// Phase 2 (catalog IS-182 – IS-233): orders and orbits of automorphismGroup(), generators
// checked to be automorphisms whose orbits are `orbits`. Written only with --phase2.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Automorphism group (phase 2)")
struct AutomorphismGroupTests {
    @Test("IS-182 empty graph: order")
    func is182() {
        // `U:`; `automorphismGroup().order` ⇒ 1
        let graph = Pseudograph<Int>()
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 1)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-183 empty graph: orbits")
    func is183() {
        // `U:`; `automorphismGroup().orbits` ⇒ (none)
        let graph = Pseudograph<Int>()
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-184 K1: order")
    func is184() {
        // `U: [0]`; `automorphismGroup().order` ⇒ 1
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 1))
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 1)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-185 K1: orbits")
    func is185() {
        // `U: [0]`; `automorphismGroup().orbits` ⇒ {0}
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 1))
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-186 P5: order")
    func is186() {
        // `U: P(0,1,2,3,4)`; `automorphismGroup().order` ⇒ 2
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 2)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 2)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-187 P5: orbits")
    func is187() {
        // `U: P(0,1,2,3,4)`; `automorphismGroup().orbits` ⇒ {0,4} {1,3} {2}
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 4], [1, 3], [2]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 2)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-188 K2,3: order")
    func is188() {
        // `U: KB(0..1;2..4)`; `automorphismGroup().order` ⇒ 12
        let graph = Pseudograph<Int>(vertices: [0, 2, 3, 4, 1], edges: [UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 12)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 12)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-189 K2,3: orbits")
    func is189() {
        // `U: KB(0..1;2..4)`; `automorphismGroup().orbits` ⇒ {0,1} {2,3,4}
        let graph = Pseudograph<Int>(vertices: [0, 2, 3, 4, 1], edges: [UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1], [2, 3, 4]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 12)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-190 K3,3: order")
    func is190() {
        // `U: KB(0..2;3..5)`; `automorphismGroup().order` ⇒ 72
        let graphEdges: [[Int]] = [
            [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]
        ]
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 72)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 72)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-191 K3,3: orbits")
    func is191() {
        // `U: KB(0..2;3..5)`; `automorphismGroup().orbits` ⇒ {0,3,4,5,1,2}
        let graphEdges: [[Int]] = [
            [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]
        ]
        let graph = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 3, 4, 5, 1, 2]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 72)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-192 Petersen: order")
    func is192() {
        // `U: nx(petersen)`; `automorphismGroup().order` ⇒ 120
        let graphEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 120)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 120)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-193 Petersen: orbits")
    func is193() {
        // `U: nx(petersen)`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6,7,8,9}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 120)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-194 Frucht: order")
    func is194() {
        // `U: nx(frucht)`; `automorphismGroup().order` ⇒ 1
        let graphEdges: [[Int]] = [
            [0, 1], [0, 6], [0, 7], [1, 2], [1, 7], [2, 3], [2, 8], [3, 4], [3, 9], [4, 5], [4, 9], [5, 6],
            [5, 10], [6, 10], [7, 11], [8, 11], [8, 9], [10, 11]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 1)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-195 Frucht: orbits")
    func is195() {
        // `U: nx(frucht)`; `automorphismGroup().orbits` ⇒ {0} {1} {2} {3} {4} {5} {6} {7} {8} {9} {10} {11}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 6], [0, 7], [1, 2], [1, 7], [2, 3], [2, 8], [3, 4], [3, 9], [4, 5], [4, 9], [5, 6],
            [5, 10], [6, 10], [7, 11], [8, 11], [8, 9], [10, 11]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 12), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-196 Heawood: order")
    func is196() {
        // `U: nx(heawood)`; `automorphismGroup().order` ⇒ 336
        let graphEdges: [[Int]] = [
            [0, 1], [0, 13], [0, 5], [1, 2], [1, 10], [2, 3], [2, 7], [3, 4], [3, 12], [4, 5], [4, 9], [5, 6],
            [6, 7], [6, 11], [7, 8], [8, 9], [8, 13], [9, 10], [10, 11], [11, 12], [12, 13]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 14), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 336)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 336)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-197 Heawood: orbits")
    func is197() {
        // `U: nx(heawood)`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6,7,8,9,10,11,12,13}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 13], [0, 5], [1, 2], [1, 10], [2, 3], [2, 7], [3, 4], [3, 12], [4, 5], [4, 9], [5, 6],
            [6, 7], [6, 11], [7, 8], [8, 9], [8, 13], [9, 10], [10, 11], [11, 12], [12, 13]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 14), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 336)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-198 Q3: order")
    func is198() {
        // `U: Q(3)`; `automorphismGroup().order` ⇒ 48
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 8), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 48)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 48)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-199 Q3: orbits")
    func is199() {
        // `U: Q(3)`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6,7}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 3], [1, 5], [2, 3], [2, 6], [3, 7], [4, 5], [4, 6], [5, 7], [6, 7]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 8), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6, 7]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 48)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-200 Q5: order")
    func is200() {
        // `U: Q(5)`; `automorphismGroup().order` ⇒ 3840
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [0, 8], [0, 16], [1, 3], [1, 5], [1, 9], [1, 17], [2, 3], [2, 6], [2, 10],
            [2, 18], [3, 7], [3, 11], [3, 19], [4, 5], [4, 6], [4, 12], [4, 20], [5, 7], [5, 13], [5, 21], [6, 7],
            [6, 14], [6, 22], [7, 15], [7, 23], [8, 9], [8, 10], [8, 12], [8, 24], [9, 11], [9, 13], [9, 25], [10, 11],
            [10, 14], [10, 26], [11, 15], [11, 27], [12, 13], [12, 14], [12, 28], [13, 15], [13, 29], [14, 15], [14, 30], [15, 31],
            [16, 17], [16, 18], [16, 20], [16, 24], [17, 19], [17, 21], [17, 25], [18, 19], [18, 22], [18, 26], [19, 23], [19, 27],
            [20, 21], [20, 22], [20, 28], [21, 23], [21, 29], [22, 23], [22, 30], [23, 31], [24, 25], [24, 26], [24, 28], [25, 27],
            [25, 29], [26, 27], [26, 30], [27, 31], [28, 29], [28, 30], [29, 31], [30, 31]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 32), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 3840)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 3840)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-201 Q5: orbits")
    func is201() {
        // `U: Q(5)`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [0, 8], [0, 16], [1, 3], [1, 5], [1, 9], [1, 17], [2, 3], [2, 6], [2, 10],
            [2, 18], [3, 7], [3, 11], [3, 19], [4, 5], [4, 6], [4, 12], [4, 20], [5, 7], [5, 13], [5, 21], [6, 7],
            [6, 14], [6, 22], [7, 15], [7, 23], [8, 9], [8, 10], [8, 12], [8, 24], [9, 11], [9, 13], [9, 25], [10, 11],
            [10, 14], [10, 26], [11, 15], [11, 27], [12, 13], [12, 14], [12, 28], [13, 15], [13, 29], [14, 15], [14, 30], [15, 31],
            [16, 17], [16, 18], [16, 20], [16, 24], [17, 19], [17, 21], [17, 25], [18, 19], [18, 22], [18, 26], [19, 23], [19, 27],
            [20, 21], [20, 22], [20, 28], [21, 23], [21, 29], [22, 23], [22, 30], [23, 31], [24, 25], [24, 26], [24, 28], [25, 27],
            [25, 29], [26, 27], [26, 30], [27, 31], [28, 29], [28, 30], [29, 31], [30, 31]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 32), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 3840)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-202 Shrikhande: order")
    func is202() {
        // `U: shrikhande`; `automorphismGroup().order` ⇒ 192
        let graphEdges: [[Int]] = [
            [0, 1], [0, 3], [0, 4], [0, 5], [0, 12], [0, 15], [1, 2], [1, 5], [1, 6], [1, 12], [1, 13], [2, 3],
            [2, 6], [2, 7], [2, 13], [2, 14], [3, 4], [3, 7], [3, 14], [3, 15], [4, 5], [4, 7], [4, 8], [4, 9],
            [5, 6], [5, 9], [5, 10], [6, 7], [6, 10], [6, 11], [7, 8], [7, 11], [8, 9], [8, 11], [8, 12], [8, 13],
            [9, 10], [9, 13], [9, 14], [10, 11], [10, 14], [10, 15], [11, 12], [11, 15], [12, 13], [12, 15], [13, 14], [14, 15]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 192)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 192)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-203 Shrikhande: orbits")
    func is203() {
        // `U: shrikhande`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 3], [0, 4], [0, 5], [0, 12], [0, 15], [1, 2], [1, 5], [1, 6], [1, 12], [1, 13], [2, 3],
            [2, 6], [2, 7], [2, 13], [2, 14], [3, 4], [3, 7], [3, 14], [3, 15], [4, 5], [4, 7], [4, 8], [4, 9],
            [5, 6], [5, 9], [5, 10], [6, 7], [6, 10], [6, 11], [7, 8], [7, 11], [8, 9], [8, 11], [8, 12], [8, 13],
            [9, 10], [9, 13], [9, 14], [10, 11], [10, 14], [10, 15], [11, 12], [11, 15], [12, 13], [12, 15], [13, 14], [14, 15]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 192)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-204 rook(4): order")
    func is204() {
        // `U: rook(4)`; `automorphismGroup().order` ⇒ 1152
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 8], [0, 12], [1, 2], [1, 3], [1, 5], [1, 9], [1, 13], [2, 3],
            [2, 6], [2, 10], [2, 14], [3, 7], [3, 11], [3, 15], [4, 5], [4, 6], [4, 7], [4, 8], [4, 12], [5, 6],
            [5, 7], [5, 9], [5, 13], [6, 7], [6, 10], [6, 14], [7, 11], [7, 15], [8, 9], [8, 10], [8, 11], [8, 12],
            [9, 10], [9, 11], [9, 13], [10, 11], [10, 14], [11, 15], [12, 13], [12, 14], [12, 15], [13, 14], [13, 15], [14, 15]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 1152)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1152)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-205 rook(4): orbits")
    func is205() {
        // `U: rook(4)`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 8], [0, 12], [1, 2], [1, 3], [1, 5], [1, 9], [1, 13], [2, 3],
            [2, 6], [2, 10], [2, 14], [3, 7], [3, 11], [3, 15], [4, 5], [4, 6], [4, 7], [4, 8], [4, 12], [5, 6],
            [5, 7], [5, 9], [5, 13], [6, 7], [6, 10], [6, 14], [7, 11], [7, 15], [8, 9], [8, 10], [8, 11], [8, 12],
            [9, 10], [9, 11], [9, 13], [10, 11], [10, 14], [11, 15], [12, 13], [12, 14], [12, 15], [13, 14], [13, 15], [14, 15]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 16), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1152)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-206 Paley(13): order")
    func is206() {
        // `U: paley(13)`; `automorphismGroup().order` ⇒ 78
        let graphEdges: [[Int]] = [
            [0, 1], [0, 3], [0, 4], [0, 9], [0, 10], [0, 12], [1, 2], [1, 4], [1, 5], [1, 10], [1, 11], [2, 3],
            [2, 5], [2, 6], [2, 11], [2, 12], [3, 4], [3, 6], [3, 7], [3, 12], [4, 5], [4, 7], [4, 8], [5, 6],
            [5, 8], [5, 9], [6, 7], [6, 9], [6, 10], [7, 8], [7, 10], [7, 11], [8, 9], [8, 11], [8, 12], [9, 10],
            [9, 12], [10, 11], [11, 12]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 13), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 78)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 78)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-207 Paley(13): orbits")
    func is207() {
        // `U: paley(13)`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6,7,8,9,10,11,12}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 3], [0, 4], [0, 9], [0, 10], [0, 12], [1, 2], [1, 4], [1, 5], [1, 10], [1, 11], [2, 3],
            [2, 5], [2, 6], [2, 11], [2, 12], [3, 4], [3, 6], [3, 7], [3, 12], [4, 5], [4, 7], [4, 8], [5, 6],
            [5, 8], [5, 9], [6, 7], [6, 9], [6, 10], [7, 8], [7, 10], [7, 11], [8, 9], [8, 11], [8, 12], [9, 10],
            [9, 12], [10, 11], [11, 12]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 13), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 78)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-208 Paley(29): order")
    func is208() {
        // `U: paley(29)`; `automorphismGroup().order` ⇒ 406
        let graphEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [0, 6], [0, 7], [0, 9], [0, 13], [0, 16], [0, 20], [0, 22], [0, 23], [0, 24],
            [0, 25], [0, 28], [1, 2], [1, 5], [1, 6], [1, 7], [1, 8], [1, 10], [1, 14], [1, 17], [1, 21], [1, 23],
            [1, 24], [1, 25], [1, 26], [2, 3], [2, 6], [2, 7], [2, 8], [2, 9], [2, 11], [2, 15], [2, 18], [2, 22],
            [2, 24], [2, 25], [2, 26], [2, 27], [3, 4], [3, 7], [3, 8], [3, 9], [3, 10], [3, 12], [3, 16], [3, 19],
            [3, 23], [3, 25], [3, 26], [3, 27], [3, 28], [4, 5], [4, 8], [4, 9], [4, 10], [4, 11], [4, 13], [4, 17],
            [4, 20], [4, 24], [4, 26], [4, 27], [4, 28], [5, 6], [5, 9], [5, 10], [5, 11], [5, 12], [5, 14], [5, 18],
            [5, 21], [5, 25], [5, 27], [5, 28], [6, 7], [6, 10], [6, 11], [6, 12], [6, 13], [6, 15], [6, 19], [6, 22],
            [6, 26], [6, 28], [7, 8], [7, 11], [7, 12], [7, 13], [7, 14], [7, 16], [7, 20], [7, 23], [7, 27], [8, 9],
            [8, 12], [8, 13], [8, 14], [8, 15], [8, 17], [8, 21], [8, 24], [8, 28], [9, 10], [9, 13], [9, 14], [9, 15],
            [9, 16], [9, 18], [9, 22], [9, 25], [10, 11], [10, 14], [10, 15], [10, 16], [10, 17], [10, 19], [10, 23], [10, 26],
            [11, 12], [11, 15], [11, 16], [11, 17], [11, 18], [11, 20], [11, 24], [11, 27], [12, 13], [12, 16], [12, 17], [12, 18],
            [12, 19], [12, 21], [12, 25], [12, 28], [13, 14], [13, 17], [13, 18], [13, 19], [13, 20], [13, 22], [13, 26], [14, 15],
            [14, 18], [14, 19], [14, 20], [14, 21], [14, 23], [14, 27], [15, 16], [15, 19], [15, 20], [15, 21], [15, 22], [15, 24],
            [15, 28], [16, 17], [16, 20], [16, 21], [16, 22], [16, 23], [16, 25], [17, 18], [17, 21], [17, 22], [17, 23], [17, 24],
            [17, 26], [18, 19], [18, 22], [18, 23], [18, 24], [18, 25], [18, 27], [19, 20], [19, 23], [19, 24], [19, 25], [19, 26],
            [19, 28], [20, 21], [20, 24], [20, 25], [20, 26], [20, 27], [21, 22], [21, 25], [21, 26], [21, 27], [21, 28], [22, 23],
            [22, 26], [22, 27], [22, 28], [23, 24], [23, 27], [23, 28], [24, 25], [24, 28], [25, 26], [26, 27], [27, 28]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 29), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 406)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 406)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-209 Paley(29): orbits")
    func is209() {
        // `U: paley(29)`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [0, 6], [0, 7], [0, 9], [0, 13], [0, 16], [0, 20], [0, 22], [0, 23], [0, 24],
            [0, 25], [0, 28], [1, 2], [1, 5], [1, 6], [1, 7], [1, 8], [1, 10], [1, 14], [1, 17], [1, 21], [1, 23],
            [1, 24], [1, 25], [1, 26], [2, 3], [2, 6], [2, 7], [2, 8], [2, 9], [2, 11], [2, 15], [2, 18], [2, 22],
            [2, 24], [2, 25], [2, 26], [2, 27], [3, 4], [3, 7], [3, 8], [3, 9], [3, 10], [3, 12], [3, 16], [3, 19],
            [3, 23], [3, 25], [3, 26], [3, 27], [3, 28], [4, 5], [4, 8], [4, 9], [4, 10], [4, 11], [4, 13], [4, 17],
            [4, 20], [4, 24], [4, 26], [4, 27], [4, 28], [5, 6], [5, 9], [5, 10], [5, 11], [5, 12], [5, 14], [5, 18],
            [5, 21], [5, 25], [5, 27], [5, 28], [6, 7], [6, 10], [6, 11], [6, 12], [6, 13], [6, 15], [6, 19], [6, 22],
            [6, 26], [6, 28], [7, 8], [7, 11], [7, 12], [7, 13], [7, 14], [7, 16], [7, 20], [7, 23], [7, 27], [8, 9],
            [8, 12], [8, 13], [8, 14], [8, 15], [8, 17], [8, 21], [8, 24], [8, 28], [9, 10], [9, 13], [9, 14], [9, 15],
            [9, 16], [9, 18], [9, 22], [9, 25], [10, 11], [10, 14], [10, 15], [10, 16], [10, 17], [10, 19], [10, 23], [10, 26],
            [11, 12], [11, 15], [11, 16], [11, 17], [11, 18], [11, 20], [11, 24], [11, 27], [12, 13], [12, 16], [12, 17], [12, 18],
            [12, 19], [12, 21], [12, 25], [12, 28], [13, 14], [13, 17], [13, 18], [13, 19], [13, 20], [13, 22], [13, 26], [14, 15],
            [14, 18], [14, 19], [14, 20], [14, 21], [14, 23], [14, 27], [15, 16], [15, 19], [15, 20], [15, 21], [15, 22], [15, 24],
            [15, 28], [16, 17], [16, 20], [16, 21], [16, 22], [16, 23], [16, 25], [17, 18], [17, 21], [17, 22], [17, 23], [17, 24],
            [17, 26], [18, 19], [18, 22], [18, 23], [18, 24], [18, 25], [18, 27], [19, 20], [19, 23], [19, 24], [19, 25], [19, 26],
            [19, 28], [20, 21], [20, 24], [20, 25], [20, 26], [20, 27], [21, 22], [21, 25], [21, 26], [21, 27], [21, 28], [22, 23],
            [22, 26], [22, 27], [22, 28], [23, 24], [23, 27], [23, 28], [24, 25], [24, 28], [25, 26], [26, 27], [27, 28]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 29), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 406)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-210 karate club: order")
    func is210() {
        // `U: nx(karate_club)`; `automorphismGroup().order` ⇒ 480
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 10], [0, 11], [0, 12], [0, 13],
            [0, 17], [0, 19], [0, 21], [0, 31], [1, 2], [1, 3], [1, 7], [1, 13], [1, 17], [1, 19], [1, 21], [1, 30],
            [2, 3], [2, 7], [2, 8], [2, 9], [2, 13], [2, 27], [2, 28], [2, 32], [3, 7], [3, 12], [3, 13], [4, 6],
            [4, 10], [5, 6], [5, 10], [5, 16], [6, 16], [8, 30], [8, 32], [8, 33], [9, 33], [13, 33], [14, 32], [14, 33],
            [15, 32], [15, 33], [18, 32], [18, 33], [19, 33], [20, 32], [20, 33], [22, 32], [22, 33], [23, 25], [23, 27], [23, 29],
            [23, 32], [23, 33], [24, 25], [24, 27], [24, 31], [25, 31], [26, 29], [26, 33], [27, 33], [28, 31], [28, 33], [29, 32],
            [29, 33], [30, 32], [30, 33], [31, 32], [31, 33], [32, 33]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 34), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 480)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 480)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-211 karate club: orbits")
    func is211() {
        // `U: nx(karate_club)`; `automorphismGroup().orbits` ⇒ {0} {1} {2} {3} {4,10} {5,6} {7} {8} {9} {11} {12} {13} {14,15,18,20,22} {16} {17,21} {19} {23} {24} {25} {26} {27} {28} {29} {30} {31} {32} {33}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [0, 7], [0, 8], [0, 10], [0, 11], [0, 12], [0, 13],
            [0, 17], [0, 19], [0, 21], [0, 31], [1, 2], [1, 3], [1, 7], [1, 13], [1, 17], [1, 19], [1, 21], [1, 30],
            [2, 3], [2, 7], [2, 8], [2, 9], [2, 13], [2, 27], [2, 28], [2, 32], [3, 7], [3, 12], [3, 13], [4, 6],
            [4, 10], [5, 6], [5, 10], [5, 16], [6, 16], [8, 30], [8, 32], [8, 33], [9, 33], [13, 33], [14, 32], [14, 33],
            [15, 32], [15, 33], [18, 32], [18, 33], [19, 33], [20, 32], [20, 33], [22, 32], [22, 33], [23, 25], [23, 27], [23, 29],
            [23, 32], [23, 33], [24, 25], [24, 27], [24, 31], [25, 31], [26, 29], [26, 33], [27, 33], [28, 31], [28, 33], [29, 32],
            [29, 33], [30, 32], [30, 33], [31, 32], [31, 33], [32, 33]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 34), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0], [1], [2], [3], [4, 10], [5, 6], [7], [8], [9], [11], [12], [13], [14, 15, 18, 20, 22], [16], [17, 21], [19], [23], [24], [25], [26], [27], [28], [29], [30], [31], [32], [33]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 480)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-212 Tutte graph: order")
    func is212() {
        // `U: nx(tutte)`; `automorphismGroup().order` ⇒ 3
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [1, 4], [1, 26], [2, 10], [2, 11], [3, 18], [3, 19], [4, 5], [4, 33], [5, 6],
            [5, 29], [6, 7], [6, 27], [7, 8], [7, 14], [8, 9], [8, 38], [9, 10], [9, 37], [10, 39], [11, 12], [11, 39],
            [12, 13], [12, 35], [13, 14], [13, 15], [14, 34], [15, 16], [15, 22], [16, 17], [16, 44], [17, 18], [17, 43], [18, 45],
            [19, 20], [19, 45], [20, 21], [20, 41], [21, 22], [21, 23], [22, 40], [23, 24], [23, 27], [24, 25], [24, 32], [25, 26],
            [25, 31], [26, 33], [27, 28], [28, 29], [28, 32], [29, 30], [30, 31], [30, 33], [31, 32], [34, 35], [34, 38], [35, 36],
            [36, 37], [36, 39], [37, 38], [40, 41], [40, 44], [41, 42], [42, 43], [42, 45], [43, 44]
        ]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 34, 35, 36, 37, 40, 41, 42, 43, 33, 38, 39, 44, 45, 32], edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 3)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 3)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-213 Tutte graph: orbits")
    func is213() {
        // `U: nx(tutte)`; `automorphismGroup().orbits` ⇒ {0} {1,2,3} {4,11,19} {5,12,20} {6,13,21} {7,15,23} {8,16,24} {9,17,25} {10,18,26} {14,22,27} {28,34,40} {29,35,41} {30,36,42} {31,37,43} {33,39,45} {38,44,32}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [1, 4], [1, 26], [2, 10], [2, 11], [3, 18], [3, 19], [4, 5], [4, 33], [5, 6],
            [5, 29], [6, 7], [6, 27], [7, 8], [7, 14], [8, 9], [8, 38], [9, 10], [9, 37], [10, 39], [11, 12], [11, 39],
            [12, 13], [12, 35], [13, 14], [13, 15], [14, 34], [15, 16], [15, 22], [16, 17], [16, 44], [17, 18], [17, 43], [18, 45],
            [19, 20], [19, 45], [20, 21], [20, 41], [21, 22], [21, 23], [22, 40], [23, 24], [23, 27], [24, 25], [24, 32], [25, 26],
            [25, 31], [26, 33], [27, 28], [28, 29], [28, 32], [29, 30], [30, 31], [30, 33], [31, 32], [34, 35], [34, 38], [35, 36],
            [36, 37], [36, 39], [37, 38], [40, 41], [40, 44], [41, 42], [42, 43], [42, 45], [43, 44]
        ]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 34, 35, 36, 37, 40, 41, 42, 43, 33, 38, 39, 44, 45, 32], edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0], [1, 2, 3], [4, 11, 19], [5, 12, 20], [6, 13, 21], [7, 15, 23], [8, 16, 24], [9, 17, 25], [10, 18, 26], [14, 22, 27], [28, 34, 40], [29, 35, 41], [30, 36, 42], [31, 37, 43], [33, 39, 45], [38, 44, 32]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 3)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-214 Hoffman–Singleton: order")
    func is214() {
        // `U: nx(hoffman_singleton)`; `automorphismGroup().order` ⇒ 252000
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 6], [0, 7], [0, 8], [0, 9], [1, 17], [1, 12], [1, 26], [1, 27], [1, 28],
            [1, 29], [2, 10], [2, 11], [2, 13], [2, 14], [2, 15], [2, 16], [3, 4], [3, 5], [3, 30], [3, 35], [3, 40],
            [3, 45], [4, 11], [4, 17], [4, 34], [4, 39], [4, 44], [4, 49], [5, 12], [5, 10], [5, 33], [5, 38], [5, 43],
            [5, 48], [6, 22], [6, 18], [6, 31], [6, 39], [6, 43], [6, 47], [7, 34], [7, 23], [7, 19], [7, 37], [7, 41],
            [7, 48], [8, 33], [8, 36], [8, 24], [8, 20], [8, 42], [8, 49], [9, 32], [9, 38], [9, 44], [9, 25], [9, 21],
            [9, 46], [10, 17], [10, 18], [10, 19], [10, 20], [10, 21], [11, 12], [11, 32], [11, 37], [11, 42], [11, 47], [12, 31],
            [12, 36], [12, 41], [12, 46], [13, 30], [13, 26], [13, 22], [13, 36], [13, 44], [13, 48], [14, 31], [14, 27], [14, 23],
            [14, 38], [14, 40], [14, 49], [15, 34], [15, 35], [15, 28], [15, 24], [15, 43], [15, 46], [16, 33], [16, 39], [16, 41],
            [16, 45], [16, 29], [16, 25], [17, 22], [17, 23], [17, 24], [17, 25], [18, 32], [18, 26], [18, 35], [18, 41], [18, 49],
            [19, 30], [19, 27], [19, 39], [19, 42], [19, 46], [20, 31], [20, 37], [20, 28], [20, 44], [20, 45], [21, 34], [21, 36],
            [21, 40], [21, 47], [21, 29], [22, 33], [22, 37], [22, 40], [22, 46], [23, 32], [23, 36], [23, 43], [23, 45], [24, 30],
            [24, 38], [24, 41], [24, 47], [25, 31], [25, 35], [25, 42], [25, 48], [26, 34], [26, 38], [26, 42], [26, 45], [27, 33],
            [27, 35], [27, 44], [27, 47], [28, 32], [28, 39], [28, 40], [28, 48], [29, 30], [29, 37], [29, 43], [29, 49], [30, 31],
            [30, 32], [31, 34], [32, 33], [33, 34], [35, 36], [35, 37], [36, 39], [37, 38], [38, 39], [40, 41], [40, 42], [41, 44],
            [42, 43], [43, 44], [45, 46], [45, 47], [46, 49], [47, 48], [48, 49]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 50), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 252000)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 252000)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-215 Les Misérables: order")
    func is215() {
        // `U: nx(les_miserables)`; `automorphismGroup().order` ⇒ 3344302080000
        let graphEdges: [[String]] = [
            ["Napoleon", "Myriel"], ["Myriel", "MlleBaptistine"], ["Myriel", "MmeMagloire"], ["Myriel", "CountessDeLo"], ["Myriel", "Geborand"], ["Myriel", "Champtercier"], ["Myriel", "Cravatte"], ["Myriel", "Count"], ["Myriel", "OldMan"], ["Myriel", "Valjean"], ["MlleBaptistine", "MmeMagloire"], ["MlleBaptistine", "Valjean"],
            ["MmeMagloire", "Valjean"], ["Valjean", "Labarre"], ["Valjean", "Marguerite"], ["Valjean", "MmeDeR"], ["Valjean", "Isabeau"], ["Valjean", "Gervais"], ["Valjean", "Fantine"], ["Valjean", "MmeThenardier"], ["Valjean", "Thenardier"], ["Valjean", "Cosette"], ["Valjean", "Javert"], ["Valjean", "Fauchelevent"],
            ["Valjean", "Bamatabois"], ["Valjean", "Simplice"], ["Valjean", "Scaufflaire"], ["Valjean", "Woman1"], ["Valjean", "Judge"], ["Valjean", "Champmathieu"], ["Valjean", "Brevet"], ["Valjean", "Chenildieu"], ["Valjean", "Cochepaille"], ["Valjean", "Woman2"], ["Valjean", "MotherInnocent"], ["Valjean", "Gavroche"],
            ["Valjean", "Gillenormand"], ["Valjean", "MlleGillenormand"], ["Valjean", "Marius"], ["Valjean", "Enjolras"], ["Valjean", "Bossuet"], ["Valjean", "Gueulemer"], ["Valjean", "Babet"], ["Valjean", "Claquesous"], ["Valjean", "Montparnasse"], ["Valjean", "Toussaint"], ["Marguerite", "Fantine"], ["Listolier", "Tholomyes"],
            ["Listolier", "Fameuil"], ["Listolier", "Blacheville"], ["Listolier", "Favourite"], ["Listolier", "Dahlia"], ["Listolier", "Zephine"], ["Listolier", "Fantine"], ["Tholomyes", "Fameuil"], ["Tholomyes", "Blacheville"], ["Tholomyes", "Favourite"], ["Tholomyes", "Dahlia"], ["Tholomyes", "Zephine"], ["Tholomyes", "Fantine"],
            ["Tholomyes", "Cosette"], ["Tholomyes", "Marius"], ["Fameuil", "Blacheville"], ["Fameuil", "Favourite"], ["Fameuil", "Dahlia"], ["Fameuil", "Zephine"], ["Fameuil", "Fantine"], ["Blacheville", "Favourite"], ["Blacheville", "Dahlia"], ["Blacheville", "Zephine"], ["Blacheville", "Fantine"], ["Favourite", "Dahlia"],
            ["Favourite", "Zephine"], ["Favourite", "Fantine"], ["Dahlia", "Zephine"], ["Dahlia", "Fantine"], ["Zephine", "Fantine"], ["Fantine", "MmeThenardier"], ["Fantine", "Thenardier"], ["Fantine", "Javert"], ["Fantine", "Bamatabois"], ["Fantine", "Perpetue"], ["Fantine", "Simplice"], ["MmeThenardier", "Thenardier"],
            ["MmeThenardier", "Cosette"], ["MmeThenardier", "Javert"], ["MmeThenardier", "Eponine"], ["MmeThenardier", "Anzelma"], ["MmeThenardier", "Magnon"], ["MmeThenardier", "Gueulemer"], ["MmeThenardier", "Babet"], ["MmeThenardier", "Claquesous"], ["Thenardier", "Cosette"], ["Thenardier", "Javert"], ["Thenardier", "Pontmercy"], ["Thenardier", "Boulatruelle"],
            ["Thenardier", "Eponine"], ["Thenardier", "Anzelma"], ["Thenardier", "Gavroche"], ["Thenardier", "Marius"], ["Thenardier", "Gueulemer"], ["Thenardier", "Babet"], ["Thenardier", "Claquesous"], ["Thenardier", "Montparnasse"], ["Thenardier", "Brujon"], ["Cosette", "Javert"], ["Cosette", "Woman2"], ["Cosette", "Gillenormand"],
            ["Cosette", "MlleGillenormand"], ["Cosette", "LtGillenormand"], ["Cosette", "Marius"], ["Cosette", "Toussaint"], ["Javert", "Fauchelevent"], ["Javert", "Bamatabois"], ["Javert", "Simplice"], ["Javert", "Woman1"], ["Javert", "Woman2"], ["Javert", "Gavroche"], ["Javert", "Enjolras"], ["Javert", "Gueulemer"],
            ["Javert", "Babet"], ["Javert", "Claquesous"], ["Javert", "Montparnasse"], ["Javert", "Toussaint"], ["Fauchelevent", "MotherInnocent"], ["Fauchelevent", "Gribier"], ["Bamatabois", "Judge"], ["Bamatabois", "Champmathieu"], ["Bamatabois", "Brevet"], ["Bamatabois", "Chenildieu"], ["Bamatabois", "Cochepaille"], ["Perpetue", "Simplice"],
            ["Judge", "Champmathieu"], ["Judge", "Brevet"], ["Judge", "Chenildieu"], ["Judge", "Cochepaille"], ["Champmathieu", "Brevet"], ["Champmathieu", "Chenildieu"], ["Champmathieu", "Cochepaille"], ["Brevet", "Chenildieu"], ["Brevet", "Cochepaille"], ["Chenildieu", "Cochepaille"], ["Pontmercy", "MmePontmercy"], ["Pontmercy", "Marius"],
            ["Eponine", "Anzelma"], ["Eponine", "Marius"], ["Eponine", "Mabeuf"], ["Eponine", "Courfeyrac"], ["Eponine", "Gueulemer"], ["Eponine", "Babet"], ["Eponine", "Claquesous"], ["Eponine", "Montparnasse"], ["Eponine", "Brujon"], ["MmeBurgon", "Jondrette"], ["MmeBurgon", "Gavroche"], ["Gavroche", "Marius"],
            ["Gavroche", "Mabeuf"], ["Gavroche", "Enjolras"], ["Gavroche", "Combeferre"], ["Gavroche", "Prouvaire"], ["Gavroche", "Feuilly"], ["Gavroche", "Courfeyrac"], ["Gavroche", "Bahorel"], ["Gavroche", "Bossuet"], ["Gavroche", "Joly"], ["Gavroche", "Grantaire"], ["Gavroche", "Gueulemer"], ["Gavroche", "Babet"],
            ["Gavroche", "Montparnasse"], ["Gavroche", "Child1"], ["Gavroche", "Child2"], ["Gavroche", "Brujon"], ["Gavroche", "MmeHucheloup"], ["Gillenormand", "Magnon"], ["Gillenormand", "MlleGillenormand"], ["Gillenormand", "LtGillenormand"], ["Gillenormand", "Marius"], ["Gillenormand", "BaronessT"], ["MlleGillenormand", "MmePontmercy"], ["MlleGillenormand", "MlleVaubois"],
            ["MlleGillenormand", "LtGillenormand"], ["MlleGillenormand", "Marius"], ["LtGillenormand", "Marius"], ["Marius", "BaronessT"], ["Marius", "Mabeuf"], ["Marius", "Enjolras"], ["Marius", "Combeferre"], ["Marius", "Feuilly"], ["Marius", "Courfeyrac"], ["Marius", "Bahorel"], ["Marius", "Bossuet"], ["Marius", "Joly"],
            ["Mabeuf", "Enjolras"], ["Mabeuf", "Combeferre"], ["Mabeuf", "Feuilly"], ["Mabeuf", "Courfeyrac"], ["Mabeuf", "Bahorel"], ["Mabeuf", "Bossuet"], ["Mabeuf", "Joly"], ["Mabeuf", "MotherPlutarch"], ["Enjolras", "Combeferre"], ["Enjolras", "Prouvaire"], ["Enjolras", "Feuilly"], ["Enjolras", "Courfeyrac"],
            ["Enjolras", "Bahorel"], ["Enjolras", "Bossuet"], ["Enjolras", "Joly"], ["Enjolras", "Grantaire"], ["Enjolras", "Claquesous"], ["Enjolras", "MmeHucheloup"], ["Combeferre", "Prouvaire"], ["Combeferre", "Feuilly"], ["Combeferre", "Courfeyrac"], ["Combeferre", "Bahorel"], ["Combeferre", "Bossuet"], ["Combeferre", "Joly"],
            ["Combeferre", "Grantaire"], ["Prouvaire", "Feuilly"], ["Prouvaire", "Courfeyrac"], ["Prouvaire", "Bahorel"], ["Prouvaire", "Bossuet"], ["Prouvaire", "Joly"], ["Prouvaire", "Grantaire"], ["Feuilly", "Courfeyrac"], ["Feuilly", "Bahorel"], ["Feuilly", "Bossuet"], ["Feuilly", "Joly"], ["Feuilly", "Grantaire"],
            ["Courfeyrac", "Bahorel"], ["Courfeyrac", "Bossuet"], ["Courfeyrac", "Joly"], ["Courfeyrac", "Grantaire"], ["Courfeyrac", "MmeHucheloup"], ["Bahorel", "Bossuet"], ["Bahorel", "Joly"], ["Bahorel", "Grantaire"], ["Bahorel", "MmeHucheloup"], ["Bossuet", "Joly"], ["Bossuet", "Grantaire"], ["Bossuet", "MmeHucheloup"],
            ["Joly", "Grantaire"], ["Joly", "MmeHucheloup"], ["Grantaire", "MmeHucheloup"], ["Gueulemer", "Babet"], ["Gueulemer", "Claquesous"], ["Gueulemer", "Montparnasse"], ["Gueulemer", "Brujon"], ["Babet", "Claquesous"], ["Babet", "Montparnasse"], ["Babet", "Brujon"], ["Claquesous", "Montparnasse"], ["Claquesous", "Brujon"],
            ["Montparnasse", "Brujon"], ["Child1", "Child2"]
        ]
        let graph = Pseudograph<String>(vertices: ["Napoleon", "Myriel", "MlleBaptistine", "MmeMagloire", "CountessDeLo", "Geborand", "Champtercier", "Cravatte", "Count", "OldMan", "Valjean", "Labarre", "Marguerite", "MmeDeR", "Isabeau", "Gervais", "Listolier", "Tholomyes", "Fameuil", "Blacheville", "Favourite", "Dahlia", "Zephine", "Fantine", "MmeThenardier", "Thenardier", "Cosette", "Javert", "Fauchelevent", "Bamatabois", "Perpetue", "Simplice", "Scaufflaire", "Woman1", "Judge", "Champmathieu", "Brevet", "Chenildieu", "Cochepaille", "Pontmercy", "Boulatruelle", "Eponine", "Anzelma", "Woman2", "MotherInnocent", "Gribier", "MmeBurgon", "Jondrette", "Gavroche", "Gillenormand", "Magnon", "MlleGillenormand", "MmePontmercy", "MlleVaubois", "LtGillenormand", "Marius", "BaronessT", "Mabeuf", "Enjolras", "Combeferre", "Prouvaire", "Feuilly", "Courfeyrac", "Bahorel", "Bossuet", "Joly", "Grantaire", "MotherPlutarch", "Gueulemer", "Babet", "Claquesous", "Montparnasse", "Toussaint", "Child1", "Child2", "Brujon", "MmeHucheloup"], edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 3344302080000)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 3344302080000)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-216 25 isolated vertices: order")
    func is216() {
        // `U: E(25)`; `automorphismGroup().order` ⇒ 15511210043330985984000000
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 25))
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 1.5511210043330986e+25)
        // The stabiliser chain's lengths multiply to the order.
        #expect(abs(group.basicOrbitLengths.reduce(1.0) { $0 * Double($1) } / group.order - 1) < 1e-12)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-217 CFI over K4: order")
    func is217() {
        // `U: cfi(K(4))`; `automorphismGroup().order` ⇒ 192
        let graphEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 14], [5, 15], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 192)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 192)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-218 CFI over K4: orbits")
    func is218() {
        // `U: cfi(K(4))`; `automorphismGroup().orbits` ⇒ {0,1,2,3,10,11,12,13,20,21,22,23,30,31,32,33} {4,5,6,7,8,9,14,15,16,17,18,19,24,25,26,27,28,29,34,35,36,37,38,39}
        let graphEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 14], [5, 15], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 10, 11, 12, 13, 20, 21, 22, 23, 30, 31, 32, 33], [4, 5, 6, 7, 8, 9, 14, 15, 16, 17, 18, 19, 24, 25, 26, 27, 28, 29, 34, 35, 36, 37, 38, 39]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 192)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-219 twisted CFI over K4: order")
    func is219() {
        // `U: cfi~(K(4))`; `automorphismGroup().order` ⇒ 192
        let graphEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 15], [5, 14], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 192)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 192)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-220 twisted CFI over K4: orbits")
    func is220() {
        // `U: cfi~(K(4))`; `automorphismGroup().orbits` ⇒ {0,1,2,3,10,11,12,13,20,21,22,23,30,31,32,33} {4,5,6,7,8,9,14,15,16,17,18,19,24,25,26,27,28,29,34,35,36,37,38,39}
        let graphEdges: [[Int]] = [
            [0, 4], [0, 6], [0, 8], [1, 5], [1, 7], [1, 8], [2, 5], [2, 6], [2, 9], [3, 4], [3, 7], [3, 9],
            [10, 14], [10, 16], [10, 18], [11, 15], [11, 17], [11, 18], [12, 15], [12, 16], [12, 19], [13, 14], [13, 17], [13, 19],
            [20, 24], [20, 26], [20, 28], [21, 25], [21, 27], [21, 28], [22, 25], [22, 26], [22, 29], [23, 24], [23, 27], [23, 29],
            [30, 34], [30, 36], [30, 38], [31, 35], [31, 37], [31, 38], [32, 35], [32, 36], [32, 39], [33, 34], [33, 37], [33, 39],
            [4, 15], [5, 14], [6, 24], [7, 25], [8, 34], [9, 35], [16, 26], [17, 27], [18, 36], [19, 37], [28, 38], [29, 39]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 40), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 10, 11, 12, 13, 20, 21, 22, 23, 30, 31, 32, 33], [4, 5, 6, 7, 8, 9, 14, 15, 16, 17, 18, 19, 24, 25, 26, 27, 28, 29, 34, 35, 36, 37, 38, 39]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 192)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-221 directed C3: order")
    func is221() {
        // `D: C(0,1,2)`; `automorphismGroup().order` ⇒ 3
        let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 3)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 3)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.source, $0.target] }
            let moved = graph.edges.map { [generator.image(of: $0.source), generator.image(of: $0.target)] }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-222 directed C3: orbits")
    func is222() {
        // `D: C(0,1,2)`; `automorphismGroup().orbits` ⇒ {0,1,2}
        let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 3)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.source, $0.target] }
            let moved = graph.edges.map { [generator.image(of: $0.source), generator.image(of: $0.target)] }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-223 Paley tournament 7: order")
    func is223() {
        // `D: tpaley(7)`; `automorphismGroup().order` ⇒ 21
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 2], [1, 3], [1, 5], [2, 3], [2, 4], [2, 6], [3, 0], [3, 4], [3, 5],
            [4, 1], [4, 5], [4, 6], [5, 0], [5, 2], [5, 6], [6, 0], [6, 1], [6, 3]
        ]
        let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< 7), edges: graphEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 21)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 21)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.source, $0.target] }
            let moved = graph.edges.map { [generator.image(of: $0.source), generator.image(of: $0.target)] }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-224 Paley tournament 7: orbits")
    func is224() {
        // `D: tpaley(7)`; `automorphismGroup().orbits` ⇒ {0,1,2,3,4,5,6}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 4], [1, 2], [1, 3], [1, 5], [2, 3], [2, 4], [2, 6], [3, 0], [3, 4], [3, 5],
            [4, 1], [4, 5], [4, 6], [5, 0], [5, 2], [5, 6], [6, 0], [6, 1], [6, 3]
        ]
        let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< 7), edges: graphEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0, 1, 2, 3, 4, 5, 6]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 21)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.source, $0.target] }
            let moved = graph.edges.map { [generator.image(of: $0.source), generator.image(of: $0.target)] }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-225 transitive tournament 5: order")
    func is225() {
        // `D: tt(5)`; `automorphismGroup().order` ⇒ 1
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]
        ]
        let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< 5), edges: graphEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 1)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.source, $0.target] }
            let moved = graph.edges.map { [generator.image(of: $0.source), generator.image(of: $0.target)] }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-226 transitive tournament 5: orbits")
    func is226() {
        // `D: tt(5)`; `automorphismGroup().orbits` ⇒ {0} {1} {2} {3} {4}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]
        ]
        let graph = DirectedPseudograph<Int>(vertices: Array(0 ..< 5), edges: graphEdges.map { DirectedEdge(from: $0[0], to: $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0], [1], [2], [3], [4]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.source, $0.target] }
            let moved = graph.edges.map { [generator.image(of: $0.source), generator.image(of: $0.target)] }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-227 Les Misérables: orbits")
    func is227() {
        // `U: nx(les_miserables)`; `automorphismGroup().orbits` ⇒ {Napoleon,CountessDeLo,Geborand,Champtercier,Cravatte,Count,OldMan} {Myriel} {MlleBaptistine,MmeMagloire} {Valjean} {Labarre,MmeDeR,Isabeau,Gervais,Scaufflaire} {Marguerite} {Listolier,Fameuil,Blacheville,Favourite,Dahlia,Zephine} {Tholomyes} {Fantine} {MmeThenardier} {Thenardier} {Cosette} {Javert} {Fauchelevent} {Bamatabois} {Perpetue} {Simplice} {Woman1} {Judge,Champmathieu,Brevet,Chenildieu,Cochepaille} {Pontmercy} {Boulatruelle} {Eponine} {Anzelma} {Woman2,Toussaint} {MotherInnocent} {Gribier} {MmeBurgon} {Jondrette} {Gavroche} {Gillenormand} {Magnon} {MlleGillenormand} {MmePontmercy} {MlleVaubois} {LtGillenormand} {Marius} {BaronessT} {Mabeuf} {Enjolras} {Combeferre,Feuilly} {Prouvaire} {Courfeyrac} {Bahorel,Joly} {Bossuet} {Grantaire} {MotherPlutarch} {Gueulemer,Babet} {Claquesous} {Montparnasse} {Child1,Child2} {Brujon} {MmeHucheloup}
        let graphEdges: [[String]] = [
            ["Napoleon", "Myriel"], ["Myriel", "MlleBaptistine"], ["Myriel", "MmeMagloire"], ["Myriel", "CountessDeLo"], ["Myriel", "Geborand"], ["Myriel", "Champtercier"], ["Myriel", "Cravatte"], ["Myriel", "Count"], ["Myriel", "OldMan"], ["Myriel", "Valjean"], ["MlleBaptistine", "MmeMagloire"], ["MlleBaptistine", "Valjean"],
            ["MmeMagloire", "Valjean"], ["Valjean", "Labarre"], ["Valjean", "Marguerite"], ["Valjean", "MmeDeR"], ["Valjean", "Isabeau"], ["Valjean", "Gervais"], ["Valjean", "Fantine"], ["Valjean", "MmeThenardier"], ["Valjean", "Thenardier"], ["Valjean", "Cosette"], ["Valjean", "Javert"], ["Valjean", "Fauchelevent"],
            ["Valjean", "Bamatabois"], ["Valjean", "Simplice"], ["Valjean", "Scaufflaire"], ["Valjean", "Woman1"], ["Valjean", "Judge"], ["Valjean", "Champmathieu"], ["Valjean", "Brevet"], ["Valjean", "Chenildieu"], ["Valjean", "Cochepaille"], ["Valjean", "Woman2"], ["Valjean", "MotherInnocent"], ["Valjean", "Gavroche"],
            ["Valjean", "Gillenormand"], ["Valjean", "MlleGillenormand"], ["Valjean", "Marius"], ["Valjean", "Enjolras"], ["Valjean", "Bossuet"], ["Valjean", "Gueulemer"], ["Valjean", "Babet"], ["Valjean", "Claquesous"], ["Valjean", "Montparnasse"], ["Valjean", "Toussaint"], ["Marguerite", "Fantine"], ["Listolier", "Tholomyes"],
            ["Listolier", "Fameuil"], ["Listolier", "Blacheville"], ["Listolier", "Favourite"], ["Listolier", "Dahlia"], ["Listolier", "Zephine"], ["Listolier", "Fantine"], ["Tholomyes", "Fameuil"], ["Tholomyes", "Blacheville"], ["Tholomyes", "Favourite"], ["Tholomyes", "Dahlia"], ["Tholomyes", "Zephine"], ["Tholomyes", "Fantine"],
            ["Tholomyes", "Cosette"], ["Tholomyes", "Marius"], ["Fameuil", "Blacheville"], ["Fameuil", "Favourite"], ["Fameuil", "Dahlia"], ["Fameuil", "Zephine"], ["Fameuil", "Fantine"], ["Blacheville", "Favourite"], ["Blacheville", "Dahlia"], ["Blacheville", "Zephine"], ["Blacheville", "Fantine"], ["Favourite", "Dahlia"],
            ["Favourite", "Zephine"], ["Favourite", "Fantine"], ["Dahlia", "Zephine"], ["Dahlia", "Fantine"], ["Zephine", "Fantine"], ["Fantine", "MmeThenardier"], ["Fantine", "Thenardier"], ["Fantine", "Javert"], ["Fantine", "Bamatabois"], ["Fantine", "Perpetue"], ["Fantine", "Simplice"], ["MmeThenardier", "Thenardier"],
            ["MmeThenardier", "Cosette"], ["MmeThenardier", "Javert"], ["MmeThenardier", "Eponine"], ["MmeThenardier", "Anzelma"], ["MmeThenardier", "Magnon"], ["MmeThenardier", "Gueulemer"], ["MmeThenardier", "Babet"], ["MmeThenardier", "Claquesous"], ["Thenardier", "Cosette"], ["Thenardier", "Javert"], ["Thenardier", "Pontmercy"], ["Thenardier", "Boulatruelle"],
            ["Thenardier", "Eponine"], ["Thenardier", "Anzelma"], ["Thenardier", "Gavroche"], ["Thenardier", "Marius"], ["Thenardier", "Gueulemer"], ["Thenardier", "Babet"], ["Thenardier", "Claquesous"], ["Thenardier", "Montparnasse"], ["Thenardier", "Brujon"], ["Cosette", "Javert"], ["Cosette", "Woman2"], ["Cosette", "Gillenormand"],
            ["Cosette", "MlleGillenormand"], ["Cosette", "LtGillenormand"], ["Cosette", "Marius"], ["Cosette", "Toussaint"], ["Javert", "Fauchelevent"], ["Javert", "Bamatabois"], ["Javert", "Simplice"], ["Javert", "Woman1"], ["Javert", "Woman2"], ["Javert", "Gavroche"], ["Javert", "Enjolras"], ["Javert", "Gueulemer"],
            ["Javert", "Babet"], ["Javert", "Claquesous"], ["Javert", "Montparnasse"], ["Javert", "Toussaint"], ["Fauchelevent", "MotherInnocent"], ["Fauchelevent", "Gribier"], ["Bamatabois", "Judge"], ["Bamatabois", "Champmathieu"], ["Bamatabois", "Brevet"], ["Bamatabois", "Chenildieu"], ["Bamatabois", "Cochepaille"], ["Perpetue", "Simplice"],
            ["Judge", "Champmathieu"], ["Judge", "Brevet"], ["Judge", "Chenildieu"], ["Judge", "Cochepaille"], ["Champmathieu", "Brevet"], ["Champmathieu", "Chenildieu"], ["Champmathieu", "Cochepaille"], ["Brevet", "Chenildieu"], ["Brevet", "Cochepaille"], ["Chenildieu", "Cochepaille"], ["Pontmercy", "MmePontmercy"], ["Pontmercy", "Marius"],
            ["Eponine", "Anzelma"], ["Eponine", "Marius"], ["Eponine", "Mabeuf"], ["Eponine", "Courfeyrac"], ["Eponine", "Gueulemer"], ["Eponine", "Babet"], ["Eponine", "Claquesous"], ["Eponine", "Montparnasse"], ["Eponine", "Brujon"], ["MmeBurgon", "Jondrette"], ["MmeBurgon", "Gavroche"], ["Gavroche", "Marius"],
            ["Gavroche", "Mabeuf"], ["Gavroche", "Enjolras"], ["Gavroche", "Combeferre"], ["Gavroche", "Prouvaire"], ["Gavroche", "Feuilly"], ["Gavroche", "Courfeyrac"], ["Gavroche", "Bahorel"], ["Gavroche", "Bossuet"], ["Gavroche", "Joly"], ["Gavroche", "Grantaire"], ["Gavroche", "Gueulemer"], ["Gavroche", "Babet"],
            ["Gavroche", "Montparnasse"], ["Gavroche", "Child1"], ["Gavroche", "Child2"], ["Gavroche", "Brujon"], ["Gavroche", "MmeHucheloup"], ["Gillenormand", "Magnon"], ["Gillenormand", "MlleGillenormand"], ["Gillenormand", "LtGillenormand"], ["Gillenormand", "Marius"], ["Gillenormand", "BaronessT"], ["MlleGillenormand", "MmePontmercy"], ["MlleGillenormand", "MlleVaubois"],
            ["MlleGillenormand", "LtGillenormand"], ["MlleGillenormand", "Marius"], ["LtGillenormand", "Marius"], ["Marius", "BaronessT"], ["Marius", "Mabeuf"], ["Marius", "Enjolras"], ["Marius", "Combeferre"], ["Marius", "Feuilly"], ["Marius", "Courfeyrac"], ["Marius", "Bahorel"], ["Marius", "Bossuet"], ["Marius", "Joly"],
            ["Mabeuf", "Enjolras"], ["Mabeuf", "Combeferre"], ["Mabeuf", "Feuilly"], ["Mabeuf", "Courfeyrac"], ["Mabeuf", "Bahorel"], ["Mabeuf", "Bossuet"], ["Mabeuf", "Joly"], ["Mabeuf", "MotherPlutarch"], ["Enjolras", "Combeferre"], ["Enjolras", "Prouvaire"], ["Enjolras", "Feuilly"], ["Enjolras", "Courfeyrac"],
            ["Enjolras", "Bahorel"], ["Enjolras", "Bossuet"], ["Enjolras", "Joly"], ["Enjolras", "Grantaire"], ["Enjolras", "Claquesous"], ["Enjolras", "MmeHucheloup"], ["Combeferre", "Prouvaire"], ["Combeferre", "Feuilly"], ["Combeferre", "Courfeyrac"], ["Combeferre", "Bahorel"], ["Combeferre", "Bossuet"], ["Combeferre", "Joly"],
            ["Combeferre", "Grantaire"], ["Prouvaire", "Feuilly"], ["Prouvaire", "Courfeyrac"], ["Prouvaire", "Bahorel"], ["Prouvaire", "Bossuet"], ["Prouvaire", "Joly"], ["Prouvaire", "Grantaire"], ["Feuilly", "Courfeyrac"], ["Feuilly", "Bahorel"], ["Feuilly", "Bossuet"], ["Feuilly", "Joly"], ["Feuilly", "Grantaire"],
            ["Courfeyrac", "Bahorel"], ["Courfeyrac", "Bossuet"], ["Courfeyrac", "Joly"], ["Courfeyrac", "Grantaire"], ["Courfeyrac", "MmeHucheloup"], ["Bahorel", "Bossuet"], ["Bahorel", "Joly"], ["Bahorel", "Grantaire"], ["Bahorel", "MmeHucheloup"], ["Bossuet", "Joly"], ["Bossuet", "Grantaire"], ["Bossuet", "MmeHucheloup"],
            ["Joly", "Grantaire"], ["Joly", "MmeHucheloup"], ["Grantaire", "MmeHucheloup"], ["Gueulemer", "Babet"], ["Gueulemer", "Claquesous"], ["Gueulemer", "Montparnasse"], ["Gueulemer", "Brujon"], ["Babet", "Claquesous"], ["Babet", "Montparnasse"], ["Babet", "Brujon"], ["Claquesous", "Montparnasse"], ["Claquesous", "Brujon"],
            ["Montparnasse", "Brujon"], ["Child1", "Child2"]
        ]
        let graph = Pseudograph<String>(vertices: ["Napoleon", "Myriel", "MlleBaptistine", "MmeMagloire", "CountessDeLo", "Geborand", "Champtercier", "Cravatte", "Count", "OldMan", "Valjean", "Labarre", "Marguerite", "MmeDeR", "Isabeau", "Gervais", "Listolier", "Tholomyes", "Fameuil", "Blacheville", "Favourite", "Dahlia", "Zephine", "Fantine", "MmeThenardier", "Thenardier", "Cosette", "Javert", "Fauchelevent", "Bamatabois", "Perpetue", "Simplice", "Scaufflaire", "Woman1", "Judge", "Champmathieu", "Brevet", "Chenildieu", "Cochepaille", "Pontmercy", "Boulatruelle", "Eponine", "Anzelma", "Woman2", "MotherInnocent", "Gribier", "MmeBurgon", "Jondrette", "Gavroche", "Gillenormand", "Magnon", "MlleGillenormand", "MmePontmercy", "MlleVaubois", "LtGillenormand", "Marius", "BaronessT", "Mabeuf", "Enjolras", "Combeferre", "Prouvaire", "Feuilly", "Courfeyrac", "Bahorel", "Bossuet", "Joly", "Grantaire", "MotherPlutarch", "Gueulemer", "Babet", "Claquesous", "Montparnasse", "Toussaint", "Child1", "Child2", "Brujon", "MmeHucheloup"], edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [["Napoleon", "CountessDeLo", "Geborand", "Champtercier", "Cravatte", "Count", "OldMan"], ["Myriel"], ["MlleBaptistine", "MmeMagloire"], ["Valjean"], ["Labarre", "MmeDeR", "Isabeau", "Gervais", "Scaufflaire"], ["Marguerite"], ["Listolier", "Fameuil", "Blacheville", "Favourite", "Dahlia", "Zephine"], ["Tholomyes"], ["Fantine"], ["MmeThenardier"], ["Thenardier"], ["Cosette"], ["Javert"], ["Fauchelevent"], ["Bamatabois"], ["Perpetue"], ["Simplice"], ["Woman1"], ["Judge", "Champmathieu", "Brevet", "Chenildieu", "Cochepaille"], ["Pontmercy"], ["Boulatruelle"], ["Eponine"], ["Anzelma"], ["Woman2", "Toussaint"], ["MotherInnocent"], ["Gribier"], ["MmeBurgon"], ["Jondrette"], ["Gavroche"], ["Gillenormand"], ["Magnon"], ["MlleGillenormand"], ["MmePontmercy"], ["MlleVaubois"], ["LtGillenormand"], ["Marius"], ["BaronessT"], ["Mabeuf"], ["Enjolras"], ["Combeferre", "Feuilly"], ["Prouvaire"], ["Courfeyrac"], ["Bahorel", "Joly"], ["Bossuet"], ["Grantaire"], ["MotherPlutarch"], ["Gueulemer", "Babet"], ["Claquesous"], ["Montparnasse"], ["Child1", "Child2"], ["Brujon"], ["MmeHucheloup"]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 3344302080000)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-228 Petersen, one vertex coloured: order")
    func is228() {
        // `U: nx(petersen)`; `automorphismGroup().order vertexColor: G [x,o,o,o,o,o,o,o,o,o]` ⇒ 12
        let graphEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let patternColor: [Int: String] = [0: "x", 1: "o", 2: "o", 3: "o", 4: "o", 5: "o", 6: "o", 7: "o", 8: "o", 9: "o"]
        let group = graph.automorphismGroup(vertexColor: { patternColor[$0]! })
        // The catalog's value.
        #expect(group.order == 12)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 12)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-229 Petersen, one vertex coloured: orbits")
    func is229() {
        // `U: nx(petersen)`; `automorphismGroup().orbits vertexColor: G [x,o,o,o,o,o,o,o,o,o]` ⇒ {0} {1,4,5} {2,3,6,7,8,9}
        let graphEdges: [[Int]] = [
            [0, 1], [0, 4], [0, 5], [1, 2], [1, 6], [2, 3], [2, 7], [3, 4], [3, 8], [4, 9], [5, 7], [5, 8],
            [6, 8], [6, 9], [7, 9]
        ]
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 10), edges: graphEdges.map { UndirectedEdge($0[0], $0[1]) })
        let patternColor: [Int: String] = [0: "x", 1: "o", 2: "o", 3: "o", 4: "o", 5: "o", 6: "o", 7: "o", 8: "o", 9: "o"]
        let group = graph.automorphismGroup(vertexColor: { patternColor[$0]! })
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0], [1, 4, 5], [2, 3, 6, 7, 8, 9]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 12)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-230 C4 with edge colours a a b b: order")
    func is230() {
        // `U: C(0,1,2,3)`; `automorphismGroup().order edgeColor: G [a,a,b,b]` ⇒ 2
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternEdgeColor = ["a", "a", "b", "b"]
        let group = graph.automorphismGroup(vertexColor: { _ in 0 }, edgeColor: { patternEdgeColor[$0] })
        // The catalog's value.
        #expect(group.order == 2)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 2)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-231 doubled edge and a pendant: order")
    func is231() {
        // `U: 0=1, 1-2`; `automorphismGroup().order` ⇒ 1
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 1)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-232 loops break symmetry: orbits")
    func is232() {
        // `U: 0-0, C(0,1,2,3)`; `automorphismGroup().orbits` ⇒ {0} {1,3} {2}
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.orbits.map { Array($0) } == [[0], [1, 3], [2]])
        #expect(graph.vertices.allSatisfy { group.orbits[group.orbit(of: $0)].contains($0) })
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 2)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }

    @Test("IS-233 bouquet of three loops: order")
    func is233() {
        // `U: 0-0, 0-0, 0-0`; `automorphismGroup().order` ⇒ 1
        let graph = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        let group = graph.automorphismGroup()
        // The catalog's value.
        #expect(group.order == 1)
        // The stabiliser chain's lengths multiply to the order.
        #expect(group.basicOrbitLengths.reduce(1, *) == 1)
        // Every generator is an automorphism, and their orbits are `orbits`.
        let index = Dictionary(uniqueKeysWithValues: graph.vertices.enumerated().map { ($1, $0) })
        var root = Array(0 ..< graph.vertexCount)
        func find(_ x: Int) -> Int { var x = x; while root[x] != x { x = root[x] }; return x }
        for generator in group.generators {
            #expect(Set(generator.images).count == graph.vertexCount)
            let edges = graph.edges.map { [$0.u, $0.v] }.map { $0.sorted { index[$0]! < index[$1]! } }
            let moved = graph.edges.map { [generator.image(of: $0.u), generator.image(of: $0.v)] }.map { $0.sorted { index[$0]! < index[$1]! } }
            #expect(Dictionary(grouping: edges, by: { $0 }).mapValues(\.count) == Dictionary(grouping: moved, by: { $0 }).mapValues(\.count))
            for v in graph.vertices { root[find(index[v]!)] = find(index[generator.image(of: v)]!) }
        }
        let orbitOf = (0 ..< graph.vertexCount).map(find)
        #expect(graph.vertices.allSatisfy { u in graph.vertices.allSatisfy { v in (group.orbit(of: u) == group.orbit(of: v)) == (orbitOf[index[u]!] == orbitOf[index[v]!]) } })
    }
}
