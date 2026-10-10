// The catalog rows on the package's representations (not a catalog section). Every row of §A – §F
// whose graph has no parallel edges is repeated on `UndirectedAdjacencyList` or `AdjacencyList`
// built in written order, so vertex order, rows and positions are the catalog's (the vertex order
// is asserted first) and the values are the same as on the reference conformers. The modularity,
// partition quality, Louvain and greedy rows of every graph on the vertices 0..<n without parallel
// edges are repeated on `CompressedSparseRow` and `AdjacencyMatrix`, whose rows are sorted and whose
// positions are row-major: directed graphs with their arcs in that order, undirected graphs without
// loops as symmetric digraphs (each edge as two arcs, the `DirectedGraph` entry points: Leicht–Newman
// modularity and the Dugué–Perez gain, which give the undirected values on a symmetric digraph).
// The arcs are asserted first; weights travel with their arcs, looked up by arc on the matrix,
// whose positions are not `Int`s. Those literals are ref.py's model on the rewritten graph (vertex
// numbering 0..<n, so the lcg rows' communities differ from the catalog's). One test per graph and
// representation, each row in its own `do` block. Case IDs (CD-nnn) refer to the catalog; see
// README.md.

import AdjacencyListModule
import AdjacencyMatrixModule
import CommunityDetection
import CompressedSparseRowModule
import Connectivity
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Community detection on every representation")
struct CommunityDetectionRepresentationTests {
    @Test("CD-001, CD-002, CD-003, CD-004, CD-005, CD-006, CD-007, CD-008 on UndirectedAdjacencyList: U: []")
    func undirectedAdjacencyList001() {
        // U: []
        let graph = UndirectedAdjacencyList<Int>(vertices: [], edges: [])
        #expect(Array(graph.vertices) == [] as [Int])
        do {
            // CD-001: modularity(of: [])
            let communities: [[Int]] = []
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-002: partitionQuality(of: []).coverage
            let communities: [[Int]] = []
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
        do {
            // CD-003: partitionQuality(of: []).performance
            let communities: [[Int]] = []
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
        do {
            // CD-004: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-005: louvainCommunities().count
            let result = graph.louvainCommunities()
            #expect(result.count == 0)
            #expect(result.reduce(0) { $0 + $1.count } == graph.vertexCount)
            for (c, community) in result.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
        }
        do {
            // CD-006: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-007: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-008: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-009 on AdjacencyList: D: []")
    func adjacencyList009() {
        // D: []
        let graph = AdjacencyList<Int>(vertices: [], edges: [])
        #expect(Array(graph.vertices) == [] as [Int])
        do {
            // CD-009: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-010, CD-011, CD-012, CD-013, CD-014, CD-015 on UndirectedAdjacencyList: U: [0]")
    func undirectedAdjacencyList010() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0] as [Int])
        do {
            // CD-010: modularity(of: [[0]])
            let communities: [[Int]] = [[0]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-011: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-012: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-013: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-014: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-015: partitionQuality(of: [[0]]).performance
            let communities: [[Int]] = [[0]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
    }

    @Test("CD-016, CD-017, CD-018, CD-019, CD-020, CD-021, CD-022 on UndirectedAdjacencyList: U: [0..3]")
    func undirectedAdjacencyList016() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3] as [Int])
        do {
            // CD-016: modularity(of: [[0, 1], [2, 3]])
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-017: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0], [1], [2], [3]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-018: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0], [1], [2], [3]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-019: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0], [1], [2], [3]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-020: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0], [1], [2], [3]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-021: partitionQuality(of: [[0, 1], [2, 3]]).coverage
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
        do {
            // CD-022: partitionQuality(of: [[0, 1], [2, 3]]).performance
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
    }

    @Test("CD-023 on UndirectedAdjacencyList: U: 0-0")
    func undirectedAdjacencyList023() {
        // U: 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0] as [Int])
        do {
            // CD-023: modularity(of: [[0]])
            let communities: [[Int]] = [[0]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
    }

    @Test("CD-024, CD-025, CD-026, CD-027, CD-028 on UndirectedAdjacencyList: U: 0-0, 1-1")
    func undirectedAdjacencyList024() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1] as [Int])
        do {
            // CD-024: modularity(of: [[0], [1]])
            let communities: [[Int]] = [[0], [1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-025: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0], [1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-026: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0], [1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-027: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0], [1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-028: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0], [1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
    }

    @Test("CD-029, CD-030, CD-031, CD-032 on UndirectedAdjacencyList: U: 0-1")
    func undirectedAdjacencyList029() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1] as [Int])
        do {
            // CD-029: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-030: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-031: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0, 1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-032: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0, 1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-033, CD-034 on AdjacencyList: D: 0>1")
    func adjacencyList033() {
        // D: 0>1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1] as [Int])
        do {
            // CD-033: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0], [1]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-034: modularity(of: [[0, 1]])
            let communities: [[Int]] = [[0, 1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
    }

    @Test("CD-035, CD-036, CD-037, CD-038, CD-039, CD-173, CD-174 on UndirectedAdjacencyList: U: P(0,1,2)")
    func undirectedAdjacencyList035() {
        // U: P(0,1,2)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2] as [Int])
        do {
            // CD-035: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-036: modularity(of: [[0, 1, 2]])
            let communities: [[Int]] = [[0, 1, 2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-037: modularity(of: [[0], [1], [2]])
            let communities: [[Int]] = [[0], [1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.375) <= 1e-12 * max(1, abs(-0.375)))
        }
        do {
            // CD-038: modularity(of: [[2], [0, 1]])
            let communities: [[Int]] = [[2], [0, 1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-039: modularity(of: [[0, 1], [], [2]])
            let communities: [[Int]] = [[0, 1], [], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-173: greedyModularityCommunities(weight: [0, 0])
            let w: [Double] = [0, 0]
            let result = graph.greedyModularityCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0], [1], [2]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-174: louvainCommunities(weight: [0, 0])
            let w: [Double] = [0, 0]
            let result = graph.louvainCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0], [1], [2]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-040, CD-041 on UndirectedAdjacencyList: U: K(4)")
    func undirectedAdjacencyList040() {
        // U: K(4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3] as [Int])
        do {
            // CD-040: modularity(of: [[0, 1, 2, 3]])
            let communities: [[Int]] = [[0, 1, 2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-041: modularity(of: [[0, 1], [2, 3]])
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.16666666666666669) <= 1e-12 * max(1, abs(-0.16666666666666669)))
        }
    }

    @Test("CD-042, CD-043, CD-044, CD-045, CD-046, CD-047, CD-048, CD-049, CD-050, CD-069, CD-070, CD-071, CD-072, CD-073, CD-083, CD-100, CD-111, CD-115, CD-133, CD-143 on UndirectedAdjacencyList: U: K(0..2), K(3..5), 2-3")
    func undirectedAdjacencyList042() {
        // U: K(0..2), K(3..5), 2-3
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
        do {
            // CD-042: modularity(of: [[0, 1, 2], [3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-043: modularity(of: [[0, 1, 2, 3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        }
        do {
            // CD-044: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 0)
            #expect(abs(value - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
        }
        do {
            // CD-045: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 0.5)
            #expect(abs(value - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-046: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 2)
            #expect(abs(value - -0.1428571428571428) <= 1e-12 * max(1, abs(-0.1428571428571428)))
        }
        do {
            // CD-047: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 5])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let w: [Double] = [1, 1, 1, 1, 1, 1, 5]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.045454545454545414) <= 1e-12 * max(1, abs(0.045454545454545414)))
        }
        do {
            // CD-048: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let w: [Double] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-049: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 0])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let w: [Double] = [1, 1, 1, 1, 1, 1, 0]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-050: modularity(of: components)
            let communities = graph.connectedComponents()
            let value = graph.modularity(of: communities)
            #expect(abs(value - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        }
        do {
            // CD-069: partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).coverage
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
            #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)))
        }
        do {
            // CD-070: partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).performance
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
            #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)))
        }
        do {
            // CD-071: partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).coverage
            let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage) <= 1e-12)
            #expect(abs(quality.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)))
        }
        do {
            // CD-072: partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).performance
            let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage) <= 1e-12)
            #expect(abs(quality.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)))
        }
        do {
            // CD-073: partitionQuality(of: components).performance
            let communities = graph.connectedComponents()
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 1) <= 1e-12 * max(1, abs(1)))
            #expect(abs(quality.performance - 0.4666666666666667) <= 1e-12 * max(1, abs(0.4666666666666667)))
        }
        do {
            // CD-083: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-100: louvainCommunities(weight: [1, 1, 1, 1, 1, 1, 10])
            let w: [Double] = [1, 1, 1, 1, 1, 1, 10]
            let result = graph.louvainCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1], [2, 3], [4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q - 0.15625) <= 1e-12 * max(1, abs(0.15625)))
        }
        do {
            // CD-111: directed > louvainCommunities()
            let result = graph.directed.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.directed.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.directed.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-115: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-133: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-143: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
    }

    @Test("CD-051, CD-097, CD-128 on UndirectedAdjacencyList: U: K(0..2), K(3..5)")
    func undirectedAdjacencyList051() {
        // U: K(0..2), K(3..5)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
        do {
            // CD-051: modularity(of: components)
            let communities = graph.connectedComponents()
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-097: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-128: greedyModularityCommunities(resolution: 0)
            let result = graph.greedyModularityCommunities(resolution: 0)
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, resolution: 0)
            #expect(abs(q - 1) <= 1e-12 * max(1, abs(1)))
        }
    }

    @Test("CD-052, CD-084, CD-114, CD-116, CD-134, CD-144 on UndirectedAdjacencyList: U: K(0..4), K(5..9), 4-5")
    func undirectedAdjacencyList052() {
        // U: K(0..4), K(5..9), 4-5
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (4, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        do {
            // CD-052: modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-084: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-114: louvainCommunities(using: rng(3))
            var generator = SeededRandomNumberGenerator(seed: 3)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
            var again = SeededRandomNumberGenerator(seed: 3)
            #expect(graph.louvainCommunities(using: &again) == result, "the same seed again")
        }
        do {
            // CD-116: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-134: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-144: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
    }

    @Test("CD-053, CD-085 on UndirectedAdjacencyList: U: nx(barbell,5,0)")
    func undirectedAdjacencyList053() {
        // U: nx(barbell,5,0)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        do {
            // CD-053: modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-085: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
    }

    @Test("CD-054, CD-086, CD-113, CD-117, CD-135, CD-145 on UndirectedAdjacencyList: U: nx(ring_of_cliques,4,4)")
    func undirectedAdjacencyList054() {
        // U: nx(ring_of_cliques,4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 2), (1, 3), (1, 4), (2, 3), (4, 5),
            (4, 6), (4, 7), (5, 6), (5, 7), (5, 8), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11),
            (9, 12), (10, 11), (12, 13), (12, 14), (12, 15), (13, 14), (13, 15), (14, 15)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        do {
            // CD-054: modularity(of: [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]])
            let communities: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-086: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-113: louvainCommunities(using: rng(2))
            var generator = SeededRandomNumberGenerator(seed: 2)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
            var again = SeededRandomNumberGenerator(seed: 2)
            #expect(graph.louvainCommunities(using: &again) == result, "the same seed again")
        }
        do {
            // CD-117: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-135: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-145: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        }
    }

    @Test("CD-055, CD-056, CD-057, CD-074, CD-075, CD-088, CD-089, CD-090, CD-091, CD-092, CD-093, CD-094, CD-095, CD-119, CD-120, CD-121, CD-122, CD-123, CD-136, CD-137, CD-138, CD-146, CD-147 on UndirectedAdjacencyList: U: nx(karate_club)")
    func undirectedAdjacencyList055() {
        // U: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 34, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        do {
            // CD-055: modularity(of: […])
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.3582347140039448) <= 1e-12 * max(1, abs(0.3582347140039448)))
        }
        do {
            // CD-056: modularity(of: […], weight: […])
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4,
                5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3,
                5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.39143756676224206) <= 1e-12 * max(1, abs(0.39143756676224206)))
        }
        do {
            // CD-057: directed > modularity(of: […])
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let value = graph.directed.modularity(of: communities)
            #expect(abs(value - 0.3582347140039448) <= 1e-12 * max(1, abs(0.3582347140039448)))
        }
        do {
            // CD-074: partitionQuality(of: […]).coverage
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)))
            #expect(abs(quality.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)))
        }
        do {
            // CD-075: partitionQuality(of: […]).performance
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)))
            #expect(abs(quality.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)))
        }
        do {
            // CD-088: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.41880341880341876) <= 1e-12 * max(1, abs(0.41880341880341876)))
        }
        do {
            // CD-089: louvainCommunities().count
            let result = graph.louvainCommunities()
            #expect(result.count == 4)
            #expect(result.reduce(0) { $0 + $1.count } == graph.vertexCount)
            for (c, community) in result.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
        }
        do {
            // CD-090: louvainCommunities().community(of: 33)
            let result = graph.louvainCommunities()
            #expect(result.community(of: 33) == 2)
            #expect(result[2].contains(33))
            #expect(result.community(ofIndex: 33) == 2)
        }
        do {
            // CD-091: louvainCommunities(weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4,
                5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3,
                5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
            let result = graph.louvainCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q - 0.44490358126721763) <= 1e-12 * max(1, abs(0.44490358126721763)))
        }
        do {
            // CD-092: louvainCommunities(resolution: 0.5)
            let result = graph.louvainCommunities(resolution: 0.5)
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21],
                [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, resolution: 0.5)
            #expect(abs(q - 0.6217948717948718) <= 1e-12 * max(1, abs(0.6217948717948718)))
        }
        do {
            // CD-093: louvainCommunities(resolution: 2)
            let result = graph.louvainCommunities(resolution: 2)
            let expected: [[Int]] = [[0, 1, 11, 12, 17, 19, 21], [2, 3, 7, 13], [4, 5, 6, 10, 16], [8, 30],
                [9, 26, 29, 33], [14, 15, 18, 20, 22, 32], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, resolution: 2)
            #expect(abs(q - 0.1561472715318869) <= 1e-12 * max(1, abs(0.1561472715318869)))
        }
        do {
            // CD-094: louvainCommunities(resolution: 0)
            let result = graph.louvainCommunities(resolution: 0)
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, resolution: 0)
            #expect(abs(q - 1) <= 1e-12 * max(1, abs(1)))
        }
        do {
            // CD-095: louvainCommunities(threshold: 1)
            let result = graph.louvainCommunities(threshold: 1)
            let expected: [[Int]] = [[0, 1, 11, 17, 19, 21], [2, 3, 7, 9, 12, 13], [4, 10], [5, 6, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.3613576594345825) <= 1e-12 * max(1, abs(0.3613576594345825)))
        }
        do {
            // CD-119: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16, 19], [1, 2, 3, 7, 9, 12, 13, 17, 21],
                [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.3806706114398422) <= 1e-12 * max(1, abs(0.3806706114398422)))
        }
        do {
            // CD-120: greedyModularityCommunities().count
            let result = graph.greedyModularityCommunities()
            #expect(result.count == 3)
            #expect(result.reduce(0) { $0 + $1.count } == graph.vertexCount)
            for (c, community) in result.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
        }
        do {
            // CD-121: greedyModularityCommunities(weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4,
                5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3,
                5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
            let result = graph.greedyModularityCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q - 0.4345214669889994) <= 1e-12 * max(1, abs(0.4345214669889994)))
        }
        do {
            // CD-122: greedyModularityCommunities(resolution: 0.5)
            let result = graph.greedyModularityCommunities(resolution: 0.5)
            let expected: [[Int]] = [[0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 16, 17, 19, 21],
                [2, 8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, resolution: 0.5)
            #expect(abs(q - 0.6158777120315582) <= 1e-12 * max(1, abs(0.6158777120315582)))
        }
        do {
            // CD-123: greedyModularityCommunities(resolution: 2)
            let result = graph.greedyModularityCommunities(resolution: 2)
            let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16], [1, 17, 19, 21], [2, 9, 28], [3, 7, 12, 13],
                [8, 30], [14, 15, 18, 20, 22, 26, 29, 32, 33], [23, 24, 25, 27, 31]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, resolution: 2)
            #expect(abs(q - 0.16354372123602892) <= 1e-12 * max(1, abs(0.16354372123602892)))
        }
        do {
            // CD-136: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 3, 4, 7, 10, 11, 12, 13, 17, 19, 21, 24, 25, 31],
                [2, 8, 9, 14, 15, 18, 20, 22, 23, 26, 27, 28, 29, 30, 32, 33], [5, 6, 16]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.3251150558842867) <= 1e-12 * max(1, abs(0.3251150558842867)))
        }
        do {
            // CD-137: labelPropagationCommunities().count
            let result = graph.labelPropagationCommunities()
            #expect(result.count == 3)
            #expect(result.reduce(0) { $0 + $1.count } == graph.vertexCount)
            for (c, community) in result.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
        }
        do {
            // CD-138: labelPropagationCommunities(weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4,
                5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3,
                5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
            let result = graph.labelPropagationCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 10], [5, 6, 16],
                [8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q - 0.41782387886283984) <= 1e-12 * max(1, abs(0.41782387886283984)))
        }
        do {
            // CD-146: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21, 24, 25, 28, 30, 31],
                [9, 14, 15, 18, 20, 22, 23, 26, 27, 29, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.2807363576594346) <= 1e-12 * max(1, abs(0.2807363576594346)))
        }
        do {
            // CD-147: asynchronousLabelPropagationCommunities(weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 6, 3, 4, 5, 1, 2, 2, 2, 3, 4,
                5, 1, 3, 2, 2, 2, 3, 3, 3, 2, 3, 5, 3, 3, 3, 3, 3, 4, 2, 3, 3, 2, 3, 4, 1, 2, 1, 3, 1, 2, 3,
                5, 4, 3, 5, 4, 2, 3, 2, 7, 4, 2, 4, 2, 2, 4, 2, 3, 3, 4, 4, 5]
            let result = graph.asynchronousLabelPropagationCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 8, 11, 12, 13, 17, 19, 21, 30], [4, 10], [5, 6, 16],
                [9, 15, 18, 22, 27, 28, 33], [14, 20, 23, 26, 29, 32], [24, 25, 31]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q - 0.35829538426941027) <= 1e-12 * max(1, abs(0.35829538426941027)))
        }
    }

    @Test("CD-059 on UndirectedAdjacencyList: U: 0-1, 1-2, 2-3")
    func undirectedAdjacencyList059() {
        // U: 0-1, 1-2, 2-3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3] as [Int])
        do {
            // CD-059: modularity(of: [[0, 1], [2, 3]], weight: [2, 1, 1])
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let w: [Double] = [2, 1, 1]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.21875) <= 1e-12 * max(1, abs(0.21875)))
        }
    }

    @Test("CD-060, CD-061, CD-062, CD-078, CD-079 on UndirectedAdjacencyList: U: 0-1, 1-2, 1-1")
    func undirectedAdjacencyList060() {
        // U: 0-1, 1-2, 1-1
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2] as [Int])
        do {
            // CD-060: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.055555555555555566) <= 1e-12 * max(1, abs(-0.055555555555555566)))
        }
        do {
            // CD-061: modularity(of: [[0, 1], [2]], weight: [1, 1, 3])
            let communities: [[Int]] = [[0, 1], [2]]
            let w: [Double] = [1, 1, 3]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - -0.02000000000000001) <= 1e-12 * max(1, abs(-0.02000000000000001)))
        }
        do {
            // CD-062: directed > modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.directed.modularity(of: communities)
            #expect(abs(value - -0.055555555555555566) <= 1e-12 * max(1, abs(-0.055555555555555566)))
        }
        do {
            // CD-078: partitionQuality(of: [[0, 1], [2]]).coverage
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
        do {
            // CD-079: partitionQuality(of: [[0, 1], [2]]).performance
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
    }

    @Test("CD-063, CD-080, CD-081 on AdjacencyList: D: 0>1, 1>2")
    func adjacencyList063() {
        // D: 0>1, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2] as [Int])
        do {
            // CD-063: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-080: partitionQuality(of: [[0, 1], [2]]).coverage
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.5) <= 1e-12 * max(1, abs(0.5)))
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
        do {
            // CD-081: partitionQuality(of: [[0, 1], [2]]).performance
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.5) <= 1e-12 * max(1, abs(0.5)))
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
    }

    @Test("CD-064, CD-082 on AdjacencyList: D: 0>1, 1>0, 1>2")
    func adjacencyList064() {
        // D: 0>1, 1>0, 1>2
        let pairs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = AdjacencyList(vertices: 0 ..< 3, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2] as [Int])
        do {
            // CD-064: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-082: partitionQuality(of: [[0, 1], [2]]).performance
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
            #expect(abs(quality.performance - 0.8333333333333334) <= 1e-12 * max(1, abs(0.8333333333333334)))
        }
    }

    @Test("CD-065, CD-066, CD-108, CD-131 on AdjacencyList: D: C(0,1,2), C(3,4,5), 2>3")
    func adjacencyList065() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (3, 4), (4, 5), (5, 3), (2, 3)]
        let graph = AdjacencyList(vertices: 0 ..< 6, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
        do {
            // CD-065: modularity(of: [[0, 1, 2], [3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
        do {
            // CD-066: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 2)
            #expect(abs(value - -0.12244897959183676) <= 1e-12 * max(1, abs(-0.12244897959183676)))
        }
        do {
            // CD-108: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
        do {
            // CD-131: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
    }

    @Test("CD-067 on AdjacencyList: D: 0>0, 0>1")
    func adjacencyList067() {
        // D: 0>0, 0>1
        let pairs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = AdjacencyList(vertices: 0 ..< 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1] as [Int])
        do {
            // CD-067: modularity(of: [[0], [1]])
            let communities: [[Int]] = [[0], [1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
    }

    @Test("CD-068 on UndirectedAdjacencyList: U: [a, b, c] a-b, b-c")
    func undirectedAdjacencyList068() {
        // U: [a, b, c] a-b, b-c
        let pairs: [(String, String)] = [("a", "b"), ("b", "c")]
        let listed: [String] = ["a", "b", "c"]
        let graph = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == ["a", "b", "c"] as [String])
        do {
            // CD-068: modularity(of: [[a, b], [c]])
            let communities: [[String]] = [["a", "b"], ["c"]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
    }

    @Test("CD-087, CD-118 on UndirectedAdjacencyList: U: nx(connected_caveman,4,5)")
    func undirectedAdjacencyList087() {
        // U: nx(connected_caveman,4,5)
        let pairs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 19), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (4, 5), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9), (9, 10),
            (10, 12), (10, 13), (10, 14), (11, 12), (11, 13), (11, 14), (12, 13), (12, 14), (13, 14),
            (14, 15), (15, 17), (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 18), (17, 19),
            (18, 19)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 20, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19] as [Int])
        do {
            // CD-087: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14],
                [15, 16, 17, 18, 19]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.65) <= 1e-12 * max(1, abs(0.65)))
        }
        do {
            // CD-118: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14],
                [15, 16, 17, 18, 19]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.65) <= 1e-12 * max(1, abs(0.65)))
        }
    }

    @Test("CD-096, CD-124 on UndirectedAdjacencyList: U: nx(florentine_families)")
    func undirectedAdjacencyList096() {
        // U: nx(florentine_families)
        let pairs: [(String, String)] = [("Acciaiuoli", "Medici"), ("Medici", "Barbadori"),
            ("Medici", "Ridolfi"), ("Medici", "Tornabuoni"), ("Medici", "Albizzi"), ("Medici", "Salviati"),
            ("Castellani", "Peruzzi"), ("Castellani", "Strozzi"), ("Castellani", "Barbadori"),
            ("Peruzzi", "Strozzi"), ("Peruzzi", "Bischeri"), ("Strozzi", "Ridolfi"), ("Strozzi", "Bischeri"),
            ("Ridolfi", "Tornabuoni"), ("Tornabuoni", "Guadagni"), ("Albizzi", "Ginori"),
            ("Albizzi", "Guadagni"), ("Salviati", "Pazzi"), ("Bischeri", "Guadagni"),
            ("Guadagni", "Lamberteschi")]
        let listed: [String] = ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori",
            "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori",
            "Lamberteschi"]
        let graph = UndirectedAdjacencyList(vertices: listed, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == ["Acciaiuoli", "Medici", "Castellani", "Peruzzi", "Strozzi", "Barbadori", "Ridolfi", "Tornabuoni", "Albizzi", "Salviati", "Pazzi", "Bischeri", "Guadagni", "Ginori", "Lamberteschi"] as [String])
        do {
            // CD-096: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[String]] = [["Acciaiuoli", "Medici", "Barbadori", "Ridolfi", "Tornabuoni"],
                ["Castellani", "Peruzzi", "Strozzi", "Bischeri"],
                ["Albizzi", "Guadagni", "Ginori", "Lamberteschi"], ["Salviati", "Pazzi"]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.3975) <= 1e-12 * max(1, abs(0.3975)))
        }
        do {
            // CD-124: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[String]] = [["Acciaiuoli", "Medici", "Ridolfi", "Tornabuoni", "Salviati", "Pazzi"],
                ["Castellani", "Peruzzi", "Strozzi", "Barbadori", "Bischeri"],
                ["Albizzi", "Guadagni", "Ginori", "Lamberteschi"]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.39874999999999994) <= 1e-12 * max(1, abs(0.39874999999999994)))
        }
    }

    @Test("CD-099 on UndirectedAdjacencyList: U: K(0..2), K(3..5), 2-3, 0-0, 4-4")
    func undirectedAdjacencyList099() {
        // U: K(0..2), K(3..5), 2-3, 0-0, 4-4
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (1, 2), (3, 4), (3, 5), (4, 5), (2, 3), (0, 0), (4, 4)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
        do {
            // CD-099: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.38888888888888884) <= 1e-12 * max(1, abs(0.38888888888888884)))
        }
    }

    @Test("CD-101, CD-125 on UndirectedAdjacencyList: U: P(0,1,2,3,4,5,6,7)")
    func undirectedAdjacencyList101() {
        // U: P(0,1,2,3,4,5,6,7)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 8, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7] as [Int])
        do {
            // CD-101: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-125: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
    }

    @Test("CD-102, CD-126 on UndirectedAdjacencyList: U: C(0,1,2,3,4,5,6,7,8,9)")
    func undirectedAdjacencyList102() {
        // U: C(0,1,2,3,4,5,6,7,8,9)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (6, 7), (7, 8), (8, 9),
            (9, 0)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        do {
            // CD-102: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 9], [3, 4, 5, 6], [7, 8]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.33999999999999997) <= 1e-12 * max(1, abs(0.33999999999999997)))
        }
        do {
            // CD-126: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.33999999999999997) <= 1e-12 * max(1, abs(0.33999999999999997)))
        }
    }

    @Test("CD-103 on UndirectedAdjacencyList: U: S(0;1..6)")
    func undirectedAdjacencyList103() {
        // U: S(0;1..6)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 7, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6] as [Int])
        do {
            // CD-103: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-104 on UndirectedAdjacencyList: U: grid(4,4)")
    func undirectedAdjacencyList104() {
        // U: grid(4,4)
        let pairs: [(Int, Int)] = [(0, 1), (0, 4), (1, 2), (1, 5), (2, 3), (2, 6), (3, 7), (4, 5), (4, 8),
            (5, 6), (5, 9), (6, 7), (6, 10), (7, 11), (8, 9), (8, 12), (9, 10), (9, 13), (10, 11), (10, 14),
            (11, 15), (12, 13), (13, 14), (14, 15)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 16, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15] as [Int])
        do {
            // CD-104: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 4, 5], [2, 3, 6, 7], [8, 9, 12, 13], [10, 11, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.41666666666666663) <= 1e-12 * max(1, abs(0.41666666666666663)))
        }
    }

    @Test("CD-109 on AdjacencyList: D: nx(karate_club)")
    func adjacencyList109() {
        // D: nx(karate_club)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = AdjacencyList(vertices: 0 ..< 34, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33] as [Int])
        do {
            // CD-109: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.43622616699539773) <= 1e-12 * max(1, abs(0.43622616699539773)))
        }
    }

    @Test("CD-112, CD-153 on UndirectedAdjacencyList: U: K(0..4), K(5..9)")
    func undirectedAdjacencyList112() {
        // U: K(0..4), K(5..9)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4),
            (3, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 8), (7, 9), (8, 9)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 10, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9] as [Int])
        do {
            // CD-112: louvainCommunities(using: rng(1))
            var generator = SeededRandomNumberGenerator(seed: 1)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
            var again = SeededRandomNumberGenerator(seed: 1)
            #expect(graph.louvainCommunities(using: &again) == result, "the same seed again")
        }
        do {
            // CD-153: asynchronousLabelPropagationCommunities(using: rng(1))
            var generator = SeededRandomNumberGenerator(seed: 1)
            let result = graph.asynchronousLabelPropagationCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
            var again = SeededRandomNumberGenerator(seed: 1)
            #expect(graph.asynchronousLabelPropagationCommunities(using: &again) == result, "the same seed again")
        }
    }

    @Test("CD-139, CD-148 on UndirectedAdjacencyList: U: P(0,1,2,3,4,5)")
    func undirectedAdjacencyList139() {
        // U: P(0,1,2,3,4,5)
        let pairs: [(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 6, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5] as [Int])
        do {
            // CD-139: labelPropagationCommunities()
            let result = graph.labelPropagationCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.30000000000000004) <= 1e-12 * max(1, abs(0.30000000000000004)))
        }
        do {
            // CD-148: asynchronousLabelPropagationCommunities()
            let result = graph.asynchronousLabelPropagationCommunities()
            let expected: [[Int]] = [[0, 1], [2, 3], [4, 5]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.26) <= 1e-12 * max(1, abs(0.26)))
        }
    }

    @Test("CD-150 on UndirectedAdjacencyList: U: 0-1, 1-2")
    func undirectedAdjacencyList150() {
        // U: 0-1, 1-2
        let pairs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 3, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2] as [Int])
        do {
            // CD-150: asynchronousLabelPropagationCommunities(weight: [1, 3])
            let w: [Double] = [1, 3]
            let result = graph.asynchronousLabelPropagationCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1, 2]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-154 on UndirectedAdjacencyList: U: K(0..3), K(4..7), K(8..11)")
    func undirectedAdjacencyList154() {
        // U: K(0..3), K(4..7), K(8..11)
        let pairs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 5), (4, 6), (4, 7),
            (5, 6), (5, 7), (6, 7), (8, 9), (8, 10), (8, 11), (9, 10), (9, 11), (10, 11)]
        let graph = UndirectedAdjacencyList(vertices: 0 ..< 12, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] as [Int])
        do {
            // CD-154: asynchronousLabelPropagationCommunities(using: rng(9))
            var generator = SeededRandomNumberGenerator(seed: 9)
            let result = graph.asynchronousLabelPropagationCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11]]
            #expect(result.map { Array($0) } == expected)
            #expect(result.count == expected.count)
            for (c, community) in expected.enumerated() {
                for v in community {
                    #expect(result.community(of: v) == c, "vertex \(v)")
                }
            }
            for (i, v) in graph.vertices.enumerated() {
                #expect(result.community(ofIndex: i) == result.community(of: v), "index \(i)")
            }
            // The modularity of the result (ref.py's model).
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
            var again = SeededRandomNumberGenerator(seed: 9)
            #expect(graph.asynchronousLabelPropagationCommunities(using: &again) == result, "the same seed again")
        }
    }

    @Test("CD-001, CD-002, CD-003, CD-004, CD-005, CD-006 on CompressedSparseRow, as symmetric arcs: U: []")
    func compressedSparseRow001() {
        // U: [] (each edge as two arcs)
        let graph = CompressedSparseRow(vertexCount: 0)
        do {
            // CD-001: modularity(of: [])
            let communities: [[Int]] = []
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-002: partitionQuality(of: []).coverage
            let communities: [[Int]] = []
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
        do {
            // CD-003: partitionQuality(of: []).performance
            let communities: [[Int]] = []
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
        do {
            // CD-004: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-005: louvainCommunities().count
            let result = graph.louvainCommunities()
            #expect(result.count == 0)
        }
        do {
            // CD-006: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-001, CD-002, CD-003, CD-004, CD-005, CD-006 on AdjacencyMatrix, as symmetric arcs: U: []")
    func adjacencyMatrix001() {
        // U: [] (each edge as two arcs)
        let graph = AdjacencyMatrix(vertexCount: 0)
        do {
            // CD-001: modularity(of: [])
            let communities: [[Int]] = []
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-002: partitionQuality(of: []).coverage
            let communities: [[Int]] = []
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
        do {
            // CD-003: partitionQuality(of: []).performance
            let communities: [[Int]] = []
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
        do {
            // CD-004: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-005: louvainCommunities().count
            let result = graph.louvainCommunities()
            #expect(result.count == 0)
        }
        do {
            // CD-006: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-009 on CompressedSparseRow, arcs in row-major order: D: []")
    func compressedSparseRow009() {
        // D: []
        let graph = CompressedSparseRow(vertexCount: 0)
        do {
            // CD-009: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-009 on AdjacencyMatrix, arcs in row-major order: D: []")
    func adjacencyMatrix009() {
        // D: []
        let graph = AdjacencyMatrix(vertexCount: 0)
        do {
            // CD-009: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = []
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-010, CD-011, CD-012, CD-015 on CompressedSparseRow, as symmetric arcs: U: [0]")
    func compressedSparseRow010() {
        // U: [0] (each edge as two arcs)
        let graph = CompressedSparseRow(vertexCount: 1)
        do {
            // CD-010: modularity(of: [[0]])
            let communities: [[Int]] = [[0]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-011: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-012: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-015: partitionQuality(of: [[0]]).performance
            let communities: [[Int]] = [[0]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
    }

    @Test("CD-010, CD-011, CD-012, CD-015 on AdjacencyMatrix, as symmetric arcs: U: [0]")
    func adjacencyMatrix010() {
        // U: [0] (each edge as two arcs)
        let graph = AdjacencyMatrix(vertexCount: 1)
        do {
            // CD-010: modularity(of: [[0]])
            let communities: [[Int]] = [[0]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-011: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-012: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-015: partitionQuality(of: [[0]]).performance
            let communities: [[Int]] = [[0]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(quality.performance.isNaN)
        }
    }

    @Test("CD-016, CD-017, CD-018, CD-021, CD-022 on CompressedSparseRow, as symmetric arcs: U: [0..3]")
    func compressedSparseRow016() {
        // U: [0..3] (each edge as two arcs)
        let graph = CompressedSparseRow(vertexCount: 4)
        do {
            // CD-016: modularity(of: [[0, 1], [2, 3]])
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-017: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0], [1], [2], [3]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-018: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0], [1], [2], [3]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-021: partitionQuality(of: [[0, 1], [2, 3]]).coverage
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
        do {
            // CD-022: partitionQuality(of: [[0, 1], [2, 3]]).performance
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
    }

    @Test("CD-016, CD-017, CD-018, CD-021, CD-022 on AdjacencyMatrix, as symmetric arcs: U: [0..3]")
    func adjacencyMatrix016() {
        // U: [0..3] (each edge as two arcs)
        let graph = AdjacencyMatrix(vertexCount: 4)
        do {
            // CD-016: modularity(of: [[0, 1], [2, 3]])
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-017: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0], [1], [2], [3]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-018: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0], [1], [2], [3]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-021: partitionQuality(of: [[0, 1], [2, 3]]).coverage
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
        do {
            // CD-022: partitionQuality(of: [[0, 1], [2, 3]]).performance
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let quality = graph.partitionQuality(of: communities)
            #expect(quality.coverage.isNaN)
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
    }

    @Test("CD-029, CD-030 on CompressedSparseRow, as symmetric arcs: U: 0-1")
    func compressedSparseRow029() {
        // U: 0-1 (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = CompressedSparseRow(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-029: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-030: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-029, CD-030 on AdjacencyMatrix, as symmetric arcs: U: 0-1")
    func adjacencyMatrix029() {
        // U: 0-1 (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (1, 0)]
        let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-029: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-030: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-033, CD-034 on CompressedSparseRow, arcs in row-major order: D: 0>1")
    func compressedSparseRow033() {
        // D: 0>1
        let arcs: [(Int, Int)] = [(0, 1)]
        let graph = CompressedSparseRow(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-033: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0], [1]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-034: modularity(of: [[0, 1]])
            let communities: [[Int]] = [[0, 1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
    }

    @Test("CD-033, CD-034 on AdjacencyMatrix, arcs in row-major order: D: 0>1")
    func adjacencyMatrix033() {
        // D: 0>1
        let arcs: [(Int, Int)] = [(0, 1)]
        let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-033: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0], [1]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-034: modularity(of: [[0, 1]])
            let communities: [[Int]] = [[0, 1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
    }

    @Test("CD-035, CD-036, CD-037, CD-038, CD-039, CD-173, CD-174 on CompressedSparseRow, as symmetric arcs: U: P(0,1,2)")
    func compressedSparseRow035() {
        // U: P(0,1,2) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-035: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-036: modularity(of: [[0, 1, 2]])
            let communities: [[Int]] = [[0, 1, 2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-037: modularity(of: [[0], [1], [2]])
            let communities: [[Int]] = [[0], [1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.375) <= 1e-12 * max(1, abs(-0.375)))
        }
        do {
            // CD-038: modularity(of: [[2], [0, 1]])
            let communities: [[Int]] = [[2], [0, 1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-039: modularity(of: [[0, 1], [], [2]])
            let communities: [[Int]] = [[0, 1], [], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-173: greedyModularityCommunities(weight: [0, 0])
            let w: [Double] = [0, 0, 0, 0]
            let result = graph.greedyModularityCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0], [1], [2]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-174: louvainCommunities(weight: [0, 0])
            let w: [Double] = [0, 0, 0, 0]
            let result = graph.louvainCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0], [1], [2]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-035, CD-036, CD-037, CD-038, CD-039, CD-173, CD-174 on AdjacencyMatrix, as symmetric arcs: U: P(0,1,2)")
    func adjacencyMatrix035() {
        // U: P(0,1,2) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-035: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-036: modularity(of: [[0, 1, 2]])
            let communities: [[Int]] = [[0, 1, 2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-037: modularity(of: [[0], [1], [2]])
            let communities: [[Int]] = [[0], [1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.375) <= 1e-12 * max(1, abs(-0.375)))
        }
        do {
            // CD-038: modularity(of: [[2], [0, 1]])
            let communities: [[Int]] = [[2], [0, 1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-039: modularity(of: [[0, 1], [], [2]])
            let communities: [[Int]] = [[0, 1], [], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.125) <= 1e-12 * max(1, abs(-0.125)))
        }
        do {
            // CD-173: greedyModularityCommunities(weight: [0, 0])
            let w: [Double] = [0, 0, 0, 0]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let result = graph.greedyModularityCommunities(weight: { weightOf[graph.edges[$0]]! })
            let expected: [[Int]] = [[0], [1], [2]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(q) <= 1e-12)
        }
        do {
            // CD-174: louvainCommunities(weight: [0, 0])
            let w: [Double] = [0, 0, 0, 0]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let result = graph.louvainCommunities(weight: { weightOf[graph.edges[$0]]! })
            let expected: [[Int]] = [[0], [1], [2]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-040, CD-041 on CompressedSparseRow, as symmetric arcs: U: K(4)")
    func compressedSparseRow040() {
        // U: K(4) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3),
            (3, 0), (3, 1), (3, 2)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-040: modularity(of: [[0, 1, 2, 3]])
            let communities: [[Int]] = [[0, 1, 2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-041: modularity(of: [[0, 1], [2, 3]])
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.16666666666666669) <= 1e-12 * max(1, abs(-0.16666666666666669)))
        }
    }

    @Test("CD-040, CD-041 on AdjacencyMatrix, as symmetric arcs: U: K(4)")
    func adjacencyMatrix040() {
        // U: K(4) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (1, 0), (1, 2), (1, 3), (2, 0), (2, 1), (2, 3),
            (3, 0), (3, 1), (3, 2)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-040: modularity(of: [[0, 1, 2, 3]])
            let communities: [[Int]] = [[0, 1, 2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-041: modularity(of: [[0, 1], [2, 3]])
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - -0.16666666666666669) <= 1e-12 * max(1, abs(-0.16666666666666669)))
        }
    }

    @Test("CD-042, CD-043, CD-044, CD-045, CD-046, CD-047, CD-048, CD-049, CD-050, CD-069, CD-070, CD-071, CD-072, CD-073, CD-083, CD-100, CD-115 on CompressedSparseRow, as symmetric arcs: U: K(0..2), K(3..5), 2-3")
    func compressedSparseRow042() {
        // U: K(0..2), K(3..5), 2-3 (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1), (2, 3), (3, 2), (3, 4),
            (3, 5), (4, 3), (4, 5), (5, 3), (5, 4)]
        let graph = CompressedSparseRow(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-042: modularity(of: [[0, 1, 2], [3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-043: modularity(of: [[0, 1, 2, 3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        }
        do {
            // CD-044: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 0)
            #expect(abs(value - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
        }
        do {
            // CD-045: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 0.5)
            #expect(abs(value - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-046: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 2)
            #expect(abs(value - -0.1428571428571428) <= 1e-12 * max(1, abs(-0.1428571428571428)))
        }
        do {
            // CD-047: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 5])
            let w: [Double] = [1, 1, 1, 1, 1, 1, 5, 5, 1, 1, 1, 1, 1, 1]
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.045454545454545414) <= 1e-12 * max(1, abs(0.045454545454545414)))
        }
        do {
            // CD-048: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
            let w: [Double] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-049: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 0])
            let w: [Double] = [1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1]
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-050: modularity(of: components)
            let communities = graph.weaklyConnectedComponents()
            let value = graph.modularity(of: communities)
            #expect(abs(value - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        }
        do {
            // CD-069: partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).coverage
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
            #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)))
        }
        do {
            // CD-070: partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).performance
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
            #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)))
        }
        do {
            // CD-071: partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).coverage
            let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage) <= 1e-12)
            #expect(abs(quality.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)))
        }
        do {
            // CD-072: partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).performance
            let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage) <= 1e-12)
            #expect(abs(quality.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)))
        }
        do {
            // CD-073: partitionQuality(of: components).performance
            let communities = graph.weaklyConnectedComponents()
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 1) <= 1e-12 * max(1, abs(1)))
            #expect(abs(quality.performance - 0.4666666666666667) <= 1e-12 * max(1, abs(0.4666666666666667)))
        }
        do {
            // CD-083: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-100: louvainCommunities(weight: [1, 1, 1, 1, 1, 1, 10])
            let w: [Double] = [1, 1, 1, 1, 1, 1, 10, 10, 1, 1, 1, 1, 1, 1]
            let result = graph.louvainCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1], [2, 3], [4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q - 0.15625) <= 1e-12 * max(1, abs(0.15625)))
        }
        do {
            // CD-115: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
    }

    @Test("CD-042, CD-043, CD-044, CD-045, CD-046, CD-047, CD-048, CD-049, CD-050, CD-069, CD-070, CD-071, CD-072, CD-073, CD-083, CD-100, CD-115 on AdjacencyMatrix, as symmetric arcs: U: K(0..2), K(3..5), 2-3")
    func adjacencyMatrix042() {
        // U: K(0..2), K(3..5), 2-3 (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1), (2, 3), (3, 2), (3, 4),
            (3, 5), (4, 3), (4, 5), (5, 3), (5, 4)]
        let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-042: modularity(of: [[0, 1, 2], [3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-043: modularity(of: [[0, 1, 2, 3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        }
        do {
            // CD-044: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 0)
            #expect(abs(value - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
        }
        do {
            // CD-045: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 0.5)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 0.5)
            #expect(abs(value - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-046: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 2)
            #expect(abs(value - -0.1428571428571428) <= 1e-12 * max(1, abs(-0.1428571428571428)))
        }
        do {
            // CD-047: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 5])
            let w: [Double] = [1, 1, 1, 1, 1, 1, 5, 5, 1, 1, 1, 1, 1, 1]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(value - 0.045454545454545414) <= 1e-12 * max(1, abs(0.045454545454545414)))
        }
        do {
            // CD-048: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
            let w: [Double] = [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(value - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-049: modularity(of: [[0, 1, 2], [3, 4, 5]], weight: [1, 1, 1, 1, 1, 1, 0])
            let w: [Double] = [1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-050: modularity(of: components)
            let communities = graph.weaklyConnectedComponents()
            let value = graph.modularity(of: communities)
            #expect(abs(value - 1.1102230246251565e-16) <= 1e-12 * max(1, abs(1.1102230246251565e-16)))
        }
        do {
            // CD-069: partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).coverage
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
            #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)))
        }
        do {
            // CD-070: partitionQuality(of: [[0, 1, 2], [3, 4, 5]]).performance
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8571428571428571) <= 1e-12 * max(1, abs(0.8571428571428571)))
            #expect(abs(quality.performance - 0.9333333333333333) <= 1e-12 * max(1, abs(0.9333333333333333)))
        }
        do {
            // CD-071: partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).coverage
            let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage) <= 1e-12)
            #expect(abs(quality.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)))
        }
        do {
            // CD-072: partitionQuality(of: [[0], [1], [2], [3], [4], [5]]).performance
            let communities: [[Int]] = [[0], [1], [2], [3], [4], [5]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage) <= 1e-12)
            #expect(abs(quality.performance - 0.5333333333333333) <= 1e-12 * max(1, abs(0.5333333333333333)))
        }
        do {
            // CD-073: partitionQuality(of: components).performance
            let communities = graph.weaklyConnectedComponents()
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 1) <= 1e-12 * max(1, abs(1)))
            #expect(abs(quality.performance - 0.4666666666666667) <= 1e-12 * max(1, abs(0.4666666666666667)))
        }
        do {
            // CD-083: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-100: louvainCommunities(weight: [1, 1, 1, 1, 1, 1, 10])
            let w: [Double] = [1, 1, 1, 1, 1, 1, 10, 10, 1, 1, 1, 1, 1, 1]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let result = graph.louvainCommunities(weight: { weightOf[graph.edges[$0]]! })
            let expected: [[Int]] = [[0, 1], [2, 3], [4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(q - 0.15625) <= 1e-12 * max(1, abs(0.15625)))
        }
        do {
            // CD-115: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
    }

    @Test("CD-051, CD-097, CD-128 on CompressedSparseRow, as symmetric arcs: U: K(0..2), K(3..5)")
    func compressedSparseRow051() {
        // U: K(0..2), K(3..5) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1), (3, 4), (3, 5), (4, 3),
            (4, 5), (5, 3), (5, 4)]
        let graph = CompressedSparseRow(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-051: modularity(of: components)
            let communities = graph.weaklyConnectedComponents()
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-097: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-128: greedyModularityCommunities(resolution: 0)
            let result = graph.greedyModularityCommunities(resolution: 0)
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 0)
            #expect(abs(q - 1) <= 1e-12 * max(1, abs(1)))
        }
    }

    @Test("CD-051, CD-097, CD-128 on AdjacencyMatrix, as symmetric arcs: U: K(0..2), K(3..5)")
    func adjacencyMatrix051() {
        // U: K(0..2), K(3..5) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1), (3, 4), (3, 5), (4, 3),
            (4, 5), (5, 3), (5, 4)]
        let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-051: modularity(of: components)
            let communities = graph.weaklyConnectedComponents()
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-097: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
        do {
            // CD-128: greedyModularityCommunities(resolution: 0)
            let result = graph.greedyModularityCommunities(resolution: 0)
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 0)
            #expect(abs(q - 1) <= 1e-12 * max(1, abs(1)))
        }
    }

    @Test("CD-052, CD-084, CD-114, CD-116 on CompressedSparseRow, as symmetric arcs: U: K(0..4), K(5..9), 4-5")
    func compressedSparseRow052() {
        // U: K(0..4), K(5..9), 4-5 (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0),
            (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5),
            (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 5), (6, 7), (6, 8), (6, 9), (7, 5), (7, 6), (7, 8),
            (7, 9), (8, 5), (8, 6), (8, 7), (8, 9), (9, 5), (9, 6), (9, 7), (9, 8)]
        let graph = CompressedSparseRow(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-052: modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-084: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-114: louvainCommunities(using: rng(3))
            var generator = SeededRandomNumberGenerator(seed: 3)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-116: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
    }

    @Test("CD-052, CD-084, CD-114, CD-116 on AdjacencyMatrix, as symmetric arcs: U: K(0..4), K(5..9), 4-5")
    func adjacencyMatrix052() {
        // U: K(0..4), K(5..9), 4-5 (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0),
            (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5),
            (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 5), (6, 7), (6, 8), (6, 9), (7, 5), (7, 6), (7, 8),
            (7, 9), (8, 5), (8, 6), (8, 7), (8, 9), (9, 5), (9, 6), (9, 7), (9, 8)]
        let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-052: modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-084: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-114: louvainCommunities(using: rng(3))
            var generator = SeededRandomNumberGenerator(seed: 3)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-116: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
    }

    @Test("CD-053, CD-085 on CompressedSparseRow, as symmetric arcs: U: nx(barbell,5,0)")
    func compressedSparseRow053() {
        // U: nx(barbell,5,0) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0),
            (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5),
            (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 5), (6, 7), (6, 8), (6, 9), (7, 5), (7, 6), (7, 8),
            (7, 9), (8, 5), (8, 6), (8, 7), (8, 9), (9, 5), (9, 6), (9, 7), (9, 8)]
        let graph = CompressedSparseRow(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-053: modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-085: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
    }

    @Test("CD-053, CD-085 on AdjacencyMatrix, as symmetric arcs: U: nx(barbell,5,0)")
    func adjacencyMatrix053() {
        // U: nx(barbell,5,0) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0),
            (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5),
            (5, 4), (5, 6), (5, 7), (5, 8), (5, 9), (6, 5), (6, 7), (6, 8), (6, 9), (7, 5), (7, 6), (7, 8),
            (7, 9), (8, 5), (8, 6), (8, 7), (8, 9), (9, 5), (9, 6), (9, 7), (9, 8)]
        let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-053: modularity(of: [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]])
            let communities: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
        do {
            // CD-085: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.45238095238095233) <= 1e-12 * max(1, abs(0.45238095238095233)))
        }
    }

    @Test("CD-054, CD-086, CD-113, CD-117 on CompressedSparseRow, as symmetric arcs: U: nx(ring_of_cliques,4,4)")
    func compressedSparseRow054() {
        // U: nx(ring_of_cliques,4,4) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0),
            (2, 1), (2, 3), (3, 0), (3, 1), (3, 2), (4, 1), (4, 5), (4, 6), (4, 7), (5, 4), (5, 6), (5, 7),
            (5, 8), (6, 4), (6, 5), (6, 7), (7, 4), (7, 5), (7, 6), (8, 5), (8, 9), (8, 10), (8, 11), (9, 8),
            (9, 10), (9, 11), (9, 12), (10, 8), (10, 9), (10, 11), (11, 8), (11, 9), (11, 10), (12, 9),
            (12, 13), (12, 14), (12, 15), (13, 0), (13, 12), (13, 14), (13, 15), (14, 12), (14, 13),
            (14, 15), (15, 12), (15, 13), (15, 14)]
        let graph = CompressedSparseRow(vertexCount: 16, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-054: modularity(of: […])
            let communities: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-086: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-113: louvainCommunities(using: rng(2))
            var generator = SeededRandomNumberGenerator(seed: 2)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-117: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
    }

    @Test("CD-054, CD-086, CD-113, CD-117 on AdjacencyMatrix, as symmetric arcs: U: nx(ring_of_cliques,4,4)")
    func adjacencyMatrix054() {
        // U: nx(ring_of_cliques,4,4) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 13), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0),
            (2, 1), (2, 3), (3, 0), (3, 1), (3, 2), (4, 1), (4, 5), (4, 6), (4, 7), (5, 4), (5, 6), (5, 7),
            (5, 8), (6, 4), (6, 5), (6, 7), (7, 4), (7, 5), (7, 6), (8, 5), (8, 9), (8, 10), (8, 11), (9, 8),
            (9, 10), (9, 11), (9, 12), (10, 8), (10, 9), (10, 11), (11, 8), (11, 9), (11, 10), (12, 9),
            (12, 13), (12, 14), (12, 15), (13, 0), (13, 12), (13, 14), (13, 15), (14, 12), (14, 13),
            (14, 15), (15, 12), (15, 13), (15, 14)]
        let graph = AdjacencyMatrix(vertexCount: 16, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-054: modularity(of: […])
            let communities: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-086: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-113: louvainCommunities(using: rng(2))
            var generator = SeededRandomNumberGenerator(seed: 2)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
        do {
            // CD-117: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9, 10, 11], [12, 13, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.6071428571428571) <= 1e-12 * max(1, abs(0.6071428571428571)))
        }
    }

    @Test("CD-055, CD-056, CD-074, CD-075, CD-088, CD-089, CD-090, CD-091, CD-092, CD-093, CD-094, CD-095, CD-119, CD-120, CD-121, CD-122, CD-123 on CompressedSparseRow, as symmetric arcs: U: nx(karate_club)")
    func compressedSparseRow055() {
        // U: nx(karate_club) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 0), (1, 2), (1, 3), (1, 7),
            (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 0), (2, 1), (2, 3), (2, 7), (2, 8), (2, 9),
            (2, 13), (2, 27), (2, 28), (2, 32), (3, 0), (3, 1), (3, 2), (3, 7), (3, 12), (3, 13), (4, 0),
            (4, 6), (4, 10), (5, 0), (5, 6), (5, 10), (5, 16), (6, 0), (6, 4), (6, 5), (6, 16), (7, 0),
            (7, 1), (7, 2), (7, 3), (8, 0), (8, 2), (8, 30), (8, 32), (8, 33), (9, 2), (9, 33), (10, 0),
            (10, 4), (10, 5), (11, 0), (12, 0), (12, 3), (13, 0), (13, 1), (13, 2), (13, 3), (13, 33),
            (14, 32), (14, 33), (15, 32), (15, 33), (16, 5), (16, 6), (17, 0), (17, 1), (18, 32), (18, 33),
            (19, 0), (19, 1), (19, 33), (20, 32), (20, 33), (21, 0), (21, 1), (22, 32), (22, 33), (23, 25),
            (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 23), (25, 24),
            (25, 31), (26, 29), (26, 33), (27, 2), (27, 23), (27, 24), (27, 33), (28, 2), (28, 31), (28, 33),
            (29, 23), (29, 26), (29, 32), (29, 33), (30, 1), (30, 8), (30, 32), (30, 33), (31, 0), (31, 24),
            (31, 25), (31, 28), (31, 32), (31, 33), (32, 2), (32, 8), (32, 14), (32, 15), (32, 18), (32, 20),
            (32, 22), (32, 23), (32, 29), (32, 30), (32, 31), (32, 33), (33, 8), (33, 9), (33, 13), (33, 14),
            (33, 15), (33, 18), (33, 19), (33, 20), (33, 22), (33, 23), (33, 26), (33, 27), (33, 28),
            (33, 29), (33, 30), (33, 31), (33, 32)]
        let graph = CompressedSparseRow(vertexCount: 34, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-055: modularity(of: […])
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.3582347140039448) <= 1e-12 * max(1, abs(0.3582347140039448)))
        }
        do {
            // CD-056: modularity(of: […], weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 4, 6, 3, 4, 5, 1, 2, 2, 2, 5,
                6, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 5, 3, 3, 3, 2, 5, 3, 2, 4, 4, 3, 2,
                5, 3, 3, 4, 1, 2, 2, 3, 3, 3, 1, 3, 3, 5, 3, 3, 3, 3, 2, 3, 4, 3, 3, 2, 1, 1, 2, 2, 2, 1, 3,
                1, 2, 2, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 5, 2, 7, 4, 2, 2, 4, 3, 4, 2, 2, 2, 3, 4, 4, 2, 2, 3,
                3, 3, 2, 2, 7, 2, 4, 4, 2, 3, 3, 3, 1, 3, 2, 5, 4, 3, 4, 5, 4, 2, 3, 2, 4, 2, 1, 1, 3, 4, 2,
                4, 2, 2, 3, 4, 5]
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.39143756676224206) <= 1e-12 * max(1, abs(0.39143756676224206)))
        }
        do {
            // CD-074: partitionQuality(of: […]).coverage
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)))
            #expect(abs(quality.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)))
        }
        do {
            // CD-075: partitionQuality(of: […]).performance
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)))
            #expect(abs(quality.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)))
        }
        do {
            // CD-088: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.41880341880341876) <= 1e-12 * max(1, abs(0.41880341880341876)))
        }
        do {
            // CD-089: louvainCommunities().count
            let result = graph.louvainCommunities()
            #expect(result.count == 4)
        }
        do {
            // CD-090: louvainCommunities().community(of: 33)
            let result = graph.louvainCommunities()
            #expect(result.community(of: 33) == 2)
        }
        do {
            // CD-091: louvainCommunities(weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 4, 6, 3, 4, 5, 1, 2, 2, 2, 5,
                6, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 5, 3, 3, 3, 2, 5, 3, 2, 4, 4, 3, 2,
                5, 3, 3, 4, 1, 2, 2, 3, 3, 3, 1, 3, 3, 5, 3, 3, 3, 3, 2, 3, 4, 3, 3, 2, 1, 1, 2, 2, 2, 1, 3,
                1, 2, 2, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 5, 2, 7, 4, 2, 2, 4, 3, 4, 2, 2, 2, 3, 4, 4, 2, 2, 3,
                3, 3, 2, 2, 7, 2, 4, 4, 2, 3, 3, 3, 1, 3, 2, 5, 4, 3, 4, 5, 4, 2, 3, 2, 4, 2, 1, 1, 3, 4, 2,
                4, 2, 2, 3, 4, 5]
            let result = graph.louvainCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q - 0.44490358126721763) <= 1e-12 * max(1, abs(0.44490358126721763)))
        }
        do {
            // CD-092: louvainCommunities(resolution: 0.5)
            let result = graph.louvainCommunities(resolution: 0.5)
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21],
                [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 0.5)
            #expect(abs(q - 0.6217948717948718) <= 1e-12 * max(1, abs(0.6217948717948718)))
        }
        do {
            // CD-093: louvainCommunities(resolution: 2)
            let result = graph.louvainCommunities(resolution: 2)
            let expected: [[Int]] = [[0, 1, 11, 12, 17, 19, 21], [2, 3, 7, 13], [4, 5, 6, 10, 16], [8, 30],
                [9, 26, 29, 33], [14, 15, 18, 20, 22, 32], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 2)
            #expect(abs(q - 0.1561472715318869) <= 1e-12 * max(1, abs(0.1561472715318869)))
        }
        do {
            // CD-094: louvainCommunities(resolution: 0)
            let result = graph.louvainCommunities(resolution: 0)
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 0)
            #expect(abs(q - 1) <= 1e-12 * max(1, abs(1)))
        }
        do {
            // CD-095: louvainCommunities(threshold: 1)
            let result = graph.louvainCommunities(threshold: 1)
            let expected: [[Int]] = [[0, 1, 11, 17, 19, 21], [2, 3, 7, 9, 12, 13], [4, 10], [5, 6, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.3613576594345825) <= 1e-12 * max(1, abs(0.3613576594345825)))
        }
        do {
            // CD-119: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16, 19], [1, 2, 3, 7, 9, 12, 13, 17, 21],
                [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.3806706114398422) <= 1e-12 * max(1, abs(0.3806706114398422)))
        }
        do {
            // CD-120: greedyModularityCommunities().count
            let result = graph.greedyModularityCommunities()
            #expect(result.count == 3)
        }
        do {
            // CD-121: greedyModularityCommunities(weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 4, 6, 3, 4, 5, 1, 2, 2, 2, 5,
                6, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 5, 3, 3, 3, 2, 5, 3, 2, 4, 4, 3, 2,
                5, 3, 3, 4, 1, 2, 2, 3, 3, 3, 1, 3, 3, 5, 3, 3, 3, 3, 2, 3, 4, 3, 3, 2, 1, 1, 2, 2, 2, 1, 3,
                1, 2, 2, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 5, 2, 7, 4, 2, 2, 4, 3, 4, 2, 2, 2, 3, 4, 4, 2, 2, 3,
                3, 3, 2, 2, 7, 2, 4, 4, 2, 3, 3, 3, 1, 3, 2, 5, 4, 3, 4, 5, 4, 2, 3, 2, 4, 2, 1, 1, 3, 4, 2,
                4, 2, 2, 3, 4, 5]
            let result = graph.greedyModularityCommunities(weight: { w[$0] })
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { w[$0] })
            #expect(abs(q - 0.4345214669889994) <= 1e-12 * max(1, abs(0.4345214669889994)))
        }
        do {
            // CD-122: greedyModularityCommunities(resolution: 0.5)
            let result = graph.greedyModularityCommunities(resolution: 0.5)
            let expected: [[Int]] = [[0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 16, 17, 19, 21],
                [2, 8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 0.5)
            #expect(abs(q - 0.6158777120315582) <= 1e-12 * max(1, abs(0.6158777120315582)))
        }
        do {
            // CD-123: greedyModularityCommunities(resolution: 2)
            let result = graph.greedyModularityCommunities(resolution: 2)
            let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16], [1, 17, 19, 21], [2, 9, 28], [3, 7, 12, 13],
                [8, 30], [14, 15, 18, 20, 22, 26, 29, 32, 33], [23, 24, 25, 27, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 2)
            #expect(abs(q - 0.16354372123602892) <= 1e-12 * max(1, abs(0.16354372123602892)))
        }
    }

    @Test("CD-055, CD-056, CD-074, CD-075, CD-088, CD-089, CD-090, CD-091, CD-092, CD-093, CD-094, CD-095, CD-119, CD-120, CD-121, CD-122, CD-123 on AdjacencyMatrix, as symmetric arcs: U: nx(karate_club)")
    func adjacencyMatrix055() {
        // U: nx(karate_club) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 0), (1, 2), (1, 3), (1, 7),
            (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 0), (2, 1), (2, 3), (2, 7), (2, 8), (2, 9),
            (2, 13), (2, 27), (2, 28), (2, 32), (3, 0), (3, 1), (3, 2), (3, 7), (3, 12), (3, 13), (4, 0),
            (4, 6), (4, 10), (5, 0), (5, 6), (5, 10), (5, 16), (6, 0), (6, 4), (6, 5), (6, 16), (7, 0),
            (7, 1), (7, 2), (7, 3), (8, 0), (8, 2), (8, 30), (8, 32), (8, 33), (9, 2), (9, 33), (10, 0),
            (10, 4), (10, 5), (11, 0), (12, 0), (12, 3), (13, 0), (13, 1), (13, 2), (13, 3), (13, 33),
            (14, 32), (14, 33), (15, 32), (15, 33), (16, 5), (16, 6), (17, 0), (17, 1), (18, 32), (18, 33),
            (19, 0), (19, 1), (19, 33), (20, 32), (20, 33), (21, 0), (21, 1), (22, 32), (22, 33), (23, 25),
            (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 23), (25, 24),
            (25, 31), (26, 29), (26, 33), (27, 2), (27, 23), (27, 24), (27, 33), (28, 2), (28, 31), (28, 33),
            (29, 23), (29, 26), (29, 32), (29, 33), (30, 1), (30, 8), (30, 32), (30, 33), (31, 0), (31, 24),
            (31, 25), (31, 28), (31, 32), (31, 33), (32, 2), (32, 8), (32, 14), (32, 15), (32, 18), (32, 20),
            (32, 22), (32, 23), (32, 29), (32, 30), (32, 31), (32, 33), (33, 8), (33, 9), (33, 13), (33, 14),
            (33, 15), (33, 18), (33, 19), (33, 20), (33, 22), (33, 23), (33, 26), (33, 27), (33, 28),
            (33, 29), (33, 30), (33, 31), (33, 32)]
        let graph = AdjacencyMatrix(vertexCount: 34, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-055: modularity(of: […])
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.3582347140039448) <= 1e-12 * max(1, abs(0.3582347140039448)))
        }
        do {
            // CD-056: modularity(of: […], weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 4, 6, 3, 4, 5, 1, 2, 2, 2, 5,
                6, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 5, 3, 3, 3, 2, 5, 3, 2, 4, 4, 3, 2,
                5, 3, 3, 4, 1, 2, 2, 3, 3, 3, 1, 3, 3, 5, 3, 3, 3, 3, 2, 3, 4, 3, 3, 2, 1, 1, 2, 2, 2, 1, 3,
                1, 2, 2, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 5, 2, 7, 4, 2, 2, 4, 3, 4, 2, 2, 2, 3, 4, 4, 2, 2, 3,
                3, 3, 2, 2, 7, 2, 4, 4, 2, 3, 3, 3, 1, 3, 2, 5, 4, 3, 4, 5, 4, 2, 3, 2, 4, 2, 1, 1, 3, 4, 2,
                4, 2, 2, 3, 4, 5]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let value = graph.modularity(of: communities, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(value - 0.39143756676224206) <= 1e-12 * max(1, abs(0.39143756676224206)))
        }
        do {
            // CD-074: partitionQuality(of: […]).coverage
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)))
            #expect(abs(quality.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)))
        }
        do {
            // CD-075: partitionQuality(of: […]).performance
            let communities: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 11, 12, 13, 16, 17, 19, 21],
                [9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.8589743589743589) <= 1e-12 * max(1, abs(0.8589743589743589)))
            #expect(abs(quality.performance - 0.6149732620320856) <= 1e-12 * max(1, abs(0.6149732620320856)))
        }
        do {
            // CD-088: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.41880341880341876) <= 1e-12 * max(1, abs(0.41880341880341876)))
        }
        do {
            // CD-089: louvainCommunities().count
            let result = graph.louvainCommunities()
            #expect(result.count == 4)
        }
        do {
            // CD-090: louvainCommunities().community(of: 33)
            let result = graph.louvainCommunities()
            #expect(result.community(of: 33) == 2)
        }
        do {
            // CD-091: louvainCommunities(weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 4, 6, 3, 4, 5, 1, 2, 2, 2, 5,
                6, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 5, 3, 3, 3, 2, 5, 3, 2, 4, 4, 3, 2,
                5, 3, 3, 4, 1, 2, 2, 3, 3, 3, 1, 3, 3, 5, 3, 3, 3, 3, 2, 3, 4, 3, 3, 2, 1, 1, 2, 2, 2, 1, 3,
                1, 2, 2, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 5, 2, 7, 4, 2, 2, 4, 3, 4, 2, 2, 2, 3, 4, 4, 2, 2, 3,
                3, 3, 2, 2, 7, 2, 4, 4, 2, 3, 3, 3, 1, 3, 2, 5, 4, 3, 4, 5, 4, 2, 3, 2, 4, 2, 1, 1, 3, 4, 2,
                4, 2, 2, 3, 4, 5]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let result = graph.louvainCommunities(weight: { weightOf[graph.edges[$0]]! })
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 9, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(q - 0.44490358126721763) <= 1e-12 * max(1, abs(0.44490358126721763)))
        }
        do {
            // CD-092: louvainCommunities(resolution: 0.5)
            let result = graph.louvainCommunities(resolution: 0.5)
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 16, 17, 19, 21],
                [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 0.5)
            #expect(abs(q - 0.6217948717948718) <= 1e-12 * max(1, abs(0.6217948717948718)))
        }
        do {
            // CD-093: louvainCommunities(resolution: 2)
            let result = graph.louvainCommunities(resolution: 2)
            let expected: [[Int]] = [[0, 1, 11, 12, 17, 19, 21], [2, 3, 7, 13], [4, 5, 6, 10, 16], [8, 30],
                [9, 26, 29, 33], [14, 15, 18, 20, 22, 32], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 2)
            #expect(abs(q - 0.1561472715318869) <= 1e-12 * max(1, abs(0.1561472715318869)))
        }
        do {
            // CD-094: louvainCommunities(resolution: 0)
            let result = graph.louvainCommunities(resolution: 0)
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 0)
            #expect(abs(q - 1) <= 1e-12 * max(1, abs(1)))
        }
        do {
            // CD-095: louvainCommunities(threshold: 1)
            let result = graph.louvainCommunities(threshold: 1)
            let expected: [[Int]] = [[0, 1, 11, 17, 19, 21], [2, 3, 7, 9, 12, 13], [4, 10], [5, 6, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.3613576594345825) <= 1e-12 * max(1, abs(0.3613576594345825)))
        }
        do {
            // CD-119: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16, 19], [1, 2, 3, 7, 9, 12, 13, 17, 21],
                [8, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.3806706114398422) <= 1e-12 * max(1, abs(0.3806706114398422)))
        }
        do {
            // CD-120: greedyModularityCommunities().count
            let result = graph.greedyModularityCommunities()
            #expect(result.count == 3)
        }
        do {
            // CD-121: greedyModularityCommunities(weight: […])
            let w: [Double] = [4, 5, 3, 3, 3, 3, 2, 2, 2, 3, 1, 3, 2, 2, 2, 2, 4, 6, 3, 4, 5, 1, 2, 2, 2, 5,
                6, 3, 4, 5, 1, 3, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 2, 3, 3, 5, 3, 3, 3, 2, 5, 3, 2, 4, 4, 3, 2,
                5, 3, 3, 4, 1, 2, 2, 3, 3, 3, 1, 3, 3, 5, 3, 3, 3, 3, 2, 3, 4, 3, 3, 2, 1, 1, 2, 2, 2, 1, 3,
                1, 2, 2, 2, 3, 5, 4, 3, 5, 4, 2, 3, 2, 5, 2, 7, 4, 2, 2, 4, 3, 4, 2, 2, 2, 3, 4, 4, 2, 2, 3,
                3, 3, 2, 2, 7, 2, 4, 4, 2, 3, 3, 3, 1, 3, 2, 5, 4, 3, 4, 5, 4, 2, 3, 2, 4, 2, 1, 1, 3, 4, 2,
                4, 2, 2, 3, 4, 5]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let result = graph.greedyModularityCommunities(weight: { weightOf[graph.edges[$0]]! })
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(q - 0.4345214669889994) <= 1e-12 * max(1, abs(0.4345214669889994)))
        }
        do {
            // CD-122: greedyModularityCommunities(resolution: 0.5)
            let result = graph.greedyModularityCommunities(resolution: 0.5)
            let expected: [[Int]] = [[0, 1, 3, 4, 5, 6, 7, 10, 11, 12, 13, 16, 17, 19, 21],
                [2, 8, 9, 14, 15, 18, 20, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 0.5)
            #expect(abs(q - 0.6158777120315582) <= 1e-12 * max(1, abs(0.6158777120315582)))
        }
        do {
            // CD-123: greedyModularityCommunities(resolution: 2)
            let result = graph.greedyModularityCommunities(resolution: 2)
            let expected: [[Int]] = [[0, 4, 5, 6, 10, 11, 16], [1, 17, 19, 21], [2, 9, 28], [3, 7, 12, 13],
                [8, 30], [14, 15, 18, 20, 22, 26, 29, 32, 33], [23, 24, 25, 27, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result, resolution: 2)
            #expect(abs(q - 0.16354372123602892) <= 1e-12 * max(1, abs(0.16354372123602892)))
        }
    }

    @Test("CD-059 on CompressedSparseRow, as symmetric arcs: U: 0-1, 1-2, 2-3")
    func compressedSparseRow059() {
        // U: 0-1, 1-2, 2-3 (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1), (2, 3), (3, 2)]
        let graph = CompressedSparseRow(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-059: modularity(of: [[0, 1], [2, 3]], weight: [2, 1, 1])
            let w: [Double] = [2, 2, 1, 1, 1, 1]
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let value = graph.modularity(of: communities, weight: { w[$0] })
            #expect(abs(value - 0.21875) <= 1e-12 * max(1, abs(0.21875)))
        }
    }

    @Test("CD-059 on AdjacencyMatrix, as symmetric arcs: U: 0-1, 1-2, 2-3")
    func adjacencyMatrix059() {
        // U: 0-1, 1-2, 2-3 (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1), (2, 3), (3, 2)]
        let graph = AdjacencyMatrix(vertexCount: 4, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-059: modularity(of: [[0, 1], [2, 3]], weight: [2, 1, 1])
            let w: [Double] = [2, 2, 1, 1, 1, 1]
            let weightOf = Dictionary(uniqueKeysWithValues: zip(graph.edges, w))
            let communities: [[Int]] = [[0, 1], [2, 3]]
            let value = graph.modularity(of: communities, weight: { weightOf[graph.edges[$0]]! })
            #expect(abs(value - 0.21875) <= 1e-12 * max(1, abs(0.21875)))
        }
    }

    @Test("CD-063, CD-080, CD-081 on CompressedSparseRow, arcs in row-major order: D: 0>1, 1>2")
    func compressedSparseRow063() {
        // D: 0>1, 1>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-063: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-080: partitionQuality(of: [[0, 1], [2]]).coverage
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.5) <= 1e-12 * max(1, abs(0.5)))
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
        do {
            // CD-081: partitionQuality(of: [[0, 1], [2]]).performance
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.5) <= 1e-12 * max(1, abs(0.5)))
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
    }

    @Test("CD-063, CD-080, CD-081 on AdjacencyMatrix, arcs in row-major order: D: 0>1, 1>2")
    func adjacencyMatrix063() {
        // D: 0>1, 1>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 2)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-063: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-080: partitionQuality(of: [[0, 1], [2]]).coverage
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.5) <= 1e-12 * max(1, abs(0.5)))
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
        do {
            // CD-081: partitionQuality(of: [[0, 1], [2]]).performance
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.5) <= 1e-12 * max(1, abs(0.5)))
            #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        }
    }

    @Test("CD-064, CD-082 on CompressedSparseRow, arcs in row-major order: D: 0>1, 1>0, 1>2")
    func compressedSparseRow064() {
        // D: 0>1, 1>0, 1>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = CompressedSparseRow(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-064: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-082: partitionQuality(of: [[0, 1], [2]]).performance
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
            #expect(abs(quality.performance - 0.8333333333333334) <= 1e-12 * max(1, abs(0.8333333333333334)))
        }
    }

    @Test("CD-064, CD-082 on AdjacencyMatrix, arcs in row-major order: D: 0>1, 1>0, 1>2")
    func adjacencyMatrix064() {
        // D: 0>1, 1>0, 1>2
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2)]
        let graph = AdjacencyMatrix(vertexCount: 3, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-064: modularity(of: [[0, 1], [2]])
            let communities: [[Int]] = [[0, 1], [2]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
        do {
            // CD-082: partitionQuality(of: [[0, 1], [2]]).performance
            let communities: [[Int]] = [[0, 1], [2]]
            let quality = graph.partitionQuality(of: communities)
            #expect(abs(quality.coverage - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
            #expect(abs(quality.performance - 0.8333333333333334) <= 1e-12 * max(1, abs(0.8333333333333334)))
        }
    }

    @Test("CD-065, CD-066, CD-108, CD-131 on CompressedSparseRow, arcs in row-major order: D: C(0,1,2), C(3,4,5), 2>3")
    func compressedSparseRow065() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 3)]
        let graph = CompressedSparseRow(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-065: modularity(of: [[0, 1, 2], [3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
        do {
            // CD-066: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 2)
            #expect(abs(value - -0.12244897959183676) <= 1e-12 * max(1, abs(-0.12244897959183676)))
        }
        do {
            // CD-108: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
        do {
            // CD-131: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
    }

    @Test("CD-065, CD-066, CD-108, CD-131 on AdjacencyMatrix, arcs in row-major order: D: C(0,1,2), C(3,4,5), 2>3")
    func adjacencyMatrix065() {
        // D: C(0,1,2), C(3,4,5), 2>3
        let arcs: [(Int, Int)] = [(0, 1), (1, 2), (2, 0), (2, 3), (3, 4), (4, 5), (5, 3)]
        let graph = AdjacencyMatrix(vertexCount: 6, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-065: modularity(of: [[0, 1, 2], [3, 4, 5]])
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities)
            #expect(abs(value - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
        do {
            // CD-066: modularity(of: [[0, 1, 2], [3, 4, 5]], resolution: 2)
            let communities: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            let value = graph.modularity(of: communities, resolution: 2)
            #expect(abs(value - -0.12244897959183676) <= 1e-12 * max(1, abs(-0.12244897959183676)))
        }
        do {
            // CD-108: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
        do {
            // CD-131: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2], [3, 4, 5]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.36734693877551017) <= 1e-12 * max(1, abs(0.36734693877551017)))
        }
    }

    @Test("CD-067 on CompressedSparseRow, arcs in row-major order: D: 0>0, 0>1")
    func compressedSparseRow067() {
        // D: 0>0, 0>1
        let arcs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = CompressedSparseRow(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-067: modularity(of: [[0], [1]])
            let communities: [[Int]] = [[0], [1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
    }

    @Test("CD-067 on AdjacencyMatrix, arcs in row-major order: D: 0>0, 0>1")
    func adjacencyMatrix067() {
        // D: 0>0, 0>1
        let arcs: [(Int, Int)] = [(0, 0), (0, 1)]
        let graph = AdjacencyMatrix(vertexCount: 2, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-067: modularity(of: [[0], [1]])
            let communities: [[Int]] = [[0], [1]]
            let value = graph.modularity(of: communities)
            #expect(abs(value) <= 1e-12)
        }
    }

    @Test("CD-087, CD-118 on CompressedSparseRow, as symmetric arcs: U: nx(connected_caveman,4,5)")
    func compressedSparseRow087() {
        // U: nx(connected_caveman,4,5) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 19), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1),
            (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 4),
            (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 5), (7, 6), (7, 8), (7, 9), (8, 5), (8, 6),
            (8, 7), (8, 9), (9, 5), (9, 6), (9, 7), (9, 8), (9, 10), (10, 9), (10, 12), (10, 13), (10, 14),
            (11, 12), (11, 13), (11, 14), (12, 10), (12, 11), (12, 13), (12, 14), (13, 10), (13, 11),
            (13, 12), (13, 14), (14, 10), (14, 11), (14, 12), (14, 13), (14, 15), (15, 14), (15, 17),
            (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 15), (17, 16), (17, 18), (17, 19),
            (18, 15), (18, 16), (18, 17), (18, 19), (19, 0), (19, 15), (19, 16), (19, 17), (19, 18)]
        let graph = CompressedSparseRow(vertexCount: 20, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-087: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14],
                [15, 16, 17, 18, 19]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.65) <= 1e-12 * max(1, abs(0.65)))
        }
        do {
            // CD-118: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14],
                [15, 16, 17, 18, 19]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.65) <= 1e-12 * max(1, abs(0.65)))
        }
    }

    @Test("CD-087, CD-118 on AdjacencyMatrix, as symmetric arcs: U: nx(connected_caveman,4,5)")
    func adjacencyMatrix087() {
        // U: nx(connected_caveman,4,5) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 2), (0, 3), (0, 4), (0, 19), (1, 2), (1, 3), (1, 4), (2, 0), (2, 1),
            (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (4, 5), (5, 4),
            (5, 7), (5, 8), (5, 9), (6, 7), (6, 8), (6, 9), (7, 5), (7, 6), (7, 8), (7, 9), (8, 5), (8, 6),
            (8, 7), (8, 9), (9, 5), (9, 6), (9, 7), (9, 8), (9, 10), (10, 9), (10, 12), (10, 13), (10, 14),
            (11, 12), (11, 13), (11, 14), (12, 10), (12, 11), (12, 13), (12, 14), (13, 10), (13, 11),
            (13, 12), (13, 14), (14, 10), (14, 11), (14, 12), (14, 13), (14, 15), (15, 14), (15, 17),
            (15, 18), (15, 19), (16, 17), (16, 18), (16, 19), (17, 15), (17, 16), (17, 18), (17, 19),
            (18, 15), (18, 16), (18, 17), (18, 19), (19, 0), (19, 15), (19, 16), (19, 17), (19, 18)]
        let graph = AdjacencyMatrix(vertexCount: 20, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-087: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14],
                [15, 16, 17, 18, 19]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.65) <= 1e-12 * max(1, abs(0.65)))
        }
        do {
            // CD-118: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9], [10, 11, 12, 13, 14],
                [15, 16, 17, 18, 19]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.65) <= 1e-12 * max(1, abs(0.65)))
        }
    }

    @Test("CD-101, CD-125 on CompressedSparseRow, as symmetric arcs: U: P(0,1,2,3,4,5,6,7)")
    func compressedSparseRow101() {
        // U: P(0,1,2,3,4,5,6,7) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1), (2, 3), (3, 2), (3, 4), (4, 3), (4, 5),
            (5, 4), (5, 6), (6, 5), (6, 7), (7, 6)]
        let graph = CompressedSparseRow(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-101: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-125: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
    }

    @Test("CD-101, CD-125 on AdjacencyMatrix, as symmetric arcs: U: P(0,1,2,3,4,5,6,7)")
    func adjacencyMatrix101() {
        // U: P(0,1,2,3,4,5,6,7) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 1), (2, 3), (3, 2), (3, 4), (4, 3), (4, 5),
            (5, 4), (5, 6), (6, 5), (6, 7), (7, 6)]
        let graph = AdjacencyMatrix(vertexCount: 8, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-101: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
        do {
            // CD-125: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.35714285714285715) <= 1e-12 * max(1, abs(0.35714285714285715)))
        }
    }

    @Test("CD-102, CD-126 on CompressedSparseRow, as symmetric arcs: U: C(0,1,2,3,4,5,6,7,8,9)")
    func compressedSparseRow102() {
        // U: C(0,1,2,3,4,5,6,7,8,9) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 9), (1, 0), (1, 2), (2, 1), (2, 3), (3, 2), (3, 4), (4, 3),
            (4, 5), (5, 4), (5, 6), (6, 5), (6, 7), (7, 6), (7, 8), (8, 7), (8, 9), (9, 0), (9, 8)]
        let graph = CompressedSparseRow(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-102: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 9], [3, 4, 5, 6], [7, 8]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.33999999999999997) <= 1e-12 * max(1, abs(0.33999999999999997)))
        }
        do {
            // CD-126: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.33999999999999997) <= 1e-12 * max(1, abs(0.33999999999999997)))
        }
    }

    @Test("CD-102, CD-126 on AdjacencyMatrix, as symmetric arcs: U: C(0,1,2,3,4,5,6,7,8,9)")
    func adjacencyMatrix102() {
        // U: C(0,1,2,3,4,5,6,7,8,9) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 9), (1, 0), (1, 2), (2, 1), (2, 3), (3, 2), (3, 4), (4, 3),
            (4, 5), (5, 4), (5, 6), (6, 5), (6, 7), (7, 6), (7, 8), (8, 7), (8, 9), (9, 0), (9, 8)]
        let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-102: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 9], [3, 4, 5, 6], [7, 8]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.33999999999999997) <= 1e-12 * max(1, abs(0.33999999999999997)))
        }
        do {
            // CD-126: greedyModularityCommunities()
            let result = graph.greedyModularityCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3], [4, 5, 6, 7], [8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.33999999999999997) <= 1e-12 * max(1, abs(0.33999999999999997)))
        }
    }

    @Test("CD-103 on CompressedSparseRow, as symmetric arcs: U: S(0;1..6)")
    func compressedSparseRow103() {
        // U: S(0;1..6) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 0), (2, 0), (3, 0),
            (4, 0), (5, 0), (6, 0)]
        let graph = CompressedSparseRow(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-103: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-103 on AdjacencyMatrix, as symmetric arcs: U: S(0;1..6)")
    func adjacencyMatrix103() {
        // U: S(0;1..6) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (1, 0), (2, 0), (3, 0),
            (4, 0), (5, 0), (6, 0)]
        let graph = AdjacencyMatrix(vertexCount: 7, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-103: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 4, 5, 6]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q) <= 1e-12)
        }
    }

    @Test("CD-104 on CompressedSparseRow, as symmetric arcs: U: grid(4,4)")
    func compressedSparseRow104() {
        // U: grid(4,4) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 4), (1, 0), (1, 2), (1, 5), (2, 1), (2, 3), (2, 6), (3, 2),
            (3, 7), (4, 0), (4, 5), (4, 8), (5, 1), (5, 4), (5, 6), (5, 9), (6, 2), (6, 5), (6, 7), (6, 10),
            (7, 3), (7, 6), (7, 11), (8, 4), (8, 9), (8, 12), (9, 5), (9, 8), (9, 10), (9, 13), (10, 6),
            (10, 9), (10, 11), (10, 14), (11, 7), (11, 10), (11, 15), (12, 8), (12, 13), (13, 9), (13, 12),
            (13, 14), (14, 10), (14, 13), (14, 15), (15, 11), (15, 14)]
        let graph = CompressedSparseRow(vertexCount: 16, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-104: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 4, 5], [2, 3, 6, 7], [8, 9, 12, 13], [10, 11, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.41666666666666663) <= 1e-12 * max(1, abs(0.41666666666666663)))
        }
    }

    @Test("CD-104 on AdjacencyMatrix, as symmetric arcs: U: grid(4,4)")
    func adjacencyMatrix104() {
        // U: grid(4,4) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 4), (1, 0), (1, 2), (1, 5), (2, 1), (2, 3), (2, 6), (3, 2),
            (3, 7), (4, 0), (4, 5), (4, 8), (5, 1), (5, 4), (5, 6), (5, 9), (6, 2), (6, 5), (6, 7), (6, 10),
            (7, 3), (7, 6), (7, 11), (8, 4), (8, 9), (8, 12), (9, 5), (9, 8), (9, 10), (9, 13), (10, 6),
            (10, 9), (10, 11), (10, 14), (11, 7), (11, 10), (11, 15), (12, 8), (12, 13), (13, 9), (13, 12),
            (13, 14), (14, 10), (14, 13), (14, 15), (15, 11), (15, 14)]
        let graph = AdjacencyMatrix(vertexCount: 16, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-104: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 4, 5], [2, 3, 6, 7], [8, 9, 12, 13], [10, 11, 14, 15]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.41666666666666663) <= 1e-12 * max(1, abs(0.41666666666666663)))
        }
    }

    @Test("CD-109 on CompressedSparseRow, arcs in row-major order: D: nx(karate_club)")
    func compressedSparseRow109() {
        // D: nx(karate_club)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = CompressedSparseRow(vertexCount: 34, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-109: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.43622616699539773) <= 1e-12 * max(1, abs(0.43622616699539773)))
        }
    }

    @Test("CD-109 on AdjacencyMatrix, arcs in row-major order: D: nx(karate_club)")
    func adjacencyMatrix109() {
        // D: nx(karate_club)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10),
            (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
            (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28),
            (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30),
            (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33),
            (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32),
            (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31),
            (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
        let graph = AdjacencyMatrix(vertexCount: 34, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-109: louvainCommunities()
            let result = graph.louvainCommunities()
            let expected: [[Int]] = [[0, 1, 2, 3, 7, 9, 11, 12, 13, 17, 19, 21], [4, 5, 6, 10, 16],
                [8, 14, 15, 18, 20, 22, 26, 29, 30, 32, 33], [23, 24, 25, 27, 28, 31]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.43622616699539773) <= 1e-12 * max(1, abs(0.43622616699539773)))
        }
    }

    @Test("CD-112 on CompressedSparseRow, as symmetric arcs: U: K(0..4), K(5..9)")
    func compressedSparseRow112() {
        // U: K(0..4), K(5..9) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0),
            (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (5, 6),
            (5, 7), (5, 8), (5, 9), (6, 5), (6, 7), (6, 8), (6, 9), (7, 5), (7, 6), (7, 8), (7, 9), (8, 5),
            (8, 6), (8, 7), (8, 9), (9, 5), (9, 6), (9, 7), (9, 8)]
        let graph = CompressedSparseRow(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-112: louvainCommunities(using: rng(1))
            var generator = SeededRandomNumberGenerator(seed: 1)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
    }

    @Test("CD-112 on AdjacencyMatrix, as symmetric arcs: U: K(0..4), K(5..9)")
    func adjacencyMatrix112() {
        // U: K(0..4), K(5..9) (each edge as two arcs)
        let arcs: [(Int, Int)] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 0), (1, 2), (1, 3), (1, 4), (2, 0),
            (2, 1), (2, 3), (2, 4), (3, 0), (3, 1), (3, 2), (3, 4), (4, 0), (4, 1), (4, 2), (4, 3), (5, 6),
            (5, 7), (5, 8), (5, 9), (6, 5), (6, 7), (6, 8), (6, 9), (7, 5), (7, 6), (7, 8), (7, 9), (8, 5),
            (8, 6), (8, 7), (8, 9), (9, 5), (9, 6), (9, 7), (9, 8)]
        let graph = AdjacencyMatrix(vertexCount: 10, edges: arcs.map { DirectedEdge(from: $0.0, to: $0.1) })
        #expect(graph.edges.map { [$0.source, $0.target] } == arcs.map { [$0.0, $0.1] })
        do {
            // CD-112: louvainCommunities(using: rng(1))
            var generator = SeededRandomNumberGenerator(seed: 1)
            let result = graph.louvainCommunities(using: &generator)
            let expected: [[Int]] = [[0, 1, 2, 3, 4], [5, 6, 7, 8, 9]]
            #expect(result.map { Array($0) } == expected)
            for v in graph.vertices {
                #expect(result.community(ofIndex: v) == result.community(of: v), "vertex \(v)")
            }
            let q = graph.modularity(of: result)
            #expect(abs(q - 0.5) <= 1e-12 * max(1, abs(0.5)))
        }
    }
}
