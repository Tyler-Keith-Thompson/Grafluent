// Drawing (catalog DR-001 – DR-021): a position per vertex in the order given, lookup by vertex
// (`position(of:)`, `position(checked:)`, `setPosition(_:of:)`), (vertex, position) elements, equality
// in order, the bounding box, and `rescaled(scale:center:)`. Exact.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphDrawing
import GraphProtocols
import Testing

@Suite("Drawing")
struct DrawingTests {
    @Test("DR-001 empty drawing: no vertices")
    func dr001() {
        // Drawing<Int>(); count → 0
        let drawing = Drawing<Int>()
        #expect(drawing.count == 0 && drawing.isEmpty)
        #expect(drawing.vertices.isEmpty && drawing.positions.isEmpty)
        #expect(drawing.startIndex == drawing.endIndex)
    }

    @Test("DR-002 empty drawing: no bounding box")
    func dr002() {
        // Drawing<Int>(); boundingBox → nil
        let drawing = Drawing<Int>()
        #expect(drawing.boundingBox == nil)
    }

    @Test("DR-003 empty drawing: rescaled stays empty")
    func dr003() {
        // Drawing<Int>(); rescaled() → []
        let drawing = Drawing<Int>()
        let rescaled = drawing.rescaled()
        #expect(rescaled.isEmpty && rescaled == drawing)
        var copy = drawing
        copy.rescale()
        #expect(copy == drawing)
    }

