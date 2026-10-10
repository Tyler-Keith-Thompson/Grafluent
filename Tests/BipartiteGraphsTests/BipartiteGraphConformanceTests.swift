// Conformances beyond Graph (api.md, Summary and Semantics): Codable (`left`, `right`, then the
// edges as pairs of offsets into `left ++ right`; decoding re-checks the invariant and throws
// instead of trapping), Hashable, `Sendable` when the vertex is, the description
// (`[0, 2] | [1]; [0–1, 2–1]`: left, right, edges, at most 16 of each, written as every
// representation writes them), `SideVertices` as a value with `Int` indices from 0, copy-on-write,
// the capacity calls, and `BipartiteSide`. api.md names no coding keys, so the invalid payloads are
// made by editing a valid encoding: the keys are found by their values. See README.md.

import AdjacencyListModule
import BipartiteGraphs
import Foundation
import GraphProtocols
import GrafluentTestSupport
import Testing

@Suite("BipartiteGraph conformances: Codable, Hashable, Sendable, descriptions, value semantics", .tags(.conformance))
struct BipartiteGraphConformanceTests {
    @Test("Round trips through JSON and property lists keep the value, the sides' orders and the edge positions")
    func roundTrip() throws {
        // BP-128's graph after its removal (the slots no longer left-then-right), BP-118's, the empty graph.
        let pairs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")]
        var moved = try #require(BipartiteGraph(left: ["a", "b", "c"], right: ["x", "y"], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        moved.remove("a")
        moved.insert(edge: UndirectedEdge("x", "c"))
        #expect(Array(moved.vertices) == ["y", "b", "c", "x"])
        let decoded = try JSONDecoder().decode(BipartiteGraph<String>.self, from: JSONEncoder().encode(moved))
        #expect(decoded == moved)
        #expect(Array(decoded.left) == Array(moved.left))
        #expect(Array(decoded.right) == Array(moved.right))
        #expect(decoded.edges.map { [$0.u, $0.v] } == moved.edges.map { [$0.u, $0.v] })
        // The encoding carries the sides in order, so the decoded vertices are left, then right.
        #expect(Array(decoded.vertices) == Array(moved.left) + Array(moved.right))

        let intPairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3), (4, 5), (0, 5)]
        let ints = try #require(BipartiteGraph(left: [0, 2, 4], right: [1, 3, 5], edges: intPairs.map { UndirectedEdge($0.0, $0.1) }))
        let fromPlist = try PropertyListDecoder().decode(BipartiteGraph<Int>.self, from: PropertyListEncoder().encode(ints))
        #expect(fromPlist == ints)
        #expect(Array(fromPlist.vertices) == [0, 2, 4, 1, 3, 5])
        #expect(fromPlist.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3], [4, 5], [0, 5]])

        let empty = try JSONDecoder().decode(BipartiteGraph<Int>.self, from: JSONEncoder().encode(BipartiteGraph<Int>()))
        #expect(empty == BipartiteGraph<Int>())
        #expect(empty.vertexCount == 0)
        // The same graph built the same way encodes to the same bytes.
        let sorted = JSONEncoder()
        sorted.outputFormatting = .sortedKeys
        let again = try #require(BipartiteGraph(left: [0, 2, 4], right: [1, 3, 5], edges: intPairs.map { UndirectedEdge($0.0, $0.1) }))
        #expect(try sorted.encode(ints) == sorted.encode(again))
    }

    @Test("Decoding a payload that breaks the invariant throws DecodingError.dataCorrupted; a malformed one throws; neither traps")
    func decodeInvalid() throws {
        // A valid encoding of left [a, b], right [x], edges [a–x, b–x]; the keys are found by value.
        let graph = try #require(BipartiteGraph(left: ["a", "b"], right: ["x"], edges: [UndirectedEdge("a", "x"), UndirectedEdge("x", "b")]))
        let object = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(graph)) as? [String: Any])
        let leftKey = try #require(object.first { ($0.value as? [String]) == ["a", "b"] }?.key, "a key holding the left side")
        let rightKey = try #require(object.first { ($0.value as? [String]) == ["x"] }?.key, "a key holding the right side")
        let edgesKey = try #require(object.first { ($0.value as? [Int]) == [0, 2, 1, 2] }?.key, "a key holding the edges as offsets into left ++ right")

        func payload(_ changes: [String: Any?]) throws -> Data {
            var copy = object
            for (key, value) in changes { copy[key] = value }
            return try JSONSerialization.data(withJSONObject: copy)
        }
        func expectCorrupted(_ data: Data, _ comment: Comment) {
            do {
                _ = try JSONDecoder().decode(BipartiteGraph<String>.self, from: data)
                Issue.record("decoded: \(comment)")
            } catch DecodingError.dataCorrupted {
                // Expected.
            } catch {
                Issue.record("\(comment): \(error), not dataCorrupted")
            }
        }
        func expectThrows(_ data: Data, _ comment: Comment) {
            #expect(throws: (any Error).self, comment) { try JSONDecoder().decode(BipartiteGraph<String>.self, from: data) }
        }
        // The unedited payload decodes.
        #expect(try JSONDecoder().decode(BipartiteGraph<String>.self, from: payload([:])) == graph)
        // Invariant violations.
        expectCorrupted(try payload([leftKey: ["a", "x"]]), "x on both sides")
        expectCorrupted(try payload([rightKey: ["x", "a"]]), "a on both sides")
        expectCorrupted(try payload([edgesKey: [0, 1]]), "an edge inside the left side")
        expectCorrupted(try payload([rightKey: ["x", "y"], edgesKey: [2, 3]]), "an edge inside the right side")
        expectCorrupted(try payload([edgesKey: [0, 0]]), "a self-loop")
        expectCorrupted(try payload([edgesKey: [2, 2]]), "a self-loop on the right")
        // Malformed edge lists.
        expectCorrupted(try payload([edgesKey: [0, 9]]), "an endpoint out of range")
        expectCorrupted(try payload([edgesKey: [-1, 2]]), "a negative endpoint")
        expectCorrupted(try payload([edgesKey: [0, 2, 1]]), "an odd edge list")
        // Wrong shapes and missing keys.
        expectThrows(try payload([edgesKey: ["a", "x"]]), "edges as strings")
        expectThrows(try payload([edgesKey: nil]), "no edges key")
        expectThrows(try payload([leftKey: nil]), "no left key")
        expectThrows(Data("[]".utf8), "an array")
        expectThrows(Data("{}".utf8), "an empty object")
    }

    @Test("Hashable: equal values hash alike whatever their orders; a set keeps one of each")
    func hashing() throws {
        let pairs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")]
        let original = try #require(BipartiteGraph(left: ["a", "b", "c"], right: ["x", "y"], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let reordered = try #require(BipartiteGraph(left: ["c", "a", "b"], right: ["y", "x"], edges: pairs.reversed().map { UndirectedEdge($0.1, $0.0) }))
        var removedAndBack = original
        removedAndBack.remove("a")
        removedAndBack.insert("a", on: .left)
        removedAndBack.insert(edge: UndirectedEdge("x", "a"))
        #expect(Array(removedAndBack.vertices) != Array(original.vertices))
        #expect(reordered == original && removedAndBack == original)
        #expect(reordered.hashValue == original.hashValue)
        #expect(removedAndBack.hashValue == original.hashValue)
        var swapped = original
        swapped.remove("a")
        swapped.insert("a", on: .right)
        #expect(swapped != original)
        var noEdge = original
        noEdge.remove(edge: UndirectedEdge("a", "x"))
        #expect(noEdge != original)
        #expect(Set([original, reordered, removedAndBack, swapped, noEdge]).count == 3)
        // Hashes see the edges and the sides, not only the counts: the six perfect matchings of
        // K3,3 (same vertices, sides and edge count) and each one with its sides swapped give twelve
        // distinct hash values (a collision among twelve 64-bit hashes is not a realistic outcome).
        var matchings: [BipartiteGraph<Int>] = []
        for p in [[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]] {
            let edges = (0 ..< 3).map { UndirectedEdge($0, 3 + p[$0]) }
            matchings.append(try #require(BipartiteGraph(left: [0, 1, 2], right: [3, 4, 5], edges: edges)))
            matchings.append(try #require(BipartiteGraph(left: [3, 4, 5], right: [0, 1, 2], edges: edges)))
        }
        #expect(Set(matchings).count == 12)
        #expect(Set(matchings.map(\.hashValue)).count == 12)
    }

    @Test("Sendable when the vertex is: the graph, its sides and a bipartition cross into a Task")
    func sendable() async throws {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let pairs: [(Int, Int)] = [(0, 1), (2, 1)]
        let graph = try #require(BipartiteGraph(left: [0, 2], right: [1], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let sentGraph = requireSendable(graph)
        let left = requireSendable(graph.left)
        let side = requireSendable(BipartiteSide.right)
        let list = UndirectedAdjacencyList(edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let bipartition = requireSendable(try #require(list.bipartition()))
        let counts = await Task { (sentGraph.vertexCount, Array(left), side, bipartition.side(of: 1)) }.value
        #expect(counts.0 == 3)
        #expect(counts.1 == [0, 2])
        #expect(counts.2 == .right)
        #expect(counts.3 == .right)
    }

    @Test("description is left | right; edges, as every representation writes them, at most 16 of each")
    func descriptions() throws {
        let pairs: [(Int, Int)] = [(1, 0), (2, 1)]
        let graph = try #require(BipartiteGraph(left: [0, 2], right: [1], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        // The edge given as 1–0 is stored, and written, left endpoint first.
        #expect(graph.description == "[0, 2] | [1]; [0–1, 2–1]")
        #expect(String(describing: graph) == "[0, 2] | [1]; [0–1, 2–1]")
        #expect(BipartiteGraph<Int>().description == "[] | []; []")
        let named = try #require(BipartiteGraph(left: ["a"], right: ["x", "y"], edges: [UndirectedEdge("x", "a")]))
        #expect(named.description == #"["a"] | ["x", "y"]; ["a"–"x"]"#)
        // 20 left vertices, 3 right, 20 edges: each list stops after 16 with an ellipsis.
        let big = try #require(BipartiteGraph(left: 0 ..< 20, right: 100 ..< 103, edges: (0 ..< 20).map { UndirectedEdge($0, 100 + $0 % 3) }))
        let leftPart = "[" + (0 ..< 16).map(String.init).joined(separator: ", ") + ", …]"
        let edgePart = "[" + (0 ..< 16).map { "\($0)–\(100 + $0 % 3)" }.joined(separator: ", ") + ", …]"
        #expect(big.description == leftPart + " | [100, 101, 102]; " + edgePart)
        // After a removal the description follows the current orders.
        var moved = graph
        moved.remove(0)
        #expect(moved.description == "[2] | [1]; [2–1]")
        #expect(!graph.debugDescription.isEmpty)
        #expect(!String(reflecting: graph).isEmpty)
    }

    @Test("SideVertices is a value with Int indices from 0, unaffected by later changes to the graph", .tags(.copyOnWrite))
    func sideVerticesAreValues() throws {
        let pairs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")]
        var graph = try #require(BipartiteGraph(left: ["a", "b", "c"], right: ["x", "y"], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let left = graph.left
        let right = graph.right
        #expect(left.startIndex == 0 && left.endIndex == 3 && left.count == 3)
        #expect(left[0] == "a" && left[2] == "c")
        #expect(right[1] == "y")
        #expect(Array(left.reversed()) == ["c", "b", "a"])
        #expect(Array(left[1...]) == ["b", "c"])
        graph.remove("a")
        graph.insert("d", on: .left)
        graph.insert("z", on: .right)
        #expect(Array(left) == ["a", "b", "c"])
        #expect(Array(right) == ["x", "y"])
        #expect(Array(graph.left) == ["c", "b", "d"])
        #expect(Array(graph.right) == ["x", "y", "z"])
        #expect(BipartiteGraph<Int>().left.isEmpty)
    }

    @Test("Copies are independent: mutating one leaves the other unchanged", .tags(.copyOnWrite))
    func copyOnWrite() throws {
        let pairs: [(String, String)] = [("a", "x"), ("b", "x"), ("b", "y"), ("c", "y")]
        let original = try #require(BipartiteGraph(left: ["a", "b", "c"], right: ["x", "y"], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let before = original.edges.map { [$0.u, $0.v] }
        var copy = original
        copy.remove("b")
        copy.insert("q", on: .right)
        copy.insert(edge: UndirectedEdge("q", "a"))
        copy.remove(edge: UndirectedEdge("c", "y"))
        #expect(Array(original.vertices) == ["a", "b", "c", "x", "y"])
        #expect(Array(original.left) == ["a", "b", "c"])
        #expect(Array(original.right) == ["x", "y"])
        #expect(original.edges.map { [$0.u, $0.v] } == before)
        #expect(original.side(of: "b") == .left)
        #expect(!original.contains("q"))
        var other = original
        other.removeAll()
        #expect(other.vertexCount == 0 && original.vertexCount == 5)
        var edgeless = original
        edgeless.removeAllEdges()
        #expect(edgeless.edgeCount == 0 && original.edgeCount == 4)
        #expect(Array(edgeless.left) == ["a", "b", "c"])
    }

    @Test("Capacity calls keep the value; the graph is usable after keeping capacity")
    func capacity() throws {
        let pairs: [(Int, Int)] = [(0, 1), (2, 1), (2, 3)]
        var graph = try #require(BipartiteGraph(left: [0, 2], right: [1, 3], edges: pairs.map { UndirectedEdge($0.0, $0.1) }))
        let before = graph
        graph.reserveCapacity(vertexCount: 1000, edgeCount: 5000)
        #expect(graph == before)
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 1], [2, 1], [2, 3]])
        graph.removeAllEdges(keepingCapacity: true)
        #expect(graph.edgeCount == 0 && graph.vertexCount == 4)
        #expect(graph.side(of: 3) == .right)
        graph.insert(edge: UndirectedEdge(3, 0))
        #expect(graph.edges.map { [$0.u, $0.v] } == [[0, 3]])
        graph.removeAll(keepingCapacity: true)
        #expect(graph == BipartiteGraph<Int>())
        #expect(graph.left.isEmpty && graph.right.isEmpty)
        graph.insert(7, on: .right)
        graph.insert(8, on: .left)
        graph.insert(edge: UndirectedEdge(7, 8))
        #expect(Array(graph.vertices) == [7, 8])
        #expect(graph.edges.map { [$0.u, $0.v] } == [[8, 7]])
        var fresh = BipartiteGraph<Int>()
        fresh.reserveCapacity(vertexCount: 0, edgeCount: 0)
        #expect(fresh == BipartiteGraph<Int>())
    }

    @Test("BipartiteSide: two cases in order left, right; Hashable, Codable, described by its name")
    func sides() throws {
        #expect(BipartiteSide.allCases == [.left, .right])
        #expect(Set(BipartiteSide.allCases).count == 2)
        #expect(BipartiteSide.left != .right)
        #expect(String(describing: BipartiteSide.left).contains("left"))
        #expect(String(describing: BipartiteSide.right).contains("right"))
        let decoded = try JSONDecoder().decode([BipartiteSide].self, from: JSONEncoder().encode([BipartiteSide.right, .left]))
        #expect(decoded == [.right, .left])
    }
}
