import Benchmark
import BenchmarkSupport
import EdgeListModule
import Foundation
import GraphProtocols

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration.metrics = [.wallClock, .mallocCountTotal, .peakMemoryResident]
    Benchmark.defaultConfiguration.maxDuration = .seconds(2)

    let edges = Inputs.randomEdges(vertexCount: 10_000, edgeCount: 1_000_000)
    let list = EdgeList(edges)
    let probe = edges[edges.count / 2]
    let other = EdgeList(edges.lazy.map { $0 })
    let endpoints = edges.flatMap { [$0.source, $0.target] }
    let json = try! JSONEncoder().encode(endpoints)

    // From an array, the list shares the array's buffer; from a lazy sequence, it copies.
    Benchmark("EdgeList: build from 1M edges in a lazy sequence") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(EdgeList(edges.lazy.map { $0 }))
        }
    }

    // An edge list should cost what an array costs.
    Benchmark("EdgeList: iterate 1M edges") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for edge in list { sum &+= edge.source ^ edge.target }
            blackHole(sum)
        }
    }

    Benchmark("EdgeList: BASELINE iterate the same [DirectedEdge]") { benchmark in
        for _ in benchmark.scaledIterations {
            var sum = 0
            for edge in edges { sum &+= edge.source ^ edge.target }
            blackHole(sum)
        }
    }

    Benchmark("EdgeList: sort 1M edges by (source, target)") { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = list
            benchmark.startMeasurement()
            copy.sort { ($0.source, $0.target) < ($1.source, $1.target) }
            benchmark.stopMeasurement()
            blackHole(copy)
        }
    }

    Benchmark("EdgeList: vertices of 1M edges") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(list.vertices)
        }
    }

    Benchmark("EdgeList: outDegree scan of 1M edges") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(list.outDegree(of: probe.source))
        }
    }

    Benchmark("EdgeList: removeEdges(incidentTo:) on 1M edges") { benchmark in
        for _ in benchmark.scaledIterations {
            // Make the copy unique first, so only the removal is measured.
            var copy = list
            copy.append(DirectedEdge(from: -1, to: -1))
            copy.removeLast()
            benchmark.startMeasurement()
            blackHole(copy.removeEdges(incidentTo: probe.source))
            benchmark.stopMeasurement()
            blackHole(copy)
        }
    }

    // The review measured each slice mutation copying the whole list.
    Benchmark("EdgeList: sort 8 edges through a slice of a 1M-edge list, 100 times (must not copy the list)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = list
            copy.append(DirectedEdge(from: -1, to: -1))
            copy.removeLast()
            benchmark.startMeasurement()
            for k in 0 ..< 100 { copy[k * 8 ..< k * 8 + 8].sort() }
            benchmark.stopMeasurement()
            blackHole(copy)
        }
    }

    Benchmark("EdgeList: BASELINE the same slice sorts on [DirectedEdge]", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = edges
            copy.append(DirectedEdge(from: -1, to: -1))
            copy.removeLast()
            benchmark.startMeasurement()
            for k in 0 ..< 100 { copy[k * 8 ..< k * 8 + 8].sort() }
            benchmark.stopMeasurement()
            blackHole(copy)
        }
    }

    Benchmark("EdgeList: outDegrees of every vertex in one pass") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(list.outDegrees)
        }
    }

    Benchmark("EdgeList: Array(list) (must not copy)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(Array(list))
        }
    }

    Benchmark("EdgeList: description of a 1M-edge list") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(list.description)
        }
    }

    Benchmark("EdgeList: JSON-encode 1M edges") { benchmark in
        let encoder = JSONEncoder()
        for _ in benchmark.scaledIterations {
            blackHole(try encoder.encode(list))
        }
    }

    Benchmark("EdgeList: BASELINE JSON-encode the same endpoints as [Int]") { benchmark in
        let encoder = JSONEncoder()
        for _ in benchmark.scaledIterations {
            blackHole(try encoder.encode(endpoints))
        }
    }

    Benchmark("EdgeList: JSON-decode 1M edges") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            blackHole(try decoder.decode(EdgeList<Int>.self, from: json))
        }
    }

    Benchmark("EdgeList: BASELINE JSON-decode the same endpoints as [Int]") { benchmark in
        let decoder = JSONDecoder()
        for _ in benchmark.scaledIterations {
            blackHole(try decoder.decode([Int].self, from: json))
        }
    }

    Benchmark("EdgeList: no-op mutation of a copy (must not allocate)", configuration: .init(metrics: [.wallClock, .mallocCountTotal])) { benchmark in
        for _ in benchmark.scaledIterations {
            var copy = list
            copy.remove(edge: DirectedEdge(from: -1, to: -1))
            copy.removeEdges(incidentTo: -1)
            blackHole(copy)
        }
    }

    Benchmark("EdgeList: == on equal 1M-edge lists") { benchmark in
        for _ in benchmark.scaledIterations {
            blackHole(list == other)
        }
    }
}
