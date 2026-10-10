// Preconditions, as exit tests (catalog MA-229 – MA-238): a position outside `edges`, a bipartition
// of another graph, an edge inside a side, a NaN or infinite weight, a negative count or NaN cost, a
// NaN weight in a full matching, an index out of range or repeated in a preference list. Then the
// preconditions the catalog does not list: `mate(of:)` on a non-vertex, `mate(ofIndex:)` out of
// range, `mate(ofProposer:)` and `mate(ofReviewer:)` out of range, a reviewer list naming a proposer
// out of range or one twice, a position outside `edges` given to the other two checks, a NaN weight
// to `minimumWeightMatching`, a negative column count, a NaN cost under `maximize`. Each exit test
// builds its inputs inside the closure. Generated from cases.md by swiftgen.py, the tests after
// MA-238 written by hand; see README.md.

import AdjacencyListModule
import BipartiteGraphs
import GraphProtocols
import GrafluentTestSupport
import MatchingModule
import Testing

@Suite("Matching preconditions", .tags(.precondition))
struct MatchingPreconditionTests {
    @Test("MA-229 position out of range (positions must be positions of `edges`) traps")
    func ma229() async {
        // V [0, 1]; E [0-1]; isMatching([1])
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.isMatching([1])
        }
    }

    @Test("MA-230 bipartition of another graph (vertex count differs) traps")
    func ma230() async {
        // V [0, 1, 2]; E [0-1]; bipartition of P3; maximumBipartiteMatching(bipartition:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1)])
            // A bipartition of the path 0–1–2–3 (three edges): four vertices, not three.
            let other = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
            _ = graph.maximumBipartiteMatching(bipartition: other.bipartition()!)
        }
    }

    @Test("MA-231 bipartition with an edge inside a side (an edge does not cross; checked in the row scan) traps")
    func ma231() async {
        // V [0, 1, 2, 3]; E [0-1]; bipartition from a graph with edges 0-2, 1-3; maximumBipartiteMatching(bipartition:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 1)])
            // The sides of 0–2, 1–3: left [0, 1], right [2, 3], so the edge 0–1 is inside the left side.
            let other = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(1, 3)])
            _ = graph.maximumBipartiteMatching(bipartition: other.bipartition()!)
        }
    }

    @Test("MA-232 NaN weight (weights must not be NaN) traps")
    func ma232() async {
        // V [0, 1]; E [0-1:nan]; maximumWeightMatching(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumWeightMatching(weight: { _ in Double.nan })
        }
    }

    @Test("MA-233 infinite weight (Double weights must be finite (dual arithmetic)) traps")
    func ma233() async {
        // V [0, 1]; E [0-1:inf]; maximumWeightMatching(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumWeightMatching(weight: { _ in Double.infinity })
        }
    }

    @Test("MA-234 negative row count (counts ≥ 0) traps")
    func ma234() async {
        // linearSumAssignment(rowCount: -1, columnCount: 2)
        await #expect(processExitsWith: .failure) {
            _ = linearSumAssignment(rowCount: -1, columnCount: 2) { (_: Int, _: Int) -> Int? in 0 }
        }
    }

    @Test("MA-235 NaN cost (costs must not be NaN (scipy: invalid numeric entries)) traps")
    func ma235() async {
        // [nan]; linearSumAssignment(rowCount: 1, columnCount: 1)
        await #expect(processExitsWith: .failure) {
            _ = linearSumAssignment(rowCount: 1, columnCount: 1) { (_: Int, _: Int) -> Double? in .nan }
        }
    }

    @Test("MA-236 NaN weight (weights must not be NaN) traps")
    func ma236() async {
        // L [0]; R [1]; E [0-1:nan]; minimumWeightFullMatching(weight:)
        await #expect(processExitsWith: .failure) {
            let graph = BipartiteGraph<Int>(left: [0], right: [1], edges: [UndirectedEdge(0, 1)])!
            _ = graph.minimumWeightFullMatching(weight: { _ in Double.nan })
        }
    }

    @Test("MA-237 reviewer index out of range (every listed index in range) traps")
    func ma237() async {
        // P [[1]]; R [[0]]; stableMatching
        await #expect(processExitsWith: .failure) {
            _ = stableMatching(proposerPreferences: [[1]], reviewerPreferences: [[0]])
        }
    }

    @Test("MA-238 repeated entry in a list (strict preferences: no repeats) traps")
    func ma238() async {
        // P [[0, 0]]; R [[0]]; stableMatching
        await #expect(processExitsWith: .failure) {
            _ = stableMatching(proposerPreferences: [[0, 0]], reviewerPreferences: [[0]])
        }
    }

    @Test("mate(of:) on a vertex that is not in the graph traps")
    func mateOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumMatching().mate(of: 7)
        }
    }

    @Test("matchedEdge(of:) on a vertex that is not in the graph traps")
    func matchedEdgeOfNonVertex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximalMatching().matchedEdge(of: 7)
        }
    }

    @Test("mate(ofIndex:) past the last index traps")
    func mateOfIndexPastEnd() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumMatching().mate(ofIndex: 2)
        }
    }

    @Test("mate(ofIndex:) with a negative index traps")
    func mateOfNegativeIndex() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.maximumMatching().mate(ofIndex: -1)
        }
    }

    @Test("mate(ofProposer:) out of range traps")
    func mateOfProposerOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = stableMatching(proposerPreferences: [[0]], reviewerPreferences: [[0]]).mate(ofProposer: 1)
        }
    }

    @Test("mate(ofReviewer:) out of range traps")
    func mateOfReviewerOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = stableMatching(proposerPreferences: [[0]], reviewerPreferences: [[0]]).mate(ofReviewer: 1)
        }
    }

    @Test("a reviewer list naming a proposer out of range traps")
    func proposerIndexOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            _ = stableMatching(proposerPreferences: [[0]], reviewerPreferences: [[1]])
        }
    }

    @Test("a reviewer list naming a proposer twice traps")
    func repeatInReviewerList() async {
        await #expect(processExitsWith: .failure) {
            _ = stableMatching(proposerPreferences: [[0], [0]], reviewerPreferences: [[1, 0, 1]])
        }
    }

    @Test("a negative reviewer index traps")
    func negativeReviewerIndex() async {
        await #expect(processExitsWith: .failure) {
            _ = stableMatching(proposerPreferences: [[-1]], reviewerPreferences: [[0]])
        }
    }

    @Test("isMaximalMatching with a position outside edges traps")
    func isMaximalOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.isMaximalMatching([1])
        }
    }

    @Test("isPerfectMatching with a position outside edges traps")
    func isPerfectOutOfRange() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1], edges: [UndirectedEdge(0, 1)])
            _ = graph.isPerfectMatching([0, 5])
        }
    }

    @Test("minimumWeightMatching with a NaN weight traps")
    func minimumWeightNaN() async {
        await #expect(processExitsWith: .failure) {
            let graph = UndirectedAdjacencyList<Int>(vertices: [0, 1, 2], edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
            _ = graph.minimumWeightMatching(weight: { $0 == 1 ? Double.nan : 1 })
        }
    }

    @Test("linearSumAssignment with a negative column count traps")
    func negativeColumnCount() async {
        await #expect(processExitsWith: .failure) {
            _ = linearSumAssignment(rowCount: 2, columnCount: -1) { (_: Int, _: Int) -> Int? in 0 }
        }
    }

    @Test("linearSumAssignment with a NaN cost under maximize traps")
    func nanCostMaximize() async {
        await #expect(processExitsWith: .failure) {
            _ = linearSumAssignment(rowCount: 2, columnCount: 2, maximize: true) { (i: Int, j: Int) -> Double? in i == 1 && j == 0 ? .nan : 1 }
        }
    }
}
