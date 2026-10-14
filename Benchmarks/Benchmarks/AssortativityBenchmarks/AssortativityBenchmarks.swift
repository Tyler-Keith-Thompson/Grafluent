import AdjacencyListModule
import Assortativity
import Benchmark
import BenchmarkSupport
import Distances
import GraphProtocols

/// Degree assortativity by hand: Pearson's r of the degrees at every edge end, two passes over
/// flat rows. The baseline for AS-B01.
func handWrittenAssortativity(_ offsets: [Int], _ targets: [Int]) -> Double {
    let n = offsets.count - 1, m = targets.count
    var degree = [Double](repeating: 0, count: n)
    for v in 0 ..< n { degree[v] = Double(offsets[v + 1] - offsets[v]) }
    var sum = 0.0
    for v in 0 ..< n { sum += degree[v] * degree[v] }
    let mean = sum / Double(m)
    var cross = 0.0, squares = 0.0
    for v in 0 ..< n {
        let dv = degree[v] - mean
        var row = 0.0
        for k in offsets[v] ..< offsets[v + 1] { row += degree[targets[k]] - mean }
        cross += dv * row
        squares += Double(offsets[v + 1] - offsets[v]) * dv * dv
    }
    return cross / squares
}

/// Directed degree assortativity by hand: the tail's out-degree against the head's in-degree over
/// flat out-rows. The baseline for AS-B01's directed rows.
func handWrittenDirectedAssortativity(_ offsets: [Int], _ targets: [Int]) -> Double {
    let n = offsets.count - 1, m = targets.count
    var x = [Double](repeating: 0, count: n), y = [Double](repeating: 0, count: n)
    for v in 0 ..< n { x[v] = Double(offsets[v + 1] - offsets[v]) }
    for w in targets { y[w] += 1 }
    var sumX = 0.0, sumY = 0.0
    for v in 0 ..< n { sumX += x[v] * x[v] }
    for w in targets { sumY += y[w] }
    let meanX = sumX / Double(m), meanY = sumY / Double(m)
    var cross = 0.0, squaresX = 0.0, squaresY = 0.0
    for v in 0 ..< n {
        let dx = x[v] - meanX
        var row = 0.0
        for k in offsets[v] ..< offsets[v + 1] {
            let dy = y[targets[k]] - meanY
            row += dy
            squaresY += dy * dy
        }
        cross += dx * row
        squaresX += x[v] * dx * dx
    }
    return cross / (squaresX * squaresY).squareRoot()
}

/// Average neighbor degrees by hand over flat rows. The baseline for AS-B02.
func handWrittenAverageNeighborDegrees(_ offsets: [Int], _ targets: [Int]) -> [Double] {
    let n = offsets.count - 1
    var averages = [Double](repeating: 0, count: n)
    for v in 0 ..< n {
        let d = offsets[v + 1] - offsets[v]
        guard d > 0 else { continue }
        var sum = 0
        for k in offsets[v] ..< offsets[v + 1] { sum += offsets[targets[k] + 1] - offsets[targets[k]] }
        averages[v] = Double(sum) / Double(d)
    }
    return averages
}

/// The same three loops over the rows `UndirectedAdjacencyList` and `AdjacencyList` store (each
/// row a block of a shared pool, found through a row table of three entries per vertex), so the
/// library and the baseline read the same memory.
func handWrittenPooledAssortativity(_ graph: UndirectedAdjacencyList<Int>) -> Double {
    graph._withIncidentIndexRows { neighbors, table, _, _ in
        let n = graph.vertexCount
        var degree = [Double](repeating: 0, count: n)
        var m = 0
        for v in 0 ..< n { degree[v] = Double(table[3 * v + 1]); m += table[3 * v + 1] }
        var sum = 0.0
        for v in 0 ..< n { sum += degree[v] * degree[v] }
        let mean = sum / Double(m)
        var cross = 0.0, squares = 0.0
        for v in 0 ..< n {
            let dv = degree[v] - mean
            var row = 0.0
            let start = table[3 * v]
            for k in start ..< start + table[3 * v + 1] { row += degree[neighbors[k]] - mean }
            cross += dv * row
            squares += degree[v] * dv * dv
        }
        return cross / squares
    }!
}

func handWrittenPooledAverageNeighborDegrees(_ graph: UndirectedAdjacencyList<Int>) -> [Double] {
    graph._withIncidentIndexRows { neighbors, table, _, _ in
        let n = graph.vertexCount
        var averages = [Double](repeating: 0, count: n)
        for v in 0 ..< n {
            let d = table[3 * v + 1]
            guard d > 0 else { continue }
            var sum = 0
            let start = table[3 * v]
            for k in start ..< start + d { sum += table[3 * neighbors[k] + 1] }
            averages[v] = Double(sum) / Double(d)
        }
        return averages
    }!
}

