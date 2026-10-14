// Graph edit distance (catalog IS-234 – IS-267): unit costs, colours as substitution costs,
// self-loops and parallel edges matched as groups, directed graphs, upper bounds.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphProtocols
import IsomorphismModule
import Multigraphs
import Testing

@Suite("Graph edit distance")
struct GraphEditDistanceTests {
    @Test("IS-234 empty graphs")
    func is234() throws {
        // `U:` → `U:`; `graphEditDistance(to:)` ⇒ 0
        let pattern = Pseudograph<Int>()
        let target = Pseudograph<Int>()
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 0)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 0)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 0)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 0)
    }

    @Test("IS-235 one vertex deleted")
    func is235() throws {
        // `U: [0]` → `U:`; `graphEditDistance(to:)` ⇒ 1
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1))
        let target = Pseudograph<Int>()
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-236 K3 inserted: three vertices and three edges")
    func is236() throws {
        // `U:` → `U: K(3)`; `graphEditDistance(to:)` ⇒ 6
        let pattern = Pseudograph<Int>()
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 6)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 6)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 6)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 6)
    }

    @Test("IS-237 P3 to K3: one edge inserted")
    func is237() throws {
        // `U: P(0,1,2)` → `U: K(3)`; `graphEditDistance(to:)` ⇒ 1
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-238 C4 to P4: one edge deleted")
    func is238() throws {
        // `U: C(0,1,2,3)` → `U: P(0,1,2,3)`; `graphEditDistance(to:)` ⇒ 1
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-239 K4 to C4: the two diagonals")
    func is239() throws {
        // `U: K(4)` → `U: C(0,1,2,3)`; `graphEditDistance(to:)` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-240 star to path on four vertices: an edge moved")
    func is240() throws {
        // `U: S(0;1..3)` → `U: P(0,1,2,3)`; `graphEditDistance(to:)` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-241 two disjoint edges to P4")
    func is241() throws {
        // `U: 0-1, 2-3` → `U: P(0,1,2,3)`; `graphEditDistance(to:)` ⇒ 1
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-242 C6 to K3,3: three edges inserted")
    func is242() throws {
        // `U: C(0,1,2,3,4,5)` → `U: KB(0..2;3..5)`; `graphEditDistance(to:)` ⇒ 3
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        let targetEdges: [[Int]] = [
            [0, 3], [0, 4], [0, 5], [1, 3], [1, 4], [1, 5], [2, 3], [2, 4], [2, 5]
        ]
        let target = Pseudograph<Int>(vertices: [0, 3, 4, 5, 1, 2], edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 3)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 3)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 3)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 3)
    }

    @Test("IS-243 C5 to K5")
    func is243() throws {
        // `U: C(0,1,2,3,4)` → `U: K(5)`; `graphEditDistance(to:)` ⇒ 5
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        let targetEdges: [[Int]] = [
            [0, 1], [0, 2], [0, 3], [0, 4], [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4]
        ]
        let target = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: targetEdges.map { UndirectedEdge($0[0], $0[1]) })
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 5)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 5)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 5)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 5)
    }

    @Test("IS-244 C6 to two triangles")
    func is244() throws {
        // `U: C(0,1,2,3,4,5)` → `U: C(0,1,2), C(3,4,5)`; `graphEditDistance(to:)` ⇒ 4
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 6), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4), UndirectedEdge(4, 5), UndirectedEdge(5, 3)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 4)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 4)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 4)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 4)
    }

    @Test("IS-245 P5 to a relabelled P5: isomorphic")
    func is245() throws {
        // `U: P(0,1,2,3,4)` → `U: P(3,1,4,0,2)`; `graphEditDistance(to:)` ⇒ 0
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4)])
        let target = Pseudograph<Int>(vertices: [3, 1, 4, 0, 2], edges: [UndirectedEdge(3, 1), UndirectedEdge(1, 4), UndirectedEdge(4, 0), UndirectedEdge(0, 2)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 0)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 0)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 0)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 0)
    }

    @Test("IS-246 K2,3 to the 4-wheel minus a spoke")
    func is246() throws {
        // `U: KB(0..1;2..4)` → `U: C(0,1,2,3), 4-0, 4-1, 4-2`; `graphEditDistance(to:)` ⇒ 1
        let pattern = Pseudograph<Int>(vertices: [0, 2, 3, 4, 1], edges: [UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(0, 4), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0), UndirectedEdge(4, 0), UndirectedEdge(4, 1), UndirectedEdge(4, 2)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-247 triangle with a pendant to C4")
    func is247() throws {
        // `U: C(0,1,2), 2-3` → `U: C(0,1,2,3)`; `graphEditDistance(to:)` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-248 a self-loop deleted")
    func is248() throws {
        // `U: 0-0` → `U: [0]`; `graphEditDistance(to:)` ⇒ 1
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 1), edges: [UndirectedEdge(0, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 1))
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-249 a loop at the other end: isomorphic")
    func is249() throws {
        // `U: 0-1, 0-0` → `U: 0-1, 1-1`; `graphEditDistance(to:)` ⇒ 0
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 1)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 0)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 0)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 0)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 0)
    }

    @Test("IS-250 a doubled edge to one edge")
    func is250() throws {
        // `U: 0=1` → `U: 0-1`; `graphEditDistance(to:)` ⇒ 1
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-251 parallel edges into a triangle")
    func is251() throws {
        // `U: 0=1, 1-2` → `U: K(3)`; `graphEditDistance(to:)` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-252 two vertices to three, different sizes both ways")
    func is252() throws {
        // `U: 0-1` → `U: [0, 1, 2] 1-2, 2-2`; `graphEditDistance(to:)` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 2), edges: [UndirectedEdge(0, 1)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(1, 2), UndirectedEdge(2, 2)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-253 directed: an arc to its reverse")
    func is253() throws {
        // `D: 0>1` → `D: 1>0`; `graphEditDistance(to:)` ⇒ 0
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: [1, 0], edges: [DirectedEdge(from: 1, to: 0)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 0)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 0)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            #expect(path.image(of: pattern.source(ofEdgeAt: p)) == target.source(ofEdgeAt: q) && path.image(of: pattern.target(ofEdgeAt: p)) == target.target(ofEdgeAt: q))
        }
        #expect(total == 0)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 0)
    }

    @Test("IS-254 directed: a 2-cycle to one arc")
    func is254() throws {
        // `D: 0>1, 1>0` → `D: 0>1`; `graphEditDistance(to:)` ⇒ 1
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            #expect(path.image(of: pattern.source(ofEdgeAt: p)) == target.source(ofEdgeAt: q) && path.image(of: pattern.target(ofEdgeAt: p)) == target.target(ofEdgeAt: q))
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-255 directed: C3 to the transitive tournament")
    func is255() throws {
        // `D: C(0,1,2)` → `D: tt(3)`; `graphEditDistance(to:)` ⇒ 2
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 1, to: 2)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            #expect(path.image(of: pattern.source(ofEdgeAt: p)) == target.source(ofEdgeAt: q) && path.image(of: pattern.target(ofEdgeAt: p)) == target.target(ofEdgeAt: q))
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-256 directed: out-star to in-star")
    func is256() throws {
        // `D: 0>1, 0>2, 0>3` → `D: 1>0, 2>0, 3>0`; `graphEditDistance(to:)` ⇒ 4
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 2), DirectedEdge(from: 0, to: 3)])
        let target = DirectedPseudograph<Int>(vertices: [1, 0, 2, 3], edges: [DirectedEdge(from: 1, to: 0), DirectedEdge(from: 2, to: 0), DirectedEdge(from: 3, to: 0)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 4)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 4)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            #expect(path.image(of: pattern.source(ofEdgeAt: p)) == target.source(ofEdgeAt: q) && path.image(of: pattern.target(ofEdgeAt: p)) == target.target(ofEdgeAt: q))
        }
        #expect(total == 4)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 4)
    }

    @Test("IS-257 directed: path to cycle")
    func is257() throws {
        // `D: P(0,1,2,3)` → `D: C(0,1,2,3)`; `graphEditDistance(to:)` ⇒ 1
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3)])
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 4), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 3), DirectedEdge(from: 3, to: 0)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            #expect(path.image(of: pattern.source(ofEdgeAt: p)) == target.source(ofEdgeAt: q) && path.image(of: pattern.target(ofEdgeAt: p)) == target.target(ofEdgeAt: q))
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 1)
    }

    @Test("IS-258 directed: loops and parallel arcs")
    func is258() throws {
        // `D: 0>0, 0>1, 0>1` → `D: 1>1, 1>0, 0>1`; `graphEditDistance(to:)` ⇒ 2
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 0), DirectedEdge(from: 0, to: 1), DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: [1, 0], edges: [DirectedEdge(from: 1, to: 1), DirectedEdge(from: 1, to: 0), DirectedEdge(from: 0, to: 1)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            #expect(path.image(of: pattern.source(ofEdgeAt: p)) == target.source(ofEdgeAt: q) && path.image(of: pattern.target(ofEdgeAt: p)) == target.target(ofEdgeAt: q))
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-259 directed: empty to a 3-cycle")
    func is259() throws {
        // `D: [0, 1]` → `D: C(0,1,2)`; `graphEditDistance(to:)` ⇒ 4
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2))
        let target = DirectedPseudograph<Int>(vertices: Array(0 ..< 3), edges: [DirectedEdge(from: 0, to: 1), DirectedEdge(from: 1, to: 2), DirectedEdge(from: 2, to: 0)])
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 4)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 4)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            #expect(path.image(of: pattern.source(ofEdgeAt: p)) == target.source(ofEdgeAt: q) && path.image(of: pattern.target(ofEdgeAt: p)) == target.target(ofEdgeAt: q))
        }
        #expect(total == 4)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 4)
    }

    @Test("IS-260 P3 with colours a b a to P3 with a a b")
    func is260() throws {
        // `U: P(0,1,2)` → `U: P(0,1,2)`; `graphEditDistance(to:) vertexColor: G [a,b,a] H [a,a,b]` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let patternColor: [Int: String] = [0: "a", 1: "b", 2: "a"]
        let targetColor: [Int: String] = [0: "a", 1: "a", 2: "b"]
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target, vertexSubstitutionCost: { patternColor[$0]! == targetColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target, vertexSubstitutionCost: { patternColor[$0]! == targetColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if let x = path.image(of: v) { total += patternColor[v]! == targetColor[x]! ? 0 : 1 } else { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern, vertexSubstitutionCost: { targetColor[$0]! == patternColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(back == 2)
    }

    @Test("IS-261 K3 with one red vertex to K3 with none")
    func is261() throws {
        // `U: K(3)` → `U: K(3)`; `graphEditDistance(to:) vertexColor: G [r,b,b] H [b,b,b]` ⇒ 1
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 2)])
        let patternColor: [Int: String] = [0: "r", 1: "b", 2: "b"]
        let targetColor: [Int: String] = [0: "b", 1: "b", 2: "b"]
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target, vertexSubstitutionCost: { patternColor[$0]! == targetColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(distance == 1)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target, vertexSubstitutionCost: { patternColor[$0]! == targetColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(path.cost == 1)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if let x = path.image(of: v) { total += patternColor[v]! == targetColor[x]! ? 0 : 1 } else { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 1)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern, vertexSubstitutionCost: { targetColor[$0]! == patternColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(back == 1)
    }

    @Test("IS-262 C4 with edge colours x x y y to x y x y")
    func is262() throws {
        // `U: C(0,1,2,3)` → `U: C(0,1,2,3)`; `graphEditDistance(to:) edgeColor: G [x,x,y,y] H [x,y,x,y]` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        let patternEdgeColor = ["x", "x", "y", "y"]
        let targetEdgeColor = ["x", "y", "x", "y"]
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { patternEdgeColor[$0] == targetEdgeColor[$1] ? 0 : 1 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { patternEdgeColor[$0] == targetEdgeColor[$1] ? 0 : 1 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
            total += patternEdgeColor[p] == targetEdgeColor[q] ? 0 : 1
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { targetEdgeColor[$0] == patternEdgeColor[$1] ? 0 : 1 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(back == 2)
    }

    @Test("IS-263 a coloured doubled edge to one edge of either colour")
    func is263() throws {
        // `U: 0=1, 1-2` → `U: 0-1, 1-2`; `graphEditDistance(to:) edgeColor: G [x,y,x] H [y,y]` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 3), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        let patternEdgeColor = ["x", "y", "x"]
        let targetEdgeColor = ["y", "y"]
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { patternEdgeColor[$0] == targetEdgeColor[$1] ? 0 : 1 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { patternEdgeColor[$0] == targetEdgeColor[$1] ? 0 : 1 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
            total += patternEdgeColor[p] == targetEdgeColor[q] ? 0 : 1
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern, vertexSubstitutionCost: { _, _ in 0 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { targetEdgeColor[$0] == patternEdgeColor[$1] ? 0 : 1 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(back == 2)
    }

    @Test("IS-264 directed: an arc and its reverse with colours in vertices order: isomorphic")
    func is264() throws {
        // `D: 0>1` → `D: 1>0`; `graphEditDistance(to:) vertexColor: G [a,b] H [a,b]` ⇒ 0
        let pattern = DirectedPseudograph<Int>(vertices: Array(0 ..< 2), edges: [DirectedEdge(from: 0, to: 1)])
        let target = DirectedPseudograph<Int>(vertices: [1, 0], edges: [DirectedEdge(from: 1, to: 0)])
        let patternColor: [Int: String] = [0: "a", 1: "b"]
        let targetColor: [Int: String] = [1: "a", 0: "b"]
        // The catalog's value.
        let distance = pattern.graphEditDistance(to: target, vertexSubstitutionCost: { patternColor[$0]! == targetColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(distance == 0)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target, vertexSubstitutionCost: { patternColor[$0]! == targetColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 }))
        #expect(path.cost == 0)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if let x = path.image(of: v) { total += patternColor[v]! == targetColor[x]! ? 0 : 1 } else { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            #expect(path.image(of: pattern.source(ofEdgeAt: p)) == target.source(ofEdgeAt: q) && path.image(of: pattern.target(ofEdgeAt: p)) == target.target(ofEdgeAt: q))
        }
        #expect(total == 0)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern, vertexSubstitutionCost: { targetColor[$0]! == patternColor[$1]! ? 0 : 1 }, vertexDeletionCost: { _ in 1 }, vertexInsertionCost: { _ in 1 }, edgeSubstitutionCost: { _, _ in 0 }, edgeDeletionCost: { _ in 1 }, edgeInsertionCost: { _ in 1 })
        #expect(back == 0)
    }

    @Test("IS-265 upper bound below the distance: nil")
    func is265() throws {
        // `U: K(4)` → `U: C(0,1,2,3)`; `optimalEditPath(to:upperBound: 1)` ⇒ nil
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        // The catalog's value.
        let bounded = pattern.optimalEditPath(to: target, upperBound: 1)
        #expect(bounded == nil)
        // Without the bound: the distance.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-266 upper bound at the distance")
    func is266() throws {
        // `U: K(4)` → `U: C(0,1,2,3)`; `optimalEditPath(to:upperBound: 2)` ⇒ 2
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2), UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        let target = Pseudograph<Int>(vertices: Array(0 ..< 4), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 0)])
        // The catalog's value.
        let bounded = pattern.optimalEditPath(to: target, upperBound: 2)
        #expect(bounded?.cost == 2)
        // Without the bound: the distance.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 2)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 2)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 2)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 2)
    }

    @Test("IS-267 upper bound 0 on isomorphic graphs")
    func is267() throws {
        // `U: C(0,1,2,3,4)` → `U: C(0,2,4,1,3)`; `optimalEditPath(to:upperBound: 0)` ⇒ 0
        let pattern = Pseudograph<Int>(vertices: Array(0 ..< 5), edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4), UndirectedEdge(4, 0)])
        let target = Pseudograph<Int>(vertices: [0, 2, 4, 1, 3], edges: [UndirectedEdge(0, 2), UndirectedEdge(2, 4), UndirectedEdge(4, 1), UndirectedEdge(1, 3), UndirectedEdge(3, 0)])
        // The catalog's value.
        let bounded = pattern.optimalEditPath(to: target, upperBound: 0)
        #expect(bounded?.cost == 0)
        // Without the bound: the distance.
        let distance = pattern.graphEditDistance(to: target)
        #expect(distance == 0)
        // The optimal path: its operations add up to its cost (deletions and insertions 1,
        // substitutions 0 or 1 by colour), and every substituted edge joins the images of its ends.
        let path = try #require(pattern.optimalEditPath(to: target))
        #expect(path.cost == 0)
        #expect(path.isOptimal)
        var total = path.insertedVertices.count + path.deletedEdges.count + path.insertedEdges.count
        for v in pattern.vertices {
            if path.image(of: v) == nil { total += 1 }
        }
        for p in pattern.edges.indices {
            guard let q = path.edgeImage(ofEdgeAt: p) else { continue }
            #expect(path.edgePreimage(ofEdgeAt: q) == p)
            let ends = [path.image(of: pattern.edges[p].u), path.image(of: pattern.edges[p].v)], other = target.edges[q]
            #expect(ends == [other.u, other.v] || ends == [other.v, other.u])
        }
        #expect(total == 0)
        #expect(path.deletedVertices.count + target.vertexCount - path.insertedVertices.count == pattern.vertexCount)
        // The distance back is the same: every cost here is symmetric.
        let back = target.graphEditDistance(to: pattern)
        #expect(back == 0)
    }
}
