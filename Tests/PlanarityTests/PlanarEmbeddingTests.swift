// planarEmbedding() (catalog PL-062 – PL-096): nil for a non-planar graph; otherwise every edge position
// embedded (loops and parallel edges too), checked against the definitions, with faceCount, the face
// lengths where every embedding has the same, and the rotation where it is unique up to mirror image.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("planarEmbedding()")
struct PlanarEmbeddingTests {
    @Test("PL-062 empty graph: planarEmbedding()")
    func pl062() throws {
        // U:; planarEmbedding() → faceCount 0; no faces
        let graph = Pseudograph<Int>(vertices: [] as [Int], edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 0 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [] as [Int])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 0 && orbits.count == 0)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-063 one vertex: planarEmbedding()")
    func pl063() throws {
        // U: [0]; planarEmbedding() → faceCount 0; no faces
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [0])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 0 && orbits.count == 0)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-064 one edge: planarEmbedding()")
    func pl064() throws {
        // U: 0-1; planarEmbedding() → faceCount 1; face lengths {2}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 1)
        #expect(Array(graph.vertices) == [0, 1])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 1 && orbits.count == 1)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [2])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0], [0]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-065 path: planarEmbedding()")
    func pl065() throws {
        // U: P(0..3); planarEmbedding() → faceCount 1; face lengths {6}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 1 && orbits.count == 1)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [6])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0], [0, 1], [1, 2], [2]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-066 star: planarEmbedding()")
    func pl066() throws {
        // U: S(0;1..4); planarEmbedding() → faceCount 1; face lengths {8}
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 1 && orbits.count == 1)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [8])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-067 tree: planarEmbedding()")
    func pl067() throws {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5; planarEmbedding() → faceCount 1; face lengths {10}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(1, 3), UndirectedEdge(1, 4), UndirectedEdge(2, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 1 && orbits.count == 1)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [10])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1], [0, 2, 3], [1, 4], [2], [3], [4]]
        let rotationB: [[Int]] = [[0, 1], [0, 3, 2], [1, 4], [2], [3], [4]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-068 cycle: planarEmbedding()")
    func pl068() throws {
        // U: C(0..4); planarEmbedding() → faceCount 2; face lengths {5×2}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 2 && orbits.count == 2)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [5, 5])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0, 4], [0, 1], [1, 2], [2, 3], [3, 4]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-069 triangle with a pendant edge: planarEmbedding()")
    func pl069() throws {
        // U: C(0..2), 0-3; planarEmbedding() → faceCount 2; face lengths {5, 3}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 0), UndirectedEdge(0, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 2 && orbits.count == 2)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [5, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 2, 3], [0, 1], [1, 2], [3]]
        let rotationB: [[Int]] = [[0, 3, 2], [0, 1], [1, 2], [3]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-070 bowtie: two triangles at a cut vertex: planarEmbedding()")
    func pl070() throws {
        // U: C(0..2), C(0,3,4); planarEmbedding() → faceCount 3; face lengths {6, 3×2}
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 0), UndirectedEdge(0, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 3 && orbits.count == 3)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [6, 3, 3])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-071 diamond (K4 minus an edge): planarEmbedding()")
    func pl071() throws {
        // U: nx(diamond); planarEmbedding() → faceCount 3; face lengths {4, 3×2}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 3 && orbits.count == 3)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [4, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1], [0, 2, 3], [1, 4, 2], [3, 4]]
        let rotationB: [[Int]] = [[0, 1], [0, 3, 2], [1, 2, 4], [3, 4]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-072 K4: planarEmbedding()")
    func pl072() throws {
        // U: K(4); planarEmbedding() → faceCount 4; face lengths {3×4}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 4 && orbits.count == 4)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 2, 1], [0, 3, 4], [1, 5, 3], [2, 4, 5]]
        let rotationB: [[Int]] = [[0, 1, 2], [0, 4, 3], [1, 3, 5], [2, 5, 4]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-073 K2,3: planarEmbedding()")
    func pl073() throws {
        // U: KB(0..1;2..4); planarEmbedding() → faceCount 3; face lengths {4×3}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: [0, 2, 3, 4, 1], edges: [UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 2, 3, 4, 1])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 3 && orbits.count == 3)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [4, 4, 4])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 2, 1], [0, 3], [1, 4], [2, 5], [3, 4, 5]]
        let rotationB: [[Int]] = [[0, 1, 2], [0, 3], [1, 4], [2, 5], [3, 5, 4]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-074 K5 minus an edge: planarEmbedding()")
    func pl074() throws {
        // U: [0..4] 0-1, 0-2, 0-3, 0-4, 1-2, 1-3, 1-4, 2-3, 2-4; planarEmbedding() → faceCount 6; face lengths {3×6}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 6 && orbits.count == 6)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 3, 3, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 3, 1, 2], [0, 5, 4, 6], [1, 8, 4, 7], [2, 7, 5], [3, 6, 8]]
        let rotationB: [[Int]] = [[0, 2, 1, 3], [0, 6, 4, 5], [1, 7, 4, 8], [2, 5, 7], [3, 8, 6]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-075 octahedron: planarEmbedding()")
    func pl075() throws {
        // U: nx(octahedral); planarEmbedding() → faceCount 8; face lengths {3×8}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 5), UndirectedEdge(2, 4), UndirectedEdge(2, 5), UndirectedEdge(3, 4),
            UndirectedEdge(3, 5), UndirectedEdge(4, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 8 && orbits.count == 8)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 3, 3, 3, 3, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 2, 3, 1], [0, 4, 6, 5], [1, 7, 8, 4], [2, 5, 10, 9], [3, 9, 11, 7],
            [6, 8, 11, 10]]
        let rotationB: [[Int]] = [[0, 1, 3, 2], [0, 5, 6, 4], [1, 4, 8, 7], [2, 9, 10, 5], [3, 7, 11, 9],
            [6, 10, 11, 8]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-076 cube: planarEmbedding()")
    func pl076() throws {
        // U: Q(3); planarEmbedding() → faceCount 6; face lengths {4×6}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 4), UndirectedEdge(1, 3), UndirectedEdge(1, 5), UndirectedEdge(2, 3),
            UndirectedEdge(2, 6), UndirectedEdge(3, 7), UndirectedEdge(4, 5), UndirectedEdge(4, 6),
            UndirectedEdge(5, 7), UndirectedEdge(6, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 6 && orbits.count == 6)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [4, 4, 4, 4, 4, 4])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 2, 1], [0, 3, 4], [1, 6, 5], [3, 5, 7], [2, 8, 9], [4, 10, 8],
            [6, 9, 11], [7, 11, 10]]
        let rotationB: [[Int]] = [[0, 1, 2], [0, 4, 3], [1, 5, 6], [3, 7, 5], [2, 9, 8], [4, 8, 10],
            [6, 11, 9], [7, 10, 11]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-077 dodecahedron: planarEmbedding()")
    func pl077() throws {
        // U: nx(dodecahedral); planarEmbedding() → faceCount 12; face lengths {5×12}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 20, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 19),
            UndirectedEdge(0, 10), UndirectedEdge(1, 2), UndirectedEdge(1, 8), UndirectedEdge(2, 3),
            UndirectedEdge(2, 6), UndirectedEdge(3, 4), UndirectedEdge(3, 19), UndirectedEdge(4, 5),
            UndirectedEdge(4, 17), UndirectedEdge(5, 6), UndirectedEdge(5, 15), UndirectedEdge(6, 7),
            UndirectedEdge(7, 8), UndirectedEdge(7, 14), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(9, 13), UndirectedEdge(10, 11), UndirectedEdge(11, 12), UndirectedEdge(11, 18),
            UndirectedEdge(12, 13), UndirectedEdge(12, 16), UndirectedEdge(13, 14), UndirectedEdge(14, 15),
            UndirectedEdge(15, 16), UndirectedEdge(16, 17), UndirectedEdge(17, 18), UndirectedEdge(18, 19)])
        #expect(graph.vertexCount == 20 && graph.edgeCount == 30)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 12 && orbits.count == 12)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 2, 1], [0, 3, 4], [3, 5, 6], [5, 8, 7], [7, 10, 9], [9, 12, 11],
            [6, 11, 13], [13, 15, 14], [4, 14, 16], [16, 18, 17], [2, 17, 19], [19, 20, 21], [20, 22, 23],
            [18, 24, 22], [15, 25, 24], [12, 26, 25], [23, 26, 27], [10, 28, 27], [21, 28, 29], [1, 29, 8]]
        let rotationB: [[Int]] = [[0, 1, 2], [0, 4, 3], [3, 6, 5], [5, 7, 8], [7, 9, 10], [9, 11, 12],
            [6, 13, 11], [13, 14, 15], [4, 16, 14], [16, 17, 18], [2, 19, 17], [19, 21, 20], [20, 23, 22],
            [18, 22, 24], [15, 24, 25], [12, 25, 26], [23, 27, 26], [10, 27, 28], [21, 29, 28], [1, 8, 29]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-078 icosahedron: planarEmbedding()")
    func pl078() throws {
        // U: nx(icosahedral); planarEmbedding() → faceCount 20; face lengths {3×20}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6], edges: [UndirectedEdge(0, 1),
            UndirectedEdge(0, 5), UndirectedEdge(0, 7), UndirectedEdge(0, 8), UndirectedEdge(0, 11),
            UndirectedEdge(1, 2), UndirectedEdge(1, 5), UndirectedEdge(1, 6), UndirectedEdge(1, 8),
            UndirectedEdge(2, 3), UndirectedEdge(2, 6), UndirectedEdge(2, 8), UndirectedEdge(2, 9),
            UndirectedEdge(3, 4), UndirectedEdge(3, 6), UndirectedEdge(3, 9), UndirectedEdge(3, 10),
            UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 10), UndirectedEdge(4, 11),
            UndirectedEdge(5, 6), UndirectedEdge(5, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 9),
            UndirectedEdge(7, 10), UndirectedEdge(7, 11), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11)])
        #expect(graph.vertexCount == 12 && graph.edgeCount == 30)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11, 6])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 20 && orbits.count == 20)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1, 4, 2, 3], [0, 8, 5, 7, 6], [5, 11, 12, 9, 10], [9, 15, 16, 13, 14],
            [13, 19, 20, 17, 18], [1, 6, 21, 17, 22], [2, 26, 25, 24, 23], [3, 23, 27, 11, 8],
            [12, 27, 24, 28, 15], [16, 28, 25, 29, 19], [4, 22, 20, 29, 26], [7, 10, 14, 18, 21]]
        let rotationB: [[Int]] = [[0, 3, 2, 4, 1], [0, 6, 7, 5, 8], [5, 10, 9, 12, 11], [9, 14, 13, 16, 15],
            [13, 18, 17, 20, 19], [1, 22, 17, 21, 6], [2, 23, 24, 25, 26], [3, 8, 11, 27, 23],
            [12, 15, 28, 24, 27], [16, 19, 29, 25, 28], [4, 26, 29, 20, 22], [7, 21, 18, 14, 10]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-079 wheel W6: planarEmbedding()")
    func pl079() throws {
        // U: nx(wheel,6); planarEmbedding() → faceCount 6; face lengths {5, 3×5}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 2),
            UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 6 && orbits.count == 6)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [5, 3, 3, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 4, 3, 2, 1], [0, 5, 6], [1, 7, 5], [2, 8, 7], [3, 9, 8], [4, 6, 9]]
        let rotationB: [[Int]] = [[0, 1, 2, 3, 4], [0, 6, 5], [1, 5, 7], [2, 7, 8], [3, 8, 9], [4, 9, 6]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-080 prism C4 × K2: planarEmbedding()")
    func pl080() throws {
        // U: nx(circular_ladder,4); planarEmbedding() → faceCount 6; face lengths {4×6}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 4),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 5), UndirectedEdge(2, 3),
            UndirectedEdge(2, 6), UndirectedEdge(3, 7), UndirectedEdge(4, 5), UndirectedEdge(4, 7),
            UndirectedEdge(5, 6), UndirectedEdge(6, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 12)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 6 && orbits.count == 6)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [4, 4, 4, 4, 4, 4])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1, 2], [0, 3, 4], [3, 5, 6], [2, 7, 5], [1, 8, 9], [4, 10, 8],
            [6, 11, 10], [7, 9, 11]]
        let rotationB: [[Int]] = [[0, 2, 1], [0, 4, 3], [3, 6, 5], [2, 5, 7], [1, 9, 8], [4, 8, 10],
            [6, 10, 11], [7, 11, 9]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-081 grid 3 × 4: planarEmbedding()")
    func pl081() throws {
        // U: grid(3,4); planarEmbedding() → faceCount 7; face lengths {10, 4×6}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 4),
            UndirectedEdge(1, 2), UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(2, 6),
            UndirectedEdge(3, 7), UndirectedEdge(4, 5), UndirectedEdge(4, 8), UndirectedEdge(5, 6),
            UndirectedEdge(5, 9), UndirectedEdge(6, 7), UndirectedEdge(6, 10), UndirectedEdge(7, 11),
            UndirectedEdge(8, 9), UndirectedEdge(9, 10), UndirectedEdge(10, 11)])
        #expect(graph.vertexCount == 12 && graph.edgeCount == 17)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 7 && orbits.count == 7)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [10, 4, 4, 4, 4, 4, 4])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1], [0, 2, 3], [2, 4, 5], [4, 6], [1, 7, 8], [3, 9, 10, 7],
            [5, 11, 12, 9], [6, 13, 11], [8, 14], [10, 15, 14], [12, 16, 15], [13, 16]]
        let rotationB: [[Int]] = [[0, 1], [0, 3, 2], [2, 5, 4], [4, 6], [1, 8, 7], [3, 7, 10, 9],
            [5, 9, 12, 11], [6, 11, 13], [8, 14], [10, 14, 15], [12, 15, 16], [13, 16]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-082 Frucht graph: planarEmbedding()")
    func pl082() throws {
        // U: nx(frucht); planarEmbedding() → faceCount 8; face lengths {7, 6, 5×2, 4, 3×3}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 6),
            UndirectedEdge(0, 7), UndirectedEdge(1, 2), UndirectedEdge(1, 7), UndirectedEdge(2, 3),
            UndirectedEdge(2, 8), UndirectedEdge(3, 4), UndirectedEdge(3, 9), UndirectedEdge(4, 5),
            UndirectedEdge(4, 9), UndirectedEdge(5, 6), UndirectedEdge(5, 10), UndirectedEdge(6, 10),
            UndirectedEdge(7, 11), UndirectedEdge(8, 11), UndirectedEdge(8, 9), UndirectedEdge(10, 11)])
        #expect(graph.vertexCount == 12 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 8 && orbits.count == 8)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [7, 6, 5, 5, 4, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 2, 1], [0, 3, 4], [3, 5, 6], [5, 7, 8], [7, 9, 10], [9, 11, 12],
            [1, 13, 11], [2, 4, 14], [6, 16, 15], [8, 10, 16], [12, 13, 17], [14, 15, 17]]
        let rotationB: [[Int]] = [[0, 1, 2], [0, 4, 3], [3, 6, 5], [5, 8, 7], [7, 10, 9], [9, 12, 11],
            [1, 11, 13], [2, 14, 4], [6, 15, 16], [8, 16, 10], [12, 17, 13], [14, 17, 15]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-083 Tutte graph: planarEmbedding()")
    func pl083() throws {
        // U: nx(tutte); planarEmbedding() → faceCount 25; face lengths {10×3, 9, 5×15, 4×6}; unique up to mirror image
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 2, 0, 3, 1, 4, 1, 26, 2, 10, 2, 11, 3, 18, 3, 19, 4, 5, 4, 33, 5, 6,
            5, 29, 6, 7, 6, 27, 7, 8, 7, 14, 8, 9, 8, 38, 9, 10, 9, 37, 10, 39, 11, 12, 11, 39, 12, 13,
            12, 35, 13, 14, 13, 15, 14, 34, 15, 16, 15, 22, 16, 17, 16, 44, 17, 18, 17, 43, 18, 45, 19, 20,
            19, 45, 20, 21, 20, 41, 21, 22, 21, 23, 22, 40, 23, 24, 23, 27, 24, 25, 24, 32, 25, 26, 25, 31,
            26, 33, 27, 28, 28, 29, 28, 32, 29, 30, 30, 31, 30, 33, 31, 32, 34, 35, 34, 38, 35, 36, 36, 37,
            36, 39, 37, 38, 40, 41, 40, 44, 41, 42, 42, 43, 42, 45, 43, 44]
        let graph = Pseudograph<Int>(vertices: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 34, 35, 36, 37, 40, 41, 42, 43, 33, 38, 39, 44, 45, 32], edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 46 && graph.edgeCount == 69)
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 25 && orbits.count == 25)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [10, 10, 10, 9, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 2, 1], [0, 3, 4], [1, 6, 5], [2, 8, 7], [3, 9, 10], [9, 11, 12],
            [11, 13, 14], [13, 15, 16], [15, 17, 18], [17, 19, 20], [5, 21, 19], [6, 22, 23], [22, 24, 25],
            [24, 27, 26], [16, 28, 26], [27, 29, 30], [29, 31, 32], [31, 33, 34], [7, 35, 33], [8, 36, 37],
            [36, 38, 39], [38, 41, 40], [30, 42, 40], [41, 43, 44], [43, 45, 46], [45, 47, 48], [4, 49, 47],
            [14, 44, 50], [50, 52, 51], [12, 51, 53], [53, 54, 55], [48, 54, 56], [28, 58, 57], [25, 57, 59],
            [59, 60, 61], [20, 60, 62], [42, 64, 63], [39, 63, 65], [65, 66, 67], [34, 66, 68], [10, 55, 49],
            [18, 62, 58], [21, 23, 61], [32, 68, 64], [35, 37, 67], [46, 56, 52]]
        let rotationB: [[Int]] = [[0, 1, 2], [0, 4, 3], [1, 5, 6], [2, 7, 8], [3, 10, 9], [9, 12, 11],
            [11, 14, 13], [13, 16, 15], [15, 18, 17], [17, 20, 19], [5, 19, 21], [6, 23, 22], [22, 25, 24],
            [24, 26, 27], [16, 26, 28], [27, 30, 29], [29, 32, 31], [31, 34, 33], [7, 33, 35], [8, 37, 36],
            [36, 39, 38], [38, 40, 41], [30, 40, 42], [41, 44, 43], [43, 46, 45], [45, 48, 47], [4, 47, 49],
            [14, 50, 44], [50, 51, 52], [12, 53, 51], [53, 55, 54], [48, 56, 54], [28, 57, 58], [25, 59, 57],
            [59, 61, 60], [20, 62, 60], [42, 63, 64], [39, 65, 63], [65, 67, 66], [34, 68, 66], [10, 49, 55],
            [18, 58, 62], [21, 61, 23], [32, 64, 68], [35, 67, 37], [46, 52, 56]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-084 house with a cross: planarEmbedding()")
    func pl084() throws {
        // U: nx(house_x); planarEmbedding() → faceCount 5; face lengths {4, 3×4}
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 3), UndirectedEdge(1, 2), UndirectedEdge(2, 3),
            UndirectedEdge(2, 4), UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 5 && orbits.count == 5)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [4, 3, 3, 3, 3])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-085 K5 subdivided: no embedding: planarEmbedding()")
    func pl085() {
        // U: sd(K(5)); planarEmbedding() → nil
        let graph = Pseudograph<Int>(vertices: 0 ..< 15, edges: [UndirectedEdge(0, 5), UndirectedEdge(5, 1),
            UndirectedEdge(0, 6), UndirectedEdge(6, 2), UndirectedEdge(0, 7), UndirectedEdge(7, 3),
            UndirectedEdge(0, 8), UndirectedEdge(8, 4), UndirectedEdge(1, 9), UndirectedEdge(9, 2),
            UndirectedEdge(1, 10), UndirectedEdge(10, 3), UndirectedEdge(1, 11), UndirectedEdge(11, 4),
            UndirectedEdge(2, 12), UndirectedEdge(12, 3), UndirectedEdge(2, 13), UndirectedEdge(13, 4),
            UndirectedEdge(3, 14), UndirectedEdge(14, 4)])
        #expect(graph.vertexCount == 15 && graph.edgeCount == 20)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14])
        #expect(graph.planarEmbedding() == nil)
        #expect(!graph.isPlanar && graph.findKuratowskiSubgraph() != nil)
    }

    @Test("PL-086 K5: no embedding: planarEmbedding()")
    func pl086() {
        // U: K(5); planarEmbedding() → nil
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 3), UndirectedEdge(2, 4), UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
        #expect(graph.planarEmbedding() == nil)
        #expect(!graph.isPlanar && graph.findKuratowskiSubgraph() != nil)
    }

    @Test("PL-087 two disjoint triangles: planarEmbedding()")
    func pl087() throws {
        // U: C(0..2), C(3..5); planarEmbedding() → faceCount 4; face lengths {3×4}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 4 && orbits.count == 4)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0, 2], [0, 1], [1, 2], [3, 5], [3, 4], [4, 5]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-088 K4 and isolated vertices: planarEmbedding()")
    func pl088() throws {
        // U: [9, 8] K(4); planarEmbedding() → faceCount 4; face lengths {3×4}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: [9, 8, 0, 1, 2, 3], edges: [UndirectedEdge(0, 1),
            UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3),
            UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [9, 8, 0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 4 && orbits.count == 4)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[], [], [0, 2, 1], [0, 3, 4], [1, 5, 3], [2, 4, 5]]
        let rotationB: [[Int]] = [[], [], [0, 1, 2], [0, 4, 3], [1, 3, 5], [2, 5, 4]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-089 two parallel edges: planarEmbedding()")
    func pl089() throws {
        // U: 0=1; planarEmbedding() → faceCount 2; face lengths {2×2}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.vertices) == [0, 1])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 2 && orbits.count == 2)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [2, 2])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0, 1], [0, 1]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-090 three parallel edges: planarEmbedding()")
    func pl090() throws {
        // U: 0=1, 0-1; planarEmbedding() → faceCount 3; face lengths {2×3}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1),
            UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [0, 1])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 3 && orbits.count == 3)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [2, 2, 2])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1, 2], [0, 2, 1]]
        let rotationB: [[Int]] = [[0, 2, 1], [0, 1, 2]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-091 one loop: planarEmbedding()")
    func pl091() throws {
        // U: 0-0; planarEmbedding() → faceCount 2; face lengths {1×2}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.vertices) == [0])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 2 && orbits.count == 2)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [1, 1])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0, 0]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-092 two loops at one vertex: planarEmbedding()")
    func pl092() throws {
        // U: 0-0, 0-0; planarEmbedding() → faceCount 3; face lengths {2, 1×2}
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 0)])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 2)
        #expect(Array(graph.vertices) == [0])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 3 && orbits.count == 3)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [2, 1, 1])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-093 loop and an edge: planarEmbedding()")
    func pl093() throws {
        // U: 0-0, 0-1; planarEmbedding() → faceCount 2; face lengths {3, 1}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 0), UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 2 && graph.edgeCount == 2)
        #expect(Array(graph.vertices) == [0, 1])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 2 && orbits.count == 2)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 1])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0, 0, 1], [1]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-094 triangle with a doubled edge: planarEmbedding()")
    func pl094() throws {
        // U: C(0..2), 0-1; planarEmbedding() → faceCount 3; face lengths {3×2, 2}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 0), UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 3 && orbits.count == 3)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 3, 2])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 3, 2], [0, 1, 3], [1, 2]]
        let rotationB: [[Int]] = [[0, 2, 3], [0, 3, 1], [1, 2]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-095 K4 with a loop and a parallel pair: planarEmbedding()")
    func pl095() throws {
        // U: K(4), 0-0, 1=2; planarEmbedding() → faceCount 7; face lengths not pinned (not unique)
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
            UndirectedEdge(0, 0), UndirectedEdge(1, 2), UndirectedEdge(1, 2)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 9)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 7 && orbits.count == 7)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }

    @Test("PL-096 stacked triangulation: planarEmbedding()")
    func pl096() throws {
        // U: tri(8,2); planarEmbedding() → faceCount 12; face lengths {3×12}; unique up to mirror image
        let graph = Pseudograph<Int>(vertices: 0 ..< 8, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(1, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
            UndirectedEdge(1, 4), UndirectedEdge(2, 4), UndirectedEdge(3, 4), UndirectedEdge(0, 5),
            UndirectedEdge(1, 5), UndirectedEdge(3, 5), UndirectedEdge(0, 6), UndirectedEdge(1, 6),
            UndirectedEdge(5, 6), UndirectedEdge(1, 7), UndirectedEdge(3, 7), UndirectedEdge(4, 7)])
        #expect(graph.vertexCount == 8 && graph.edgeCount == 18)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6, 7])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the safe: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(embedding.clockwiseIncidentEdges(safe: v).map { Array($0) } == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(embedding.clockwiseNeighbors(safe: v).map { Array($0) } == across)
            #expect(Array(embedding.clockwiseNeighborIndices(ofIndex: i)) == across.map { indexOf[$0]! })
            rotation.append(row)
        }
        // Half-edges are (vertex index, slot). The twin of a slot is the edge's other end: at the far
        // vertex, or for a loop the other slot holding it. The face after (i, s) is the slot before the
        // twin, clockwise. `faces` is these orbits, met walking the vertices in order and each row in
        // order, each from that half-edge's tail.
        var slots: [Int: [(Int, Int)]] = [:]
        for (i, row) in rotation.enumerated() { for (s, p) in row.enumerated() { slots[p, default: []].append((i, s)) } }
        #expect(slots.values.allSatisfy { $0.count == 2 } && slots.count == graph.edgeCount)
        var seen = rotation.map { [Bool](repeating: false, count: $0.count) }
        var orbits: [(vertices: [Int], edges: [Int])] = []
        var faceOf = rotation.map { [Int](repeating: -1, count: $0.count) }
        for i in rotation.indices {
            for s in rotation[i].indices where !seen[i][s] {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    seen[x][y] = true
                    faceOf[x][y] = orbits.count
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                orbits.append((vertices + [vertexList[i]], edges))
            }
        }
        #expect(embedding.faces.map(\.vertices) == orbits.map(\.vertices))
        #expect(embedding.faces.map(\.edges) == orbits.map(\.edges))
        // Euler's formula per component with an edge: Σ (2 − n_c + m_c).
        #expect(embedding.faceCount == 12 && orbits.count == 12)
        // face(from:alongEdgeAt:): the orbit from the half-edge leaving the vertex (a loop: its first slot).
        // Every half-edge.
        for i in rotation.indices {
            for s in rotation[i].indices where rotation[i].firstIndex(of: rotation[i][s]) == s {
                var vertices: [Int] = [], edges: [Int] = []
                var (x, y) = (i, s)
                repeat {
                    vertices.append(vertexList[x])
                    edges.append(rotation[x][y])
                    let twin = slots[rotation[x][y]]!.first { $0 != (x, y) }!
                    (x, y) = (twin.0, (twin.1 + rotation[twin.0].count - 1) % rotation[twin.0].count)
                } while (x, y) != (i, s)
                let face = embedding.face(from: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(face.vertices == vertices + [vertexList[i]] && face.edges == edges)
                #expect(embedding.rightFace(from: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        #expect(embedding.faces.map(\.length).sorted(by: >) == [3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3])
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 12, 9, 3, 1], [0, 2, 6, 15, 4, 10, 13], [1, 5, 7, 2],
            [3, 11, 4, 16, 8, 5], [6, 7, 8, 17], [9, 14, 10, 11], [12, 13, 14], [15, 17, 16]]
        let rotationB: [[Int]] = [[0, 1, 3, 9, 12], [0, 13, 10, 4, 15, 6, 2], [1, 2, 7, 5],
            [3, 5, 8, 16, 4, 11], [6, 17, 8, 7], [9, 11, 10, 14], [12, 14, 13], [15, 16, 17]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
    }
}
