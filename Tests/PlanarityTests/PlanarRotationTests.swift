// Clockwise orders and face(from:alongEdgeAt:) (catalog PL-108 – PL-130 without the traps): starting at
// the first incident edge, the mirror image accepted when it is the whole embedding's.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("PlanarEmbedding clockwise orders and faces")
struct PlanarRotationTests {
    @Test("PL-108 K4, vertex 0: planarEmbedding()!.clockwiseNeighbors(of: 0)")
    func pl108() throws {
        // U: K(4); planarEmbedding()!.clockwiseNeighbors(of: 0) → [1, 3, 2] or [1, 2, 3] (mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(Array(embedding.clockwiseNeighbors(of: 0)) == (isA ? [1, 3, 2] : [1, 2, 3]))
    }

    @Test("PL-109 K4, vertex 0, edges: planarEmbedding()!.clockwiseIncidentEdges(of: 0)")
    func pl109() throws {
        // U: K(4); planarEmbedding()!.clockwiseIncidentEdges(of: 0) → [0, 2, 1] or [0, 1, 2] (mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(Array(embedding.clockwiseIncidentEdges(of: 0)) == (isA ? [0, 2, 1] : [0, 1, 2]))
    }

    @Test("PL-110 wheel hub: planarEmbedding()!.clockwiseNeighbors(of: 0)")
    func pl110() throws {
        // U: nx(wheel,6); planarEmbedding()!.clockwiseNeighbors(of: 0) → [1, 5, 4, 3, 2] or [1, 2, 3, 4, 5] (mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 2),
            UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(Array(embedding.clockwiseNeighbors(of: 0)) == (isA ? [1, 5, 4, 3, 2] : [1, 2, 3, 4, 5]))
    }

