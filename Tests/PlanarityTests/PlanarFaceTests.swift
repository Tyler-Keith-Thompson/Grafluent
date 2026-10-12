// faces (catalog PL-097 – PL-107): unique embeddings, so the faces as vertex cycles are pinned, or
// every face reversed for the mirror image (the same choice as the rotation's).
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import Multigraphs
import Planarity
import Testing

@Suite("PlanarEmbedding.faces")
struct PlanarFaceTests {
    @Test("PL-097 triangle: planarEmbedding()!.faces")
    func pl097() throws {
        // U: C(0..2); planarEmbedding()!.faces → {(0 1 2), (0 2 1)}
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2),
            UndirectedEdge(2, 0)])
        #expect(graph.vertexCount == 3 && graph.edgeCount == 3)
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
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
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == [[0, 1, 2], [0, 2, 1]])
    }

    @Test("PL-098 square: planarEmbedding()!.faces")
    func pl098() throws {
        // U: C(0..3); planarEmbedding()!.faces → {(0 1 2 3), (0 3 2 1)}
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
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
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == [[0, 1, 2, 3], [0, 3, 2, 1]])
    }

    @Test("PL-099 path: one face: planarEmbedding()!.faces")
    func pl099() throws {
        // U: P(0..2); planarEmbedding()!.faces → {(0 1 2 1)}
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
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
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == [[0, 1, 2, 1]])
    }

    @Test("PL-100 star: one face: planarEmbedding()!.faces")
    func pl100() throws {
        // U: S(0;1..3); planarEmbedding()!.faces → {(0 1 0 2 0 3)}; or every face reversed (the mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3)])
        #expect(graph.vertexCount == 4 && graph.edgeCount == 3)
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1, 2], [0], [1], [2]]
        let rotationB: [[Int]] = [[0, 2, 1], [0], [1], [2]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == (isA ? [[0, 1, 0, 3, 0, 2]] : [[0, 1, 0, 2, 0, 3]]))
    }

    @Test("PL-101 K4: planarEmbedding()!.faces")
    func pl101() throws {
        // U: K(4); planarEmbedding()!.faces → {(0 1 2), (0 2 3), (0 3 1), (1 3 2)}; or every face reversed (the mirror image)
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
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
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == (isA ? [[0, 1, 3], [0, 2, 1], [0, 3, 2], [1, 2, 3]] : [[0, 1, 2], [0, 2, 3], [0, 3, 1], [1, 3, 2]]))
    }

    @Test("PL-102 wheel W5: planarEmbedding()!.faces")
    func pl102() throws {
        // U: nx(wheel,5); planarEmbedding()!.faces → {(0 1 2), (0 2 3), (0 3 4), (0 4 1), (1 4 3 2)}; or every face reversed (the mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 4),
            UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 8)
        #expect(Array(graph.vertices) == [0, 1, 2, 3, 4])
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 3, 2, 1], [0, 4, 5], [1, 6, 4], [2, 7, 6], [3, 5, 7]]
        let rotationB: [[Int]] = [[0, 1, 2, 3], [0, 5, 4], [1, 4, 6], [2, 6, 7], [3, 7, 5]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == (isA ? [[0, 1, 4], [0, 2, 1], [0, 3, 2], [0, 4, 3], [1, 2, 3, 4]] : [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [1, 4, 3, 2]]))
    }

    @Test("PL-103 cube: planarEmbedding()!.faces")
    func pl103() throws {
        // U: Q(3); planarEmbedding()!.faces → {(0 1 3 2), (0 2 6 4), (0 4 5 1), (1 5 7 3), (2 3 7 6), (4 6 7 5)}; or every face reversed (the mirror image)
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
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
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == (isA ? [[0, 1, 5, 4], [0, 2, 3, 1], [0, 4, 6, 2], [1, 3, 7, 5], [2, 6, 7, 3], [4, 5, 7, 6]] : [[0, 1, 3, 2], [0, 2, 6, 4], [0, 4, 5, 1], [1, 5, 7, 3], [2, 3, 7, 6], [4, 6, 7, 5]]))
    }

    @Test("PL-104 octahedron: planarEmbedding()!.faces")
    func pl104() throws {
        // U: nx(octahedral); planarEmbedding()!.faces → {(0 1 2), (0 2 4), (0 3 1), (0 4 3), (1 3 5), (1 5 2), (2 5 4), (3 4 5)}; or every face reversed (the mirror image)
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
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
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == (isA ? [[0, 1, 3], [0, 2, 1], [0, 3, 4], [0, 4, 2], [1, 2, 5], [1, 5, 3], [2, 4, 5], [3, 5, 4]] : [[0, 1, 2], [0, 2, 4], [0, 3, 1], [0, 4, 3], [1, 3, 5], [1, 5, 2], [2, 5, 4], [3, 4, 5]]))
    }

    @Test("PL-105 prism C3 × K2: planarEmbedding()!.faces")
    func pl105() throws {
        // U: nx(circular_ladder,3); planarEmbedding()!.faces → {(0 1 2), (0 2 5 3), (0 3 4 1), (1 4 5 2), (3 5 4)}; or every face reversed (the mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 3),
            UndirectedEdge(0, 2), UndirectedEdge(1, 2), UndirectedEdge(1, 4), UndirectedEdge(2, 5),
            UndirectedEdge(3, 4), UndirectedEdge(3, 5), UndirectedEdge(4, 5)])
        #expect(graph.vertexCount == 6 && graph.edgeCount == 9)
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 1, 2], [0, 3, 4], [2, 5, 3], [1, 6, 7], [4, 8, 6], [5, 7, 8]]
        let rotationB: [[Int]] = [[0, 2, 1], [0, 4, 3], [2, 3, 5], [1, 7, 6], [4, 6, 8], [5, 8, 7]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == (isA ? [[0, 1, 4, 3], [0, 2, 1], [0, 3, 5, 2], [1, 2, 5, 4], [3, 4, 5]] : [[0, 1, 2], [0, 2, 5, 3], [0, 3, 4, 1], [1, 4, 5, 2], [3, 5, 4]]))
    }

    @Test("PL-106 stacked triangulation: planarEmbedding()!.faces")
    func pl106() throws {
        // U: tri(7,4); planarEmbedding()!.faces → {(0 1 2), (0 2 6), (0 3 4), (0 4 1), (0 6 3), (1 3 2), (1 4 5), (1 5 3), (2 3 6), (3 5 4)}; or every face reversed (the mirror image)
        let graph = Pseudograph<Int>(vertices: 0 ..< 7, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2),
            UndirectedEdge(1, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 3), UndirectedEdge(2, 3),
            UndirectedEdge(0, 4), UndirectedEdge(1, 4), UndirectedEdge(3, 4), UndirectedEdge(1, 5),
            UndirectedEdge(3, 5), UndirectedEdge(4, 5), UndirectedEdge(0, 6), UndirectedEdge(2, 6),
            UndirectedEdge(3, 6)])
        #expect(graph.vertexCount == 7 && graph.edgeCount == 15)
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
        #expect(embedding.faceCount == 10 && orbits.count == 10)
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 6, 3, 12, 1], [0, 2, 4, 9, 7], [1, 13, 5, 2], [3, 8, 10, 4, 5, 14],
            [6, 7, 11, 8], [9, 10, 11], [12, 14, 13]]
        let rotationB: [[Int]] = [[0, 1, 12, 3, 6], [0, 7, 9, 4, 2], [1, 2, 5, 13], [3, 14, 5, 4, 10, 8],
            [6, 8, 11, 7], [9, 11, 10], [12, 13, 14]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == (isA ? [[0, 1, 4], [0, 2, 1], [0, 3, 6], [0, 4, 3], [0, 6, 2], [1, 2, 3], [1, 3, 5], [1, 5, 4], [2, 6, 3], [3, 4, 5]] : [[0, 1, 2], [0, 2, 6], [0, 3, 4], [0, 4, 1], [0, 6, 3], [1, 3, 2], [1, 4, 5], [1, 5, 3], [2, 3, 6], [3, 5, 4]]))
    }

    @Test("PL-107 theta graph: three paths from 0 to 1: planarEmbedding()!.faces")
    func pl107() throws {
        // U: P(0,2,1), P(0,3,1), P(0,4,1); planarEmbedding()!.faces → {(0 2 1 3), (0 3 1 4), (0 4 1 2)}; or every face reversed (the mirror image)
        let graph = Pseudograph<Int>(vertices: [0, 2, 1, 3, 4], edges: [UndirectedEdge(0, 2),
            UndirectedEdge(2, 1), UndirectedEdge(0, 3), UndirectedEdge(3, 1), UndirectedEdge(0, 4),
            UndirectedEdge(4, 1)])
        #expect(graph.vertexCount == 5 && graph.edgeCount == 6)
        #expect(Array(graph.vertices) == [0, 2, 1, 3, 4])
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
                let checkedFace = try embedding.face(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s])
                #expect(checkedFace.vertices == face.vertices && checkedFace.edges == face.edges)
                #expect(try embedding.rightFace(checkedFrom: vertexList[i], alongEdgeAt: rotation[i][s]) == faceOf[i][s])
            }
        }
        // Unique up to mirror image: every clockwise order, read cyclically, is the model's or, at
        // every vertex at once, its mirror image's.
        let cyclic = rotation.map { row in row.indices.map { Array(row[$0...] + row[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? [] }
        let rotationA: [[Int]] = [[0, 4, 2], [0, 1], [1, 3, 5], [2, 3], [4, 5]]
        let rotationB: [[Int]] = [[0, 2, 4], [0, 1], [1, 5, 3], [2, 3], [4, 5]]
        let isA = cyclic == rotationA
        #expect(isA || cyclic == rotationB)
        // A second call gives the same embedding.
        let again = try #require(graph.planarEmbedding())
        #expect(vertexList.map { Array(again.clockwiseIncidentEdges(of: $0)) } == rotation)
        #expect(again.faces.map(\.vertices) == embedding.faces.map(\.vertices) && again.faces.map(\.edges) == embedding.faces.map(\.edges))
        #expect(graph.isPlanar && graph.findKuratowskiSubgraph() == nil)
        #expect(!embedding.description.isEmpty)
        // Each face as a cycle of vertices from its least rotation, the faces sorted.
        let cycles = embedding.faces.map { face -> [Int] in
            let cycle = Array(face.vertices.dropLast())
            return cycle.indices.map { Array(cycle[$0...] + cycle[..<$0]) }.min { $0.lexicographicallyPrecedes($1) } ?? []
        }.sorted { $0.lexicographicallyPrecedes($1) }
        #expect(cycles == (isA ? [[0, 2, 1, 4], [0, 3, 1, 2], [0, 4, 1, 3]] : [[0, 2, 1, 3], [0, 3, 1, 4], [0, 4, 1, 2]]))
    }
}
