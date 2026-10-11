// stressMajorizationLayout (catalog DR-190 – DR-204): the converged stress within ±1%, the normalized
// stress against 1.02 × NetworkX's Kamada–Kawai (+ 1e-4), `stress` equal to the stress of `drawing`
// computed inline, monotone steps, determinism, and edge lengths.
// Generated from cases.md by swiftgen.py; see README.md.

import GraphDrawing
import GraphProtocols
import Multigraphs
import Testing

@Suite("stressMajorizationLayout")
struct StressMajorizationLayoutTests {
    @Test("DR-190 one vertex")
    func dr190() {
        // U: n=1;; stressMajorizationLayout() → [(0.0, 0.0)]; stress 0.0
        let graph = Pseudograph<Int>(vertices: 0 ..< 1, edges: [] as [UndirectedEdge<Int>])
        #expect(Array(graph.vertices) == Array(0 ..< 1) && graph.edgeCount == 0)
        let layout = graph.stressMajorizationLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 1))
        let expected: [SIMD2<Double>] = [SIMD2(0.0, 0.0)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(abs(stepper.stress) <= 1e-12)
    }

    @Test("DR-191 one edge")
    func dr191() {
        // U: 0-1; stressMajorizationLayout() → [(0.0, 0.0), (-1.0, 0.0)]; stress 0.0
        let graph = Pseudograph<Int>(vertices: 0 ..< 2, edges: [UndirectedEdge(0, 1)])
        #expect(Array(graph.vertices) == Array(0 ..< 2) && graph.edgeCount == 1)
        let layout = graph.stressMajorizationLayout()
        #expect(Array(layout.vertices) == Array(0 ..< 2))
        let expected: [SIMD2<Double>] = [SIMD2(0.0, 6.123233995736766e-17), SIMD2(-1.0, 1.2246467991473532e-16)]
        let got = layout.positions
        #expect(got.count == expected.count)
        for (a, b) in zip(got, expected) {
            #expect(abs(a.x - b.x) <= 1e-9 && abs(a.y - b.y) <= 1e-9, "\(a) vs \(b)")
        }
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(abs(stepper.stress) <= 1e-12)
    }

    @Test("DR-192 path of 3")
    func dr192() {
        // U: P(0,1,2); stressMajorizationLayout() → stress ≤ 0.001, normalized ≤ 0.0002 (NetworkX Kamada–Kawai 0.0000)
        let graph = Pseudograph<Int>(vertices: 0 ..< 3, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2)])
        #expect(Array(graph.vertices) == Array(0 ..< 3) && graph.edgeCount == 2)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 3))
        #expect(stepper.stress <= 0.001, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.0002, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-193 cycle C6")
    func dr193() {
        // U: C(0,1,2,3,4,5); stressMajorizationLayout() → stress ≈ 0.284077 (±1%), normalized ≤ 0.0195 (NetworkX Kamada–Kawai 0.0189)
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 6)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 6))
        #expect(abs(stepper.stress - 0.284077) <= 0.01 * 0.284077, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.0195, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-194 K4")
    func dr194() {
        // U: K(4); stressMajorizationLayout() → stress ≈ 0.171573 (±1%), normalized ≤ 0.0293 (NetworkX Kamada–Kawai 0.0286)
        let graph = Pseudograph<Int>(vertices: 0 ..< 4, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 3), UndirectedEdge(1, 2),
            UndirectedEdge(1, 3), UndirectedEdge(2, 3)])
        #expect(Array(graph.vertices) == Array(0 ..< 4) && graph.edgeCount == 6)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 4))
        #expect(abs(stepper.stress - 0.171573) <= 0.01 * 0.171573, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.0293, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-195 cycle C12")
    func dr195() {
        // U: C(0,1,2,3,4,5,6,7,8,9,10,11); stressMajorizationLayout() → stress ≈ 1.08842 (±1%), normalized ≤ 0.017 (NetworkX Kamada–Kawai 0.0165)
        let graph = Pseudograph<Int>(vertices: 0 ..< 12, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 6), UndirectedEdge(6, 7), UndirectedEdge(7, 8), UndirectedEdge(8, 9), UndirectedEdge(9, 10),
            UndirectedEdge(10, 11), UndirectedEdge(11, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 12) && graph.edgeCount == 12)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 12))
        #expect(abs(stepper.stress - 1.08842) <= 0.01 * 1.08842, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.017, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-196 grid 5 x 5")
    func dr196() {
        // U: grid(5,5); stressMajorizationLayout() → stress ≈ 6.61676 (±1%), normalized ≤ 0.0226 (NetworkX Kamada–Kawai 0.0221)
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 25))
        #expect(abs(stepper.stress - 6.61676) <= 0.01 * 6.61676, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.0226, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-197 binary tree of height 4 (as a graph)")
    func dr197() {
        // U: 0-1, 0-2, 1-3, 1-4, 2-5, 2-6, 3-7, 3-8, 4-9, 4-10, 5-11, 5-12, 6-13, 6-14, 7-15, 7-16, 8-17, 8-18, 9-19, 9-20, 10-21, 10-22, 11-23, 11-24, 12-25, 12-26, 13-27, 13-28, 14-29, 14-30; stressMajorizationLayout() → stress ≈ 18.0246 (±1%), normalized ≤ 0.0397 (NetworkX Kamada–Kawai 0.0388)
        let graph = Pseudograph<Int>(vertices: 0 ..< 31, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(1, 3), UndirectedEdge(1, 4),
            UndirectedEdge(2, 5), UndirectedEdge(2, 6), UndirectedEdge(3, 7), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(4, 10),
            UndirectedEdge(5, 11), UndirectedEdge(5, 12), UndirectedEdge(6, 13), UndirectedEdge(6, 14), UndirectedEdge(7, 15), UndirectedEdge(7, 16),
            UndirectedEdge(8, 17), UndirectedEdge(8, 18), UndirectedEdge(9, 19), UndirectedEdge(9, 20), UndirectedEdge(10, 21), UndirectedEdge(10, 22),
            UndirectedEdge(11, 23), UndirectedEdge(11, 24), UndirectedEdge(12, 25), UndirectedEdge(12, 26), UndirectedEdge(13, 27), UndirectedEdge(13, 28),
            UndirectedEdge(14, 29), UndirectedEdge(14, 30)])
        #expect(Array(graph.vertices) == Array(0 ..< 31) && graph.edgeCount == 30)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 31))
        #expect(abs(stepper.stress - 18.0246) <= 0.01 * 18.0246, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.0397, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-198 cube Q4")
    func dr198() {
        // U: Q(4); stressMajorizationLayout() → stress ≈ 15.2964 (±1%), normalized ≤ 0.2572 (NetworkX Kamada–Kawai 0.2520)
        let graph = Pseudograph<Int>(vertices: 0 ..< 16, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 2), UndirectedEdge(0, 4), UndirectedEdge(0, 8),
            UndirectedEdge(1, 3), UndirectedEdge(1, 5), UndirectedEdge(1, 9), UndirectedEdge(2, 3), UndirectedEdge(2, 6), UndirectedEdge(2, 10),
            UndirectedEdge(3, 7), UndirectedEdge(3, 11), UndirectedEdge(4, 5), UndirectedEdge(4, 6), UndirectedEdge(4, 12), UndirectedEdge(5, 7),
            UndirectedEdge(5, 13), UndirectedEdge(6, 7), UndirectedEdge(6, 14), UndirectedEdge(7, 15), UndirectedEdge(8, 9), UndirectedEdge(8, 10),
            UndirectedEdge(8, 12), UndirectedEdge(9, 11), UndirectedEdge(9, 13), UndirectedEdge(10, 11), UndirectedEdge(10, 14), UndirectedEdge(11, 15),
            UndirectedEdge(12, 13), UndirectedEdge(12, 14), UndirectedEdge(13, 15), UndirectedEdge(14, 15)])
        #expect(Array(graph.vertices) == Array(0 ..< 16) && graph.edgeCount == 32)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 16))
        #expect(abs(stepper.stress - 15.2964) <= 0.01 * 15.2964, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.2572, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-199 Petersen")
    func dr199() {
        // U: petersen; stressMajorizationLayout() → stress ≈ 5.22849 (±1%), normalized ≤ 0.1195 (NetworkX Kamada–Kawai 0.1170)
        let graph = Pseudograph<Int>(vertices: 0 ..< 10, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 0), UndirectedEdge(0, 5), UndirectedEdge(1, 6), UndirectedEdge(2, 7), UndirectedEdge(3, 8), UndirectedEdge(4, 9),
            UndirectedEdge(5, 7), UndirectedEdge(6, 8), UndirectedEdge(7, 9), UndirectedEdge(8, 5), UndirectedEdge(9, 6)])
        #expect(Array(graph.vertices) == Array(0 ..< 10) && graph.edgeCount == 15)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 10))
        #expect(abs(stepper.stress - 5.22849) <= 0.01 * 5.22849, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.1195, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-200 random graph, 40 vertices, 60 edges")
    func dr200() {
        // U: lcggraph(40,60,5); stressMajorizationLayout() → stress ≈ 67.7529 (±1%), normalized ≤ 0.0933 (NetworkX Kamada–Kawai 0.0913)
        let graph = Pseudograph<Int>(vertices: 0 ..< 40, edges: [UndirectedEdge(32, 13), UndirectedEdge(34, 5), UndirectedEdge(15, 11),
            UndirectedEdge(19, 29), UndirectedEdge(10, 24), UndirectedEdge(35, 34), UndirectedEdge(28, 11), UndirectedEdge(33, 37), UndirectedEdge(28, 23),
            UndirectedEdge(2, 20), UndirectedEdge(30, 24), UndirectedEdge(8, 2), UndirectedEdge(21, 14), UndirectedEdge(1, 14), UndirectedEdge(9, 19),
            UndirectedEdge(10, 9), UndirectedEdge(35, 33), UndirectedEdge(35, 13), UndirectedEdge(25, 29), UndirectedEdge(20, 1), UndirectedEdge(14, 38),
            UndirectedEdge(30, 4), UndirectedEdge(14, 36), UndirectedEdge(28, 34), UndirectedEdge(32, 20), UndirectedEdge(7, 16), UndirectedEdge(30, 10),
            UndirectedEdge(31, 17), UndirectedEdge(1, 12), UndirectedEdge(21, 5), UndirectedEdge(14, 36), UndirectedEdge(31, 38), UndirectedEdge(12, 10),
            UndirectedEdge(35, 39), UndirectedEdge(31, 32), UndirectedEdge(28, 9), UndirectedEdge(11, 12), UndirectedEdge(12, 21), UndirectedEdge(38, 0),
            UndirectedEdge(14, 35), UndirectedEdge(27, 1), UndirectedEdge(7, 21), UndirectedEdge(7, 22), UndirectedEdge(2, 17), UndirectedEdge(8, 6),
            UndirectedEdge(14, 25), UndirectedEdge(8, 31), UndirectedEdge(17, 14), UndirectedEdge(26, 15), UndirectedEdge(1, 23), UndirectedEdge(29, 30),
            UndirectedEdge(7, 23), UndirectedEdge(35, 38), UndirectedEdge(33, 7), UndirectedEdge(28, 3), UndirectedEdge(11, 25), UndirectedEdge(29, 15),
            UndirectedEdge(23, 18), UndirectedEdge(23, 2), UndirectedEdge(4, 13)])
        #expect(Array(graph.vertices) == Array(0 ..< 40) && graph.edgeCount == 60)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 40))
        #expect(abs(stepper.stress - 67.7529) <= 0.01 * 67.7529, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
        // Normalized stress over pairs in one component, weights d⁻²: 1 − (Σ w d e)² / (Σ w d² · Σ w e²).
        func normalizedStress(_ p: [SIMD2<Double>]) -> Double {
            var a = 0.0, b = 0.0, c = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n where hops[i][j] > 0 {
                    let dij = Double(hops[i][j])
                    let w = 1 / (dij * dij)
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    a += w * dij * e
                    b += w * dij * dij
                    c += w * e * e
                }
            }
            return b == 0 || c == 0 ? 1 : 1 - a * a / (b * c)
        }
        #expect(normalizedStress(layout.positions) <= 0.0933, "normalized \(normalizedStress(layout.positions))")
    }

    @Test("DR-201 two components: a triangle and an edge")
    func dr201() {
        // U: C(0,1,2), 3-4; stressMajorizationLayout() → stress ≈ 0.0794561 (±1%)
        let graph = Pseudograph<Int>(vertices: 0 ..< 5, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 0), UndirectedEdge(3, 4)])
        #expect(Array(graph.vertices) == Array(0 ..< 5) && graph.edgeCount == 4)
        var stepper = StressMajorizationLayout(graph)
        stepper.run()
        let layout = graph.stressMajorizationLayout()
        #expect(stepper.isFinished && stepper.drawing == layout)
        #expect(Array(layout.vertices) == Array(0 ..< 5))
        #expect(abs(stepper.stress - 0.0794561) <= 0.01 * 0.0794561, "stress \(stepper.stress)")
        // Hop distances by breadth-first search (loops ignored); -1 between components.
        let n = graph.vertexCount
        var adjacency = [[Int]](repeating: [], count: n)
        for edge in graph.edges where edge.u != edge.v {
            adjacency[edge.u].append(edge.v)
            adjacency[edge.v].append(edge.u)
        }
        var hops = [[Int]](repeating: [Int](repeating: -1, count: n), count: n)
        for s in 0 ..< n {
            hops[s][s] = 0
            var queue = [s]
            var head = 0
            while head < queue.count {
                let v = queue[head]
                head += 1
                for w in adjacency[v] where hops[s][w] < 0 {
                    hops[s][w] = hops[s][v] + 1
                    queue.append(w)
                }
            }
        }
        // Target distances: hops, and 1 + √n between components (unit edge lengths); stress Σ_{i<j} d⁻² (‖x_i − x_j‖ − d)².
        func rawStress(_ p: [SIMD2<Double>]) -> Double {
            var s = 0.0
            for i in 0 ..< n {
                for j in i + 1 ..< n {
                    let dij = hops[i][j] > 0 ? Double(hops[i][j]) : 1 + Double(n).squareRoot()
                    let delta = p[i] - p[j]
                    let e = (delta * delta).sum().squareRoot()
                    s += (e - dij) * (e - dij) / (dij * dij)
                }
            }
            return s
        }
        // `stress` is the stress of `drawing`.
        #expect(abs(rawStress(layout.positions) - stepper.stress) <= 1e-9 * Swift.max(1, stepper.stress))
    }

    @Test("DR-202 stress never increases between steps")
    func dr202() {
        // U: grid(5,5); StressMajorizationLayout: stress after each step() → non-increasing
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        var layout = StressMajorizationLayout(graph)
        var previous = layout.stress
        var steps = 0
        #expect(layout.iteration == 0 && !layout.isFinished)
        while !layout.isFinished {
            layout.step()
            steps += 1
            #expect(layout.stress <= previous * (1 + 1e-12), "step \(steps): \(layout.stress) after \(previous)")
            previous = layout.stress
        }
        #expect(layout.iteration == steps && steps >= 1 && steps <= 1000)
        let finished = layout.drawing
        layout.step()
        #expect(layout.drawing == finished && layout.iteration == steps)
    }

    @Test("DR-203 initial drawing is used as given (no randomness)")
    func dr203() {
        // U: grid(5,5); two calls → equal
        let graph = Pseudograph<Int>(vertices: 0 ..< 25, edges: [UndirectedEdge(0, 1), UndirectedEdge(0, 5), UndirectedEdge(1, 2), UndirectedEdge(1, 6),
            UndirectedEdge(2, 3), UndirectedEdge(2, 7), UndirectedEdge(3, 4), UndirectedEdge(3, 8), UndirectedEdge(4, 9), UndirectedEdge(5, 6),
            UndirectedEdge(5, 10), UndirectedEdge(6, 7), UndirectedEdge(6, 11), UndirectedEdge(7, 8), UndirectedEdge(7, 12), UndirectedEdge(8, 9),
            UndirectedEdge(8, 13), UndirectedEdge(9, 14), UndirectedEdge(10, 11), UndirectedEdge(10, 15), UndirectedEdge(11, 12), UndirectedEdge(11, 16),
            UndirectedEdge(12, 13), UndirectedEdge(12, 17), UndirectedEdge(13, 14), UndirectedEdge(13, 18), UndirectedEdge(14, 19), UndirectedEdge(15, 16),
            UndirectedEdge(15, 20), UndirectedEdge(16, 17), UndirectedEdge(16, 21), UndirectedEdge(17, 18), UndirectedEdge(17, 22), UndirectedEdge(18, 19),
            UndirectedEdge(18, 23), UndirectedEdge(19, 24), UndirectedEdge(20, 21), UndirectedEdge(21, 22), UndirectedEdge(22, 23), UndirectedEdge(23, 24)])
        #expect(Array(graph.vertices) == Array(0 ..< 25) && graph.edgeCount == 40)
        let first = graph.stressMajorizationLayout()
        let second = graph.stressMajorizationLayout()
        #expect(first == second)
        // The default start is circularLayout(): passing it gives the same drawing.
        #expect(graph.stressMajorizationLayout(initial: graph.circularLayout()) == first)
        let start = Drawing(vertices: 0 ..< 25, positions: (0 ..< 25).map { SIMD2(Double($0 % 5), Double($0 / 5) * 1.5) })
        #expect(graph.stressMajorizationLayout(initial: start) == graph.stressMajorizationLayout(initial: start))
        var stepper = StressMajorizationLayout(graph, initial: start, maxIterations: 0)
        #expect(stepper.drawing == start)
        stepper.run()
        #expect(stepper.drawing == start && stepper.iteration == 0)
    }

    @Test("DR-204 edge length 2 doubles the drawing")
    func dr204() {
        // U: C(0,1,2,3,4,5); stressMajorizationLayout(edgeLength: { _ in 2 }) vs default → positions × 2 (exact)
        let graph = Pseudograph<Int>(vertices: 0 ..< 6, edges: [UndirectedEdge(0, 1), UndirectedEdge(1, 2), UndirectedEdge(2, 3), UndirectedEdge(3, 4),
            UndirectedEdge(4, 5), UndirectedEdge(5, 0)])
        #expect(Array(graph.vertices) == Array(0 ..< 6) && graph.edgeCount == 6)
        let unit = graph.stressMajorizationLayout()
        let doubled = graph.stressMajorizationLayout(edgeLength: { _ in 2 })
        #expect(unit.vertices == doubled.vertices)
        #expect(doubled.positions == unit.positions.map { 2 * $0 })
        // The default start is scaled by the mean edge length, and so is every step.
        #expect(StressMajorizationLayout(graph, edgeLength: { _ in 2 }).drawing == graph.circularLayout(radius: 2))
        var unitStepper = StressMajorizationLayout(graph)
        unitStepper.run()
        var doubledStepper = StressMajorizationLayout(graph, edgeLength: { _ in 2 })
        doubledStepper.run()
        #expect(doubledStepper.iteration == unitStepper.iteration && doubledStepper.stress == unitStepper.stress)
        #expect(doubledStepper.drawing == doubled)
    }
}
