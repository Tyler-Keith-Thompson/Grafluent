// §A: the empty graph (both kinds), one vertex, four isolated vertices, lone self-loops, K₂ and one
// arc: every entry point. m = 0 gives modularity 0 (NetworkX; igraph NaN); coverage and performance
// are NaN where their ratio is 0/0; every algorithm returns singletons on an edgeless graph, and
// self-loops never join two vertices (Louvain, greedy) and vote for nothing (label propagation).
// Expected values are ref.py's model at full precision (the catalog cells are the same values
// rounded to 12 digits); scalars compare within 1e-12 relative to max(1, |value|), partitions
// exactly, in canonical order (communities by least vertex number, each in `vertices` order). Every
// partition row also checks `count`, `community(of:)` against membership, `community(ofIndex:)`
// against `community(of:)`, and the modularity of the result (at the call's weight and resolution)
// against ref.py's; undirected rows of the measures, Louvain and greedy modularity also run on
// `graph.directed` (the same values). Case IDs (CD-nnn) refer to the catalog; see README.md.

import CommunityDetection
import GrafluentTestSupport
import GraphProtocols
import Testing

@Suite("Degenerate graphs")
struct CommunityDegenerateGraphTests {
    @Test("CD-001 U([]).modularity(of: []) is 0: Empty graph, empty partition: m = 0, so 0 (NetworkX)")
    func modularity001() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let communities: [[Int]] = []
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs) <= 1e-12, "graph.directed")
    }

    @Test("CD-002 U([]).partitionQuality(of: []).coverage is NaN: 0/0: NaN (NetworkX raises ZeroDivisionError)")
    func quality002() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let communities: [[Int]] = []
        let quality = graph.partitionQuality(of: communities)
        #expect(quality.coverage.isNaN)
        #expect(quality.performance.isNaN)
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(arcs.coverage.isNaN, "graph.directed")
        #expect(arcs.performance.isNaN, "graph.directed")
    }

    @Test("CD-003 U([]).partitionQuality(of: []).performance is NaN: 0/0 pairs: NaN")
    func quality003() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let communities: [[Int]] = []
        let quality = graph.partitionQuality(of: communities)
        #expect(quality.coverage.isNaN)
        #expect(quality.performance.isNaN)
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(arcs.coverage.isNaN, "graph.directed")
        #expect(arcs.performance.isNaN, "graph.directed")
    }

    @Test("CD-004 U([]).louvainCommunities() is []: Empty partition")
    func louvain004() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-005 U([]).louvainCommunities().count is 0")
    func louvain005() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
        let result = graph.louvainCommunities()
        #expect(result.count == 0)
        #expect(result.reduce(0) { $0 + $1.count } == graph.vertexCount)
        for (c, community) in result.enumerated() {
            for v in community {
                #expect(result.community(of: v) == c, "vertex \(v)")
            }
        }
    }

    @Test("CD-006 U([]).greedyModularityCommunities() is []")
    func greedy006() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-007 U([]).labelPropagationCommunities() is []")
    func labelPropagation007() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
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

    @Test("CD-008 U([]).asynchronousLabelPropagationCommunities() is []")
    func asynchronousLabelPropagation008() {
        // U: []
        let graph = ReferencePseudograph<Int>(vertices: [], edges: [])
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

    @Test("CD-009 D([]).louvainCommunities() is []")
    func louvain009() {
        // D: []
        let graph = ReferenceDirectedMultigraph<Int>(vertices: [], edges: [])
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

    @Test("CD-010 U([0]).modularity(of: [[0]]) is 0: One vertex, no edges: 0")
    func modularity010() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs) <= 1e-12, "graph.directed")
    }

    @Test("CD-011 U([0]).louvainCommunities() is [[0]]: One vertex: one community")
    func louvain011() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-012 U([0]).greedyModularityCommunities() is [[0]]")
    func greedy012() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-013 U([0]).labelPropagationCommunities() is [[0]]")
    func labelPropagation013() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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

    @Test("CD-014 U([0]).asynchronousLabelPropagationCommunities() is [[0]]")
    func asynchronousLabelPropagation014() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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

    @Test("CD-015 U([0]).partitionQuality(of: [[0]]).performance is NaN: No pairs: NaN")
    func quality015() {
        // U: [0]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0]]
        let quality = graph.partitionQuality(of: communities)
        #expect(quality.coverage.isNaN)
        #expect(quality.performance.isNaN)
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(arcs.coverage.isNaN, "graph.directed")
        #expect(arcs.performance.isNaN, "graph.directed")
    }

    @Test("CD-016 U([0..3]).modularity(of: [[0, 1], [2, 3]]) is 0: Edgeless: m = 0, so 0 (NetworkX); igraph NaN")
    func modularity016() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2, 3]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs) <= 1e-12, "graph.directed")
    }

    @Test("CD-017 U([0..3]).louvainCommunities() is [[0], [1], [2], [3]]: Edgeless: singletons")
    func louvain017() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-018 U([0..3]).greedyModularityCommunities() is [[0], [1], [2], [3]]: Edgeless: singletons (NetworkX `if not G.size()`)")
    func greedy018() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-019 U([0..3]).labelPropagationCommunities() is [[0], [1], [2], [3]]: No votes: every vertex keeps its own label")
    func labelPropagation019() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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

    @Test("CD-020 U([0..3]).asynchronousLabelPropagationCommunities() is [[0], [1], [2], [3]]")
    func asynchronousLabelPropagation020() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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

    @Test("CD-021 U([0..3]).partitionQuality(of: [[0, 1], [2, 3]]).coverage is NaN: No edges: NaN")
    func quality021() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2, 3]]
        let quality = graph.partitionQuality(of: communities)
        #expect(quality.coverage.isNaN)
        #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(arcs.coverage.isNaN, "graph.directed")
        #expect(abs(arcs.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
    }

    @Test("CD-022 U([0..3]).partitionQuality(of: [[0, 1], [2, 3]]).performance is 0.666666666667: 4 of 6 pairs are inter-community non-edges")
    func quality022() {
        // U: [0..3]
        let pairs: [(Int, Int)] = []
        let graph = ReferencePseudograph(vertices: 0 ..< 4, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0, 1], [2, 3]]
        let quality = graph.partitionQuality(of: communities)
        #expect(quality.coverage.isNaN)
        #expect(abs(quality.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)))
        let arcs = graph.directed.partitionQuality(of: communities)
        #expect(arcs.coverage.isNaN, "graph.directed")
        #expect(abs(arcs.performance - 0.6666666666666666) <= 1e-12 * max(1, abs(0.6666666666666666)), "graph.directed")
    }

    @Test("CD-023 U(0-0).modularity(of: [[0]]) is 0: A loop alone: L = 1, d = 2, m = 1: 1 − 4/4 = 0")
    func modularity023() {
        // U: 0-0
        let pairs: [(Int, Int)] = [(0, 0)]
        let graph = ReferencePseudograph(vertices: 0 ..< 1, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs) <= 1e-12, "graph.directed")
    }

    @Test("CD-024 U(0-0, 1-1).modularity(of: [[0], [1]]) is 0.5: Two loops: 2 · (1/2 − 1/4)")
    func modularity024() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
        let communities: [[Int]] = [[0], [1]]
        let value = graph.modularity(of: communities)
        #expect(abs(value - 0.5) <= 1e-12 * max(1, abs(0.5)))
        let arcs = graph.directed.modularity(of: communities)
        #expect(abs(arcs - 0.5) <= 1e-12 * max(1, abs(0.5)), "graph.directed")
    }

    @Test("CD-025 U(0-0, 1-1).louvainCommunities() is [[0], [1]]: Loops never join vertices")
    func louvain025() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-026 U(0-0, 1-1).greedyModularityCommunities() is [[0], [1]]: No off-diagonal pair to merge")
    func greedy026() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-027 U(0-0, 1-1).labelPropagationCommunities() is [[0], [1]]: Loops vote for nothing")
    func labelPropagation027() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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

    @Test("CD-028 U(0-0, 1-1).asynchronousLabelPropagationCommunities() is [[0], [1]]")
    func asynchronousLabelPropagation028() {
        // U: 0-0, 1-1
        let pairs: [(Int, Int)] = [(0, 0), (1, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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

    @Test("CD-029 U(0-1).louvainCommunities() is [[0, 1]]: K2: one community, Q = 0 > −½")
    func louvain029() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.louvainCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-030 U(0-1).greedyModularityCommunities() is [[0, 1]]")
    func greedy030() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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
        let arcs = graph.directed.greedyModularityCommunities()
        #expect(arcs == result, "graph.directed")
    }

    @Test("CD-031 U(0-1).labelPropagationCommunities() is [[0, 1]]: Both adopt the greatest label, 1")
    func labelPropagation031() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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

    @Test("CD-032 U(0-1).asynchronousLabelPropagationCommunities() is [[0, 1]]: 0 takes 1's label, then 1 keeps it")
    func asynchronousLabelPropagation032() {
        // U: 0-1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferencePseudograph(vertices: 0 ..< 2, edges: pairs.map { UndirectedEdge($0.0, $0.1) })
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

    @Test("CD-033 D(0>1).louvainCommunities() is [[0], [1]]: One arc: Q is 0 either way, and a move needs a strictly greater gain")
    func louvain033() {
        // D: 0>1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
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

    @Test("CD-034 D(0>1).modularity(of: [[0, 1]]) is 0: One community is always 1 − γ = 0")
    func modularity034() {
        // D: 0>1
        let pairs: [(Int, Int)] = [(0, 1)]
        let graph = ReferenceDirectedMultigraph(vertices: 0 ..< 2, edges: pairs.map { DirectedEdge(from: $0.0, to: $0.1) })
        let communities: [[Int]] = [[0, 1]]
        let value = graph.modularity(of: communities)
        #expect(abs(value) <= 1e-12)
    }
}
