// §11: Codable, description and Sendable. Encoding writes a keyed container {"vertices", "edges"}
// in the stored rotation; decoding re-checks the shape and the intrinsic invariant and throws
// DecodingError.dataCorrupted instead of trapping. description writes the vertices as Array does
// (at most 16, then …), debugDescription adds the type and the positions. Case IDs (WK-nnn) refer
// to the catalog; see README.md.

import Foundation
import GrafluentTestSupport
import Testing
import Walks

@Suite("Walk Codable, description and Sendable", .tags(.conformance))
struct WalkCodableTests {
    @Test("WK-1101 a walk encodes as a keyed container of vertices and edges")
    func encodeShape() throws {
        let walk = Walk(vertices: [0, 1, 2], edges: [5, 6])
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        #expect(String(decoding: try encoder.encode(walk), as: UTF8.self) == #"{"edges":[5,6],"vertices":[0,1,2]}"#)
        let cycle = try #require(Cycle(vertices: [2, 0, 1], edges: [7, 8, 9]))
        #expect(String(decoding: try encoder.encode(cycle), as: UTF8.self) == #"{"edges":[7,8,9],"vertices":[2,0,1]}"#)
    }

    @Test("WK-1102 every type round-trips through JSON with String vertices")
    func roundTrip() throws {
        let walk = Walk(vertices: ["a", "b", "a"], edges: [0, 0])
        let trail = try #require(Trail(vertices: ["a", "b", "a"], edges: [0, 1]))
        let path = try #require(Path(vertices: ["a", "b", "c"], edges: [0, 1]))
        let circuit = try #require(Circuit(vertices: ["a", "b", "a", "c"], edges: [0, 1, 2, 3]))
        let cycle = try #require(Cycle(vertices: ["a", "b", "c"], edges: [0, 1, 2]))
        let trivial = Walk<String, Int>(vertex: "z")
        #expect(try JSONDecoder().decode(Walk<String, Int>.self, from: JSONEncoder().encode(walk)) == walk)
        #expect(try JSONDecoder().decode(Trail<String, Int>.self, from: JSONEncoder().encode(trail)) == trail)
        #expect(try JSONDecoder().decode(Path<String, Int>.self, from: JSONEncoder().encode(path)) == path)
        #expect(try JSONDecoder().decode(Circuit<String, Int>.self, from: JSONEncoder().encode(circuit)) == circuit)
        #expect(try JSONDecoder().decode(Cycle<String, Int>.self, from: JSONEncoder().encode(cycle)) == cycle)
        #expect(try JSONDecoder().decode(Walk<String, Int>.self, from: JSONEncoder().encode(trivial)) == trivial)
        #expect(try PropertyListDecoder().decode(Path<String, Int>.self, from: PropertyListEncoder().encode(path)) == path)
    }