    @Test("DR-004 positions in vertices order")
    func dr004() {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)]); positions → [(0.0, 0.0), (2.0, 1.0)]
        let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        #expect(drawing.positions == [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        #expect(Array(drawing.vertices) == [5, 3] && drawing.count == 2)
    }

    @Test("DR-005 position(of:) reads by vertex")
    func dr005() {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)]); position(of: 3) → (2.0, 1.0)
        let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        let position = drawing.position(of: 3)
        #expect(position == SIMD2(2.0, 1.0))
        let other = drawing.position(of: 5)
        #expect(other == SIMD2(0.0, 0.0))
    }

    @Test("DR-006 setPosition(_:of:) writes by vertex")
    func dr006() {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)]); setPosition((7, -1), of: 5); positions → [(7.0, -1.0), (2.0, 1.0)]
        var drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        drawing.setPosition(SIMD2(7.0, -1.0), of: 5)
        #expect(drawing.positions == [SIMD2(7.0, -1.0), SIMD2(2.0, 1.0)])
        #expect(Array(drawing.vertices) == [5, 3])
        let written = drawing.position(of: 5)
        #expect(written == SIMD2(7.0, -1.0))
    }

    @Test("DR-008 position(checked:) on a missing vertex")
    func dr008() {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)]); position(checked: 4) → throws VertexNotFound
        let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        #expect(throws: VertexNotFound.self) { try drawing.position(checked: 4) }
        #expect(throws: VertexNotFound.self) { try drawing.position(checked: 0) }
        #expect(throws: VertexNotFound.self) { try drawing.position(checked: 1) }
    }

    @Test("DR-009 position(checked:) on a vertex")
    func dr009() throws {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)]); position(checked: 5) → (0.0, 0.0)
        let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        #expect(try drawing.position(checked: 5) == SIMD2(0.0, 0.0))
        #expect(try drawing.position(checked: 3) == SIMD2(2.0, 1.0))
    }

    @Test("DR-012 elements are (vertex, position) pairs in order")
    func dr012() throws {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)]); Array(self) → [(5, (0.0, 0.0)), (3, (2.0, 1.0))]
        let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        let elements = Array(drawing)
        #expect(elements.map(\.vertex) == [5, 3])
        #expect(elements.map(\.position) == [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        var visited: [Int] = []
        for (vertex, position) in drawing {
            visited.append(vertex)
            #expect(try drawing.position(checked: vertex) == position)
        }
        #expect(visited == [5, 3])
    }

    @Test("DR-013 equal when vertices and positions are equal in order")
    func dr013() throws {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)])` vs `Drawing(vertices: [3, 5], positions: [(2, 1), (0, 0)]); == → false
        let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        let reordered = Drawing(vertices: [3, 5], positions: [SIMD2(2.0, 1.0), SIMD2(0.0, 0.0)])
        #expect(drawing != reordered)
        #expect(try drawing.position(checked: 3) == reordered.position(checked: 3) && drawing.position(checked: 5) == reordered.position(checked: 5))
        let same = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        #expect(drawing == same && drawing.hashValue == same.hashValue)
    }

    @Test("DR-014 bounding box")
    func dr014() throws {
        // Drawing(vertices: [5, 3], positions: [(0, 0), (2, 1)]); boundingBox → (min: (0.0, 0.0), max: (2.0, 1.0))
        let drawing = Drawing(vertices: [5, 3], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        let box = try #require(drawing.boundingBox)
        #expect(box.min == SIMD2(0.0, 0.0) && box.max == SIMD2(2.0, 1.0))
    }

    @Test("DR-015 rescaled: centred, largest |coordinate| = 1")
    func dr015() {
        // Drawing(vertices: [0, 1], positions: [(0.0, 0.0), (2.0, 1.0)]); rescaled(scale: 1.0, center: (0.0, 0.0)) → [(-1.0, -0.5), (1.0, 0.5)]
        let drawing = Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        let rescaled = drawing.rescaled(scale: 1.0, center: SIMD2(0.0, 0.0))
        #expect(rescaled.positions == [SIMD2(-1.0, -0.5), SIMD2(1.0, 0.5)])
        #expect(rescaled.vertices == drawing.vertices)
        var copy = drawing
        copy.rescale(scale: 1.0, center: SIMD2(0.0, 0.0))
        #expect(copy == rescaled)
    }

    @Test("DR-016 rescaled: scale 3")
    func dr016() {
        // Drawing(vertices: [0, 1], positions: [(0.0, 0.0), (2.0, 1.0)]); rescaled(scale: 3.0, center: (0.0, 0.0)) → [(-3.0, -1.5), (3.0, 1.5)]
        let drawing = Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        let rescaled = drawing.rescaled(scale: 3.0, center: SIMD2(0.0, 0.0))
        #expect(rescaled.positions == [SIMD2(-3.0, -1.5), SIMD2(3.0, 1.5)])
        #expect(rescaled.vertices == drawing.vertices)
        var copy = drawing
        copy.rescale(scale: 3.0, center: SIMD2(0.0, 0.0))
        #expect(copy == rescaled)
    }

    @Test("DR-017 rescaled: centre (10, -2)")
    func dr017() {
        // Drawing(vertices: [0, 1], positions: [(0.0, 0.0), (2.0, 1.0)]); rescaled(scale: 1.0, center: (10.0, -2.0)) → [(9.0, -2.5), (11.0, -1.5)]
        let drawing = Drawing(vertices: [0, 1], positions: [SIMD2(0.0, 0.0), SIMD2(2.0, 1.0)])
        let rescaled = drawing.rescaled(scale: 1.0, center: SIMD2(10.0, -2.0))
        #expect(rescaled.positions == [SIMD2(9.0, -2.5), SIMD2(11.0, -1.5)])
        #expect(rescaled.vertices == drawing.vertices)
        var copy = drawing
        copy.rescale(scale: 1.0, center: SIMD2(10.0, -2.0))
        #expect(copy == rescaled)
    }

    @Test("DR-018 rescaled: three points, the y extent decides")
    func dr018() {
        // Drawing(vertices: [0, 1, 2], positions: [(0.0, 0.0), (1.0, 4.0), (2.0, -4.0)]); rescaled(scale: 1.0, center: (0.0, 0.0)) → [(-0.25, 0.0), (0.0, 1.0), (0.25, -1.0)]
        let drawing = Drawing(vertices: [0, 1, 2], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 4.0), SIMD2(2.0, -4.0)])
        let rescaled = drawing.rescaled(scale: 1.0, center: SIMD2(0.0, 0.0))
        #expect(rescaled.positions == [SIMD2(-0.25, 0.0), SIMD2(0.0, 1.0), SIMD2(0.25, -1.0)])
        #expect(rescaled.vertices == drawing.vertices)
        var copy = drawing
        copy.rescale(scale: 1.0, center: SIMD2(0.0, 0.0))
        #expect(copy == rescaled)
    }

    @Test("DR-019 rescaled: one point goes to the centre")
    func dr019() {
        // Drawing(vertices: [0], positions: [(3.0, 4.0)]); rescaled(scale: 1.0, center: (0.0, 0.0)) → [(0.0, 0.0)]
        let drawing = Drawing(vertices: [0], positions: [SIMD2(3.0, 4.0)])
        let rescaled = drawing.rescaled(scale: 1.0, center: SIMD2(0.0, 0.0))
        #expect(rescaled.positions == [SIMD2(0.0, 0.0)])
        #expect(rescaled.vertices == drawing.vertices)
        var copy = drawing
        copy.rescale(scale: 1.0, center: SIMD2(0.0, 0.0))
        #expect(copy == rescaled)
    }

    @Test("DR-020 rescaled: coincident points go to the centre")
    func dr020() {
        // Drawing(vertices: [0, 1], positions: [(3.0, 4.0), (3.0, 4.0)]); rescaled(scale: 2.0, center: (1.0, 1.0)) → [(1.0, 1.0), (1.0, 1.0)]
        let drawing = Drawing(vertices: [0, 1], positions: [SIMD2(3.0, 4.0), SIMD2(3.0, 4.0)])
        let rescaled = drawing.rescaled(scale: 2.0, center: SIMD2(1.0, 1.0))
        #expect(rescaled.positions == [SIMD2(1.0, 1.0), SIMD2(1.0, 1.0)])
        #expect(rescaled.vertices == drawing.vertices)
        var copy = drawing
        copy.rescale(scale: 2.0, center: SIMD2(1.0, 1.0))
        #expect(copy == rescaled)
    }

    @Test("DR-021 rescaled: square")
    func dr021() {
        // Drawing(vertices: [0, 1, 2, 3], positions: [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]); rescaled(scale: 1.0, center: (0.0, 0.0)) → [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)]
        let drawing = Drawing(vertices: [0, 1, 2, 3], positions: [SIMD2(0.0, 0.0), SIMD2(1.0, 0.0), SIMD2(1.0, 1.0), SIMD2(0.0, 1.0)])
        let rescaled = drawing.rescaled(scale: 1.0, center: SIMD2(0.0, 0.0))
        #expect(rescaled.positions == [SIMD2(-1.0, -1.0), SIMD2(1.0, -1.0), SIMD2(1.0, 1.0), SIMD2(-1.0, 1.0)])
        #expect(rescaled.vertices == drawing.vertices)
        var copy = drawing
        copy.rescale(scale: 1.0, center: SIMD2(0.0, 0.0))
        #expect(copy == rescaled)
    }
}