    @Test("PL-111 wheel rim vertex: planarEmbedding()!.clockwiseNeighbors(of: 3)")
    func pl111() throws {
        // U: nx(wheel,6); planarEmbedding()!.clockwiseNeighbors(of: 3) → [0, 4, 2] or [0, 2, 4] (mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(0, 5), UndirectedEdge(1, 2),
            UndirectedEdge(1, 5), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 10)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(Array(embedding.clockwiseNeighbors(of: 3)) == (isA ? [0, 4, 2] : [0, 2, 4]))
    }

    @Test("PL-112 path middle: planarEmbedding()!.clockwiseNeighbors(of: 1)")
    func pl112() throws {
        // U: P(0..2); planarEmbedding()!.clockwiseNeighbors(of: 1) → [0, 2]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0], [0, 1], [1]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        #expect(Array(embedding.clockwiseNeighbors(of: 1)) == [0, 2])
    }

    @Test("PL-113 isolated vertex: empty: planarEmbedding()!.clockwiseNeighbors(of: 2)")
    func pl113() throws {
        // U: [0..2] 0-1; planarEmbedding()!.clockwiseNeighbors(of: 2) → []
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 1)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0], [0], []])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        #expect(Array(embedding.clockwiseNeighbors(of: 2)) == [] as [Int])
    }

    @Test("PL-114 triangle with a doubled edge, vertex 0: planarEmbedding()!.clockwiseIncidentEdges(of: 0)")
    func pl114() throws {
        // U: C(0..2), 0-1; planarEmbedding()!.clockwiseIncidentEdges(of: 0) → [0, 3, 2] or [0, 2, 3] (mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 0), UndirectedEdge(0, 1)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(Array(embedding.clockwiseIncidentEdges(of: 0)) == (isA ? [0, 3, 2] : [0, 2, 3]))
    }

    @Test("PL-115 loop: its position twice: planarEmbedding()!.clockwiseIncidentEdges(of: 0)")
    func pl115() throws {
        // U: 0-0; planarEmbedding()!.clockwiseIncidentEdges(of: 0) → [0, 0]
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.vertices) == [0])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(Array(embedding.clockwiseIncidentEdges(of: 0)) == [0, 0])
    }

    @Test("PL-116 labels: vertices are not indices: planarEmbedding()!.clockwiseNeighbors(of: 3)")
    func pl116() throws {
        // U: [7, 3, 5] 7-3, 3-5, 5-7; planarEmbedding()!.clockwiseNeighbors(of: 3) → [7, 5]
        let graph = Pseudograph<Int>(vertices: [7, 3, 5], edges: [UndirectedEdge(7, 3), UndirectedEdge(3, 5),
            UndirectedEdge(5, 7)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
        #expect(Array(graph.vertices) == [7, 3, 5])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0, 2], [0, 1], [1, 2]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        #expect(Array(embedding.clockwiseNeighbors(of: 3)) == [7, 5])
    }

    @Test("PL-118 not a vertex, checked:: planarEmbedding()!.clockwiseNeighbors(checked: 9)")
    func pl118() throws {
        // U: K(4); planarEmbedding()!.clockwiseNeighbors(checked: 9) → throws VertexNotFound
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(throws: VertexNotFound.self) { try embedding.clockwiseNeighbors(checked: 9) }
    }

    @Test("PL-119 a vertex, checked:: planarEmbedding()!.clockwiseNeighbors(checked: 0)")
    func pl119() throws {
        // U: K(4); planarEmbedding()!.clockwiseNeighbors(checked: 0) → [1, 3, 2] or [1, 2, 3] (mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(try Array(embedding.clockwiseNeighbors(checked: 0)) == (isA ? [1, 3, 2] : [1, 2, 3]))
    }

    @Test("PL-120 K4: face right of 0 → 1: planarEmbedding()!.face(from: 0, alongEdgeAt: 0)")
    func pl120() throws {
        // U: K(4); planarEmbedding()!.face(from: 0, alongEdgeAt: 0) → vertices [0, 1, 3, 0], edges [0, 4, 2]; or vertices [0, 1, 2, 0], edges [0, 3, 1] (mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        let face = embedding.face(from: 0, alongEdgeAt: 0)
        #expect(face.vertices == (isA ? [0, 1, 3, 0] : [0, 1, 2, 0]))
        #expect(face.edges == (isA ? [0, 4, 2] : [0, 3, 1]))
    }

    @Test("PL-121 K4: face right of 1 → 0: planarEmbedding()!.face(from: 1, alongEdgeAt: 0)")
    func pl121() throws {
        // U: K(4); planarEmbedding()!.face(from: 1, alongEdgeAt: 0) → vertices [1, 0, 2, 1], edges [0, 1, 3]; or vertices [1, 0, 3, 1], edges [0, 2, 4] (mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        let face = embedding.face(from: 1, alongEdgeAt: 0)
        #expect(face.vertices == (isA ? [1, 0, 2, 1] : [1, 0, 3, 1]))
        #expect(face.edges == (isA ? [0, 1, 3] : [0, 2, 4]))
    }

    @Test("PL-122 path: the one face: planarEmbedding()!.face(from: 0, alongEdgeAt: 0)")
    func pl122() throws {
        // U: P(0..2); planarEmbedding()!.face(from: 0, alongEdgeAt: 0) → vertices [0, 1, 2, 1, 0], edges [0, 1, 1, 0]
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 2)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0], [0, 1], [1]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        #expect(embedding.face(from: 0, alongEdgeAt: 0).vertices == [0, 1, 2, 1, 0] && embedding.face(from: 0, alongEdgeAt: 0).edges == [0, 1, 1, 0])
    }

    @Test("PL-123 square: inner and outer: planarEmbedding()!.face(from: 0, alongEdgeAt: 0)")
    func pl123() throws {
        // U: C(0..3); planarEmbedding()!.face(from: 0, alongEdgeAt: 0) → vertices [0, 1, 2, 3, 0], edges [0, 1, 2, 3]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0, 3], [0, 1], [1, 2], [2, 3]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        #expect(embedding.face(from: 0, alongEdgeAt: 0).vertices == [0, 1, 2, 3, 0] && embedding.face(from: 0, alongEdgeAt: 0).edges == [0, 1, 2, 3])
    }

    @Test("PL-124 square: the other side: planarEmbedding()!.face(from: 1, alongEdgeAt: 0)")
    func pl124() throws {
        // U: C(0..3); planarEmbedding()!.face(from: 1, alongEdgeAt: 0) → vertices [1, 0, 3, 2, 1], edges [0, 3, 2, 1]
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 4)
        #expect(Array(graph.vertices) == [0, 1, 2, 3])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0, 3], [0, 1], [1, 2], [2, 3]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        #expect(embedding.face(from: 1, alongEdgeAt: 0).vertices == [1, 0, 3, 2, 1] && embedding.face(from: 1, alongEdgeAt: 0).edges == [0, 3, 2, 1])
    }

    @Test("PL-125 loop: the face inside: planarEmbedding()!.face(from: 0, alongEdgeAt: 0)")
    func pl125() throws {
        // U: 0-0; planarEmbedding()!.face(from: 0, alongEdgeAt: 0) → vertices [0, 0], edges [0]
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [UndirectedEdge(0, 0)])
        #expect(graph.vertexCount == 1 && graph.edgeCount == 1)
        #expect(Array(graph.vertices) == [0])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(embedding.face(from: 0, alongEdgeAt: 0).vertices == [0, 0] && embedding.face(from: 0, alongEdgeAt: 0).edges == [0])
    }

    @Test("PL-126 cube: a square face: planarEmbedding()!.face(from: 0, alongEdgeAt: 0)")
    func pl126() throws {
        // U: Q(3); planarEmbedding()!.face(from: 0, alongEdgeAt: 0) → vertices [0, 1, 5, 4, 0], edges [0, 4, 8, 2]; or vertices [0, 1, 3, 2, 0], edges [0, 3, 5, 1] (mirror image)
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
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        let face = embedding.face(from: 0, alongEdgeAt: 0)
        #expect(face.vertices == (isA ? [0, 1, 5, 4, 0] : [0, 1, 3, 2, 0]))
        #expect(face.edges == (isA ? [0, 4, 8, 2] : [0, 3, 5, 1]))
    }

    @Test("PL-128 faceCount, isolated vertices only: planarEmbedding()!.faceCount")
    func pl128() throws {
        // U: E(3); planarEmbedding()!.faceCount → 0
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [] as [UndirectedEdge<Int>])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 0)
        #expect(Array(graph.vertices) == [0, 1, 2])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(embedding.faceCount == 0)
    }

    @Test("PL-129 faceCount, forest: planarEmbedding()!.faceCount")
    func pl129() throws {
        // U: P(0..3), P(4..6); planarEmbedding()!.faceCount → 2
        let graph = Pseudograph<Int>(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 3), UndirectedEdge(4, 5), UndirectedEdge(5, 6)])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 5)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4, 5, 6])
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        #expect(cyclic == [[0], [0, 1], [1, 2], [2], [3], [3, 4], [4]])
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        #expect(embedding.faceCount == 2)
    }

    @Test("PL-130 faceCount, grid 10 × 10: planarEmbedding()!.faceCount")
    func pl130() throws {
        // U: grid(10,10); planarEmbedding()!.faceCount → 82
        // The edges as flat (u, v) pairs in position order.
        let ends: [Int] = [0, 1, 0, 10, 1, 2, 1, 11, 2, 3, 2, 12, 3, 4, 3, 13, 4, 5, 4, 14, 5, 6, 5, 15,
            6, 7, 6, 16, 7, 8, 7, 17, 8, 9, 8, 18, 9, 19, 10, 11, 10, 20, 11, 12, 11, 21, 12, 13, 12, 22,
            13, 14, 13, 23, 14, 15, 14, 24, 15, 16, 15, 25, 16, 17, 16, 26, 17, 18, 17, 27, 18, 19, 18, 28,
            19, 29, 20, 21, 20, 30, 21, 22, 21, 31, 22, 23, 22, 32, 23, 24, 23, 33, 24, 25, 24, 34, 25, 26,
            25, 35, 26, 27, 26, 36, 27, 28, 27, 37, 28, 29, 28, 38, 29, 39, 30, 31, 30, 40, 31, 32, 31, 41,
            32, 33, 32, 42, 33, 34, 33, 43, 34, 35, 34, 44, 35, 36, 35, 45, 36, 37, 36, 46, 37, 38, 37, 47,
            38, 39, 38, 48, 39, 49, 40, 41, 40, 50, 41, 42, 41, 51, 42, 43, 42, 52, 43, 44, 43, 53, 44, 45,
            44, 54, 45, 46, 45, 55, 46, 47, 46, 56, 47, 48, 47, 57, 48, 49, 48, 58, 49, 59, 50, 51, 50, 60,
            51, 52, 51, 61, 52, 53, 52, 62, 53, 54, 53, 63, 54, 55, 54, 64, 55, 56, 55, 65, 56, 57, 56, 66,
            57, 58, 57, 67, 58, 59, 58, 68, 59, 69, 60, 61, 60, 70, 61, 62, 61, 71, 62, 63, 62, 72, 63, 64,
            63, 73, 64, 65, 64, 74, 65, 66, 65, 75, 66, 67, 66, 76, 67, 68, 67, 77, 68, 69, 68, 78, 69, 79,
            70, 71, 70, 80, 71, 72, 71, 81, 72, 73, 72, 82, 73, 74, 73, 83, 74, 75, 74, 84, 75, 76, 75, 85,
            76, 77, 76, 86, 77, 78, 77, 87, 78, 79, 78, 88, 79, 89, 80, 81, 80, 90, 81, 82, 81, 91, 82, 83,
            82, 92, 83, 84, 83, 93, 84, 85, 84, 94, 85, 86, 85, 95, 86, 87, 86, 96, 87, 88, 87, 97, 88, 89,
            88, 98, 89, 99, 90, 91, 91, 92, 92, 93, 93, 94, 94, 95, 95, 96, 96, 97, 97, 98, 98, 99]
        let graph = Pseudograph<Int>(vertices: 0 ..< 100, edges: stride(from: 0, to: ends.count, by: 2).map { UndirectedEdge(ends[$0], ends[$0 + 1]) })
        #expect(graph.vertexCount == 100 && graph.edgeCount == 180)
        let embedding = try #require(graph.planarEmbedding())
        let vertexList = Array(graph.vertices)
        let indexOf = Dictionary(uniqueKeysWithValues: vertexList.enumerated().map { ($1, $0) })
        // Each clockwise order: the vertex's incident edges (a loop twice), starting at the first one;
        // the neighbours, the index-space neighbours and the checked: spellings say the same.
        var rotation: [[Int]] = []
        for (i, v) in vertexList.enumerated() {
            let row = Array(embedding.clockwiseIncidentEdges(of: v))
            let incident = Array(graph.incidentEdges(of: v))
            let across = row.map { graph.oppositeVertex(to: v, acrossEdgeAt: $0) }
            #expect(row.sorted() == incident.sorted(), "the clockwise order at \(v) is not its incident edges")
            #expect(row.first == incident.first, "the clockwise order at \(v) does not start at its first edge")
            #expect(try Array(embedding.clockwiseIncidentEdges(checked: v)) == row)
            #expect(Array(embedding.clockwiseNeighbors(of: v)) == across)
            #expect(try Array(embedding.clockwiseNeighbors(checked: v)) == across)
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
        #expect(embedding.faceCount == 82 && orbits.count == 82)
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
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1], [0, 2, 3], [2, 4, 5], [4, 6, 7], [6, 8, 9], [8, 10, 11],
            [10, 12, 13], [12, 14, 15], [14, 16, 17], [16, 18], [1, 19, 20], [3, 21, 22, 19],
            [5, 23, 24, 21], [7, 25, 26, 23], [9, 27, 28, 25], [11, 29, 30, 27], [13, 31, 32, 29],
            [15, 33, 34, 31], [17, 35, 36, 33], [18, 37, 35], [20, 38, 39], [22, 40, 41, 38],
            [24, 42, 43, 40], [26, 44, 45, 42], [28, 46, 47, 44], [30, 48, 49, 46], [32, 50, 51, 48],
            [34, 52, 53, 50], [36, 54, 55, 52], [37, 56, 54], [39, 57, 58], [41, 59, 60, 57],
            [43, 61, 62, 59], [45, 63, 64, 61], [47, 65, 66, 63], [49, 67, 68, 65], [51, 69, 70, 67],
            [53, 71, 72, 69], [55, 73, 74, 71], [56, 75, 73], [58, 76, 77], [60, 78, 79, 76],
            [62, 80, 81, 78], [64, 82, 83, 80], [66, 84, 85, 82], [68, 86, 87, 84], [70, 88, 89, 86],
            [72, 90, 91, 88], [74, 92, 93, 90], [75, 94, 92], [77, 95, 96], [79, 97, 98, 95],
            [81, 99, 100, 97], [83, 101, 102, 99], [85, 103, 104, 101], [87, 105, 106, 103],
            [89, 107, 108, 105], [91, 109, 110, 107], [93, 111, 112, 109], [94, 113, 111], [96, 114, 115],
            [98, 116, 117, 114], [100, 118, 119, 116], [102, 120, 121, 118], [104, 122, 123, 120],
            [106, 124, 125, 122], [108, 126, 127, 124], [110, 128, 129, 126], [112, 130, 131, 128],
            [113, 132, 130], [115, 133, 134], [117, 135, 136, 133], [119, 137, 138, 135],
            [121, 139, 140, 137], [123, 141, 142, 139], [125, 143, 144, 141], [127, 145, 146, 143],
            [129, 147, 148, 145], [131, 149, 150, 147], [132, 151, 149], [134, 152, 153],
            [136, 154, 155, 152], [138, 156, 157, 154], [140, 158, 159, 156], [142, 160, 161, 158],
            [144, 162, 163, 160], [146, 164, 165, 162], [148, 166, 167, 164], [150, 168, 169, 166],
            [151, 170, 168], [153, 171], [155, 172, 171], [157, 173, 172], [159, 174, 173], [161, 175, 174],
            [163, 176, 175], [165, 177, 176], [167, 178, 177], [169, 179, 178], [170, 179]]
        let rotationB: [[Int]] = [[0, 1], [0, 3, 2], [2, 5, 4], [4, 7, 6], [6, 9, 8], [8, 11, 10],
            [10, 13, 12], [12, 15, 14], [14, 17, 16], [16, 18], [1, 20, 19], [3, 19, 22, 21],
            [5, 21, 24, 23], [7, 23, 26, 25], [9, 25, 28, 27], [11, 27, 30, 29], [13, 29, 32, 31],
            [15, 31, 34, 33], [17, 33, 36, 35], [18, 35, 37], [20, 39, 38], [22, 38, 41, 40],
            [24, 40, 43, 42], [26, 42, 45, 44], [28, 44, 47, 46], [30, 46, 49, 48], [32, 48, 51, 50],
            [34, 50, 53, 52], [36, 52, 55, 54], [37, 54, 56], [39, 58, 57], [41, 57, 60, 59],
            [43, 59, 62, 61], [45, 61, 64, 63], [47, 63, 66, 65], [49, 65, 68, 67], [51, 67, 70, 69],
            [53, 69, 72, 71], [55, 71, 74, 73], [56, 73, 75], [58, 77, 76], [60, 76, 79, 78],
            [62, 78, 81, 80], [64, 80, 83, 82], [66, 82, 85, 84], [68, 84, 87, 86], [70, 86, 89, 88],
            [72, 88, 91, 90], [74, 90, 93, 92], [75, 92, 94], [77, 96, 95], [79, 95, 98, 97],
            [81, 97, 100, 99], [83, 99, 102, 101], [85, 101, 104, 103], [87, 103, 106, 105],
            [89, 105, 108, 107], [91, 107, 110, 109], [93, 109, 112, 111], [94, 111, 113], [96, 115, 114],
            [98, 114, 117, 116], [100, 116, 119, 118], [102, 118, 121, 120], [104, 120, 123, 122],
            [106, 122, 125, 124], [108, 124, 127, 126], [110, 126, 129, 128], [112, 128, 131, 130],
            [113, 130, 132], [115, 134, 133], [117, 133, 136, 135], [119, 135, 138, 137],
            [121, 137, 140, 139], [123, 139, 142, 141], [125, 141, 144, 143], [127, 143, 146, 145],
            [129, 145, 148, 147], [131, 147, 150, 149], [132, 149, 151], [134, 153, 152],
            [136, 152, 155, 154], [138, 154, 157, 156], [140, 156, 159, 158], [142, 158, 161, 160],
            [144, 160, 163, 162], [146, 162, 165, 164], [148, 164, 167, 166], [150, 166, 169, 168],
            [151, 168, 170], [153, 171], [155, 171, 172], [157, 172, 173], [159, 173, 174], [161, 174, 175],
            [163, 175, 176], [165, 176, 177], [167, 177, 178], [169, 178, 179], [170, 179]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        #expect(embedding.faceCount == 82)
    }
}