    @Test("WK-1103 a decoded cycle keeps the encoded rotation and equals every rotation")
    func decodedRotation() throws {
        let json = Data(#"{"vertices":[1,2,0],"edges":[11,12,10]}"#.utf8)
        let decoded = try JSONDecoder().decode(Cycle<Int, Int>.self, from: json)
        #expect(Array(decoded) == [1, 2, 0])
        #expect(decoded.edges == [11, 12, 10])
        #expect(decoded == (try #require(Cycle(vertices: [0, 1, 2], edges: [10, 11, 12]))))
        #expect(decoded == (try #require(Cycle(vertices: [2, 0, 1], edges: [12, 10, 11]))))
    }

    @Test("WK-1104 decoding a value that breaks its invariant or shape throws dataCorrupted")
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
        expectCorrupted(Path<Int, Int>.self, #"{"vertices":[0,1,0],"edges":[1,2]}"#)
        expectCorrupted(Walk<Int, Int>.self, #"{"vertices":[0,1],"edges":[]}"#)
        expectCorrupted(Cycle<Int, Int>.self, #"{"vertices":[],"edges":[]}"#)
        expectCorrupted(Walk<Int, Int>.self, #"{"vertices":[],"edges":[]}"#)
        expectCorrupted(Trail<Int, Int>.self, #"{"vertices":[0,1,0],"edges":[4,4]}"#)
        expectCorrupted(Circuit<Int, Int>.self, #"{"vertices":[0,1],"edges":[3]}"#)
        expectCorrupted(Circuit<Int, Int>.self, #"{"vertices":[0,1],"edges":[3,3]}"#)
        expectCorrupted(Cycle<Int, Int>.self, #"{"vertices":[0,0],"edges":[3,4]}"#)
    }

    @Test("WK-1105 description writes the vertices as Array does")
    func description() throws {
        let walk = Walk(vertices: [0, 1, 2], edges: [5, 6])
        #expect(String(describing: walk) == "[0, 1, 2]")
        #expect(String(describing: Walk<Int, Int>(vertex: 4)) == "[4]")
        #expect(String(describing: try #require(Path(vertices: ["a", "b"], edges: [3]))) == #"["a", "b"]"#)
    }

    @Test("WK-1106 debugDescription adds the type and the positions")
    func debugDescription() throws {
        let path = try #require(Path(vertices: ["a", "b"], edges: [3]))
        #expect(String(reflecting: path) == #"Path(vertices: ["a", "b"], edges: [3])"#)
        let walk = Walk(vertices: [0, 1, 2], edges: [3, 5])
        #expect(String(reflecting: walk) == "Walk(vertices: [0, 1, 2], edges: [3, 5])")
    }

    @Test("WK-1107 a cycle prints without its repeated start")
    func cycleDescription() throws {
        let cycle = try #require(Cycle(vertices: [0, 1, 2], edges: [0, 1, 2]))
        #expect(String(describing: cycle) == "[0, 1, 2]")
        #expect(String(reflecting: cycle) == "Cycle(vertices: [0, 1, 2], edges: [0, 1, 2])")
        #expect(String(describing: try #require(Circuit(vertices: [0, 1, 0, 2], edges: [0, 1, 2, 3]))) == "[0, 1, 0, 2]")
    }

    @Test("WK-1108 a description lists at most 16 vertices, then …")
    func elided() throws {
        let walk = Walk(vertices: Array(0 ..< 20), edges: Array(100 ..< 119))
        #expect(String(describing: walk) == "[" + (0 ..< 16).map(String.init).joined(separator: ", ") + ", …]")
        let sixteen = Walk(vertices: Array(0 ..< 16), edges: Array(100 ..< 115))
        #expect(String(describing: sixteen) == "[" + (0 ..< 16).map(String.init).joined(separator: ", ") + "]")
    }

    @Test("WK-1109 walks of Sendable vertices and edges are Sendable")
    func sendable() async throws {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let walk = Walk(vertices: [0, 1, 2], edges: [5, 6])
        let cycle = try #require(Cycle(vertices: [0, 1], edges: [0, 1]))
        _ = requireSendable(walk)
        _ = requireSendable(try #require(Trail(vertices: [0, 1], edges: [0])))
        _ = requireSendable(try #require(Path(vertices: [0, 1], edges: [0])))
        _ = requireSendable(Circuit(cycle))
        _ = requireSendable(cycle)
        let length = await Task.detached { walk.length + cycle.length }.value
        #expect(length == 4)
        let send: @Sendable () -> Int = { walk.target }
        #expect(send() == 2)
    }

    @Test("WK-1110 no vertex outlives the walks built over it: conversions, append and reversal", .lifetimeChecked, .tags(.lifetime))
    func lifetimes() throws {
        let tracker = try #require(LifetimeTracker.current)
        do {
            let vs = (0 ..< 4).map { LifetimeTracked($0) }
            #expect(tracker.instances == 4)
            let path = try #require(Path(vertices: vs, edges: [0, 1, 2]))
            var walk = Walk(path)
            walk.append(Walk(vertices: [vs[3], vs[0]], edges: [3]))
            let cycle = try #require(Cycle(walk))
            let circuit = Circuit(cycle)
            let back = Walk(circuit.reversed())
            let trail = try #require(Trail(back))
            #expect(trail.count == 5 && cycle.count == 4)
            #expect(Walk(cycle).reversed().length == 4)
            #expect(tracker.instances == 4)
        }
        #expect(tracker.instances == 0)
    }
}
