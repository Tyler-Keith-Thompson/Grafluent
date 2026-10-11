// Conformances (catalog FG-060 – FG-062): equality and hashing of the successor arrays, the
// description, and Codable as the bare array, with decoding re-checking the range.
// Generated from cases.md by swiftgen.py; see README.md.

import Foundation
import FunctionalGraphs
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("FunctionalGraphs equality, description and Codable")
struct FunctionalGraphEqualityTests {
    @Test("FG-060 Equatable compares successor arrays", .tags(.conformance))
    func fg060() {
        // FG [1, 0] == FG [1, 0] / FG [1, 0] == FG [0, 1] → true; false
        #expect(FunctionalGraph(successors: [1, 0]) == FunctionalGraph(successors: [1, 0]))
        #expect(FunctionalGraph(successors: [1, 0]) != FunctionalGraph(successors: [0, 1]))
        #expect(FunctionalGraph(successors: [1, 0]).hashValue == FunctionalGraph(successors: [1, 0]).hashValue)
        #expect(Set([FunctionalGraph(successors: [1, 0]), FunctionalGraph(successors: [1, 0]), FunctionalGraph(successors: [0, 1])]).count == 2)
        #expect(FunctionalGraph(successors: [0]) != FunctionalGraph(successors: [0, 0]))
    }

    @Test("FG-061 description", .tags(.conformance))
    func fg061() {
        // FG [1, 2, 0].description → FunctionalGraph([1, 2, 0])
        #expect(FunctionalGraph(successors: [1, 2, 0]).description == "FunctionalGraph([1, 2, 0])")
        #expect(FunctionalGraph(successors: []).description == "FunctionalGraph([])")
        #expect("\(FunctionalGraph(successors: [0]))" == "FunctionalGraph([0])")
    }

    @Test("FG-062 Codable round trip as the successor array; decoding re-checks the range", .tags(.conformance))
    func fg062() throws {
        // encode FG [1, 2, 0] / decode [0, 3] → [1,2,0]; DecodingError.dataCorrupted
        let data = try JSONEncoder().encode(FunctionalGraph(successors: [1, 2, 0]))
        #expect(String(decoding: data, as: UTF8.self) == "[1,2,0]")
        #expect(try JSONDecoder().decode(FunctionalGraph.self, from: data) == FunctionalGraph(successors: [1, 2, 0]))
        for corrupt in ["[0,3]", "[-1]", "[1]"] {
            do {
                _ = try JSONDecoder().decode(FunctionalGraph.self, from: Data(corrupt.utf8))
                Issue.record("decoded \(corrupt)")
            } catch DecodingError.dataCorrupted {
            } catch {
                Issue.record("\(corrupt): \(error)")
            }
        }
        #expect(try JSONDecoder().decode(FunctionalGraph.self, from: Data("[]".utf8)) == FunctionalGraph(successors: []))
    }
}