func handWrittenPooledDirectedAssortativity(_ graph: AdjacencyList<Int>) -> Double {
    graph._withOutIndexRows { targets, table, _, _ in
        let n = graph.vertexCount
        var x = [Double](repeating: 0, count: n), y = [Double](repeating: 0, count: n)
        var m = 0
        for v in 0 ..< n { x[v] = Double(table[3 * v + 1]); m += table[3 * v + 1] }
        for v in 0 ..< n {
            let start = table[3 * v]
            for k in start ..< start + table[3 * v + 1] { y[targets[k]] += 1 }
        }
        var sumX = 0.0, sumY = 0.0
        for v in 0 ..< n {
            sumX += x[v] * x[v]
            sumY += y[v] * y[v]
        }
        let meanX = sumX / Double(m), meanY = sumY / Double(m)
        var cross = 0.0, squaresX = 0.0, squaresY = 0.0
        for v in 0 ..< n {
            let dx = x[v] - meanX
            var row = 0.0
            let start = table[3 * v]
            for k in start ..< start + table[3 * v + 1] {
                let dy = y[targets[k]] - meanY
                row += dy
                squaresY += dy * dy
            }
            cross += dx * row
            squaresX += x[v] * dx * dx
        }
        return cross / (squaresX * squaresY).squareRoot()
    }!
}

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    // A sparse random graph G(10⁵, 5·10⁵), undirected and directed, and a smaller one for the
    // all-pairs efficiency.
    let arcs = Inputs.randomEdges(vertexCount: 100_000, edgeCount: 500_000, seed: 7)
    let undirected = UndirectedAdjacencyList(vertices: 0 ..< 100_000, edges: arcs.map { UndirectedEdge($0.source, $0.target) })
    let directed = AdjacencyList(vertices: 0 ..< 100_000, edges: arcs)
    let small = UndirectedAdjacencyList(vertices: 0 ..< 2000, edges: Inputs.randomEdges(vertexCount: 2000, edgeCount: 10_000, seed: 8).map { UndirectedEdge($0.source, $0.target) })
    var offsets = [0], targets: [Int] = []
    for v in 0 ..< undirected.vertexCount {
        targets.append(contentsOf: undirected.neighborIndices(ofIndex: v))
        offsets.append(targets.count)
    }
    var directedOffsets = [0], directedTargets: [Int] = []
    for v in 0 ..< directed.vertexCount {
        directedTargets.append(contentsOf: directed.successorIndices(ofIndex: v))
        directedOffsets.append(directedTargets.count)
    }
    precondition(abs(handWrittenAssortativity(offsets, targets) - undirected.degreeAssortativityCoefficient()!) < 1e-9)
    precondition(abs(handWrittenDirectedAssortativity(directedOffsets, directedTargets) - directed.degreeAssortativityCoefficient()!) < 1e-9)
    precondition(handWrittenAverageNeighborDegrees(offsets, targets) == undirected.averageNeighborDegrees().values)

    precondition(abs(handWrittenPooledAssortativity(undirected) - undirected.degreeAssortativityCoefficient()!) < 1e-9)
    precondition(handWrittenPooledAverageNeighborDegrees(undirected) == undirected.averageNeighborDegrees().values)
    precondition(abs(handWrittenPooledDirectedAssortativity(directed) - directed.degreeAssortativityCoefficient()!) < 1e-9)

    // AS-B01: degree assortativity. The flat-row baselines read a packed copy; the pooled ones
    // read the representation's own rows, as the library does.
    Benchmark("Assortativity: BASELINE hand-written pooled-row degree assortativity, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenPooledAssortativity(undirected)) }
    }
    Benchmark("Assortativity: BASELINE hand-written pooled-row directed degree assortativity, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenPooledDirectedAssortativity(directed)) }
    }
    Benchmark("Assortativity: BASELINE hand-written degree assortativity, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenAssortativity(offsets, targets)) }
    }
    Benchmark("Assortativity: degreeAssortativityCoefficient(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.degreeAssortativityCoefficient()) }
    }
    Benchmark("Assortativity: degreeAssortativityCoefficient(weight:), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.degreeAssortativityCoefficient(weight: { Double($0 & 7) })) }
    }
    Benchmark("Assortativity: BASELINE hand-written directed degree assortativity, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenDirectedAssortativity(directedOffsets, directedTargets)) }
    }
    Benchmark("Assortativity: directed degreeAssortativityCoefficient(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.degreeAssortativityCoefficient()) }
    }
    Benchmark("Assortativity: attributeAssortativityCoefficient(attribute:), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.attributeAssortativityCoefficient(attribute: { $0 % 7 })) }
    }
    // AS-B02: neighbor degrees.
    Benchmark("Assortativity: BASELINE hand-written pooled-row average neighbor degrees, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenPooledAverageNeighborDegrees(undirected)) }
    }
    Benchmark("Assortativity: BASELINE hand-written average neighbor degrees, G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(handWrittenAverageNeighborDegrees(offsets, targets)) }
    }
    Benchmark("Assortativity: averageNeighborDegrees(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.averageNeighborDegrees()) }
    }
    Benchmark("Assortativity: averageDegreeConnectivity(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.averageDegreeConnectivity()) }
    }
    Benchmark("Assortativity: directed averageNeighborDegrees(source: .total, target: .total), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.averageNeighborDegrees(source: .total, target: .total)) }
    }
    // AS-B03: reciprocity, the census, degree statistics.
    Benchmark("Assortativity: reciprocity(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.reciprocity()) }
    }
    Benchmark("Assortativity: triadicCensus(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(directed.triadicCensus()) }
    }
    Benchmark("Assortativity: richClubCoefficients(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.richClubCoefficients()) }
    }
    Benchmark("Assortativity: degreeHistogram() and sMetric(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(undirected.degreeHistogram())
            blackHole(undirected.sMetric())
        }
    }
    // AS-B04: efficiency (Distances).
    Benchmark("Assortativity: globalEfficiency(), G(2000, 10⁴)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(small.globalEfficiency()) }
    }
    Benchmark("Assortativity: localEfficiency(), G(10⁵, 5·10⁵)") { benchmark in
        for _ in benchmark.scaledIterations { blackHole(undirected.localEfficiency()) }
    }
}
