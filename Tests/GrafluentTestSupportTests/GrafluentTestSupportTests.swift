import GrafluentTestSupport
import GraphProtocols
import Testing

// The test support target is itself tested: a fixture with a wrong expected value, or a tracker
// that miscounts, would make every suite built on it worthless.

@Suite("Directed fixtures are internally consistent", .tags(.fixture))
struct DirectedFixtureConsistencyTests {
    @Test(arguments: DirectedFixture<Int>.all)
    func intFixture(_ fixture: DirectedFixture<Int>) {
        let vertices = Set(fixture.vertices).union(fixture.edges.flatMap { [$0.source, $0.target] })
        let edges = Set(fixture.edges)
        #expect(fixture.vertexSet == vertices)
        #expect(fixture.edgeSet == edges)
        #expect(vertices.count == fixture.vertexCount, "vertexCount")
        #expect(edges.count == fixture.edgeCount, "edgeCount")
        #expect(Set(fixture.outDegree.keys) == vertices, "outDegree covers every vertex")
        #expect(Set(fixture.inDegree.keys) == vertices, "inDegree covers every vertex")
        for v in vertices {
            #expect(edges.filter { $0.source == v }.count == fixture.outDegree[v], "outDegree(of: \(v))")
            #expect(edges.filter { $0.target == v }.count == fixture.inDegree[v], "inDegree(of: \(v))")
        }
        // Σ outDegree = Σ inDegree = edgeCount.
        #expect(fixture.outDegree.values.reduce(0, +) == fixture.edgeCount, "Σ outDegree")
        #expect(fixture.inDegree.values.reduce(0, +) == fixture.edgeCount, "Σ inDegree")
    }

    @Test(arguments: DirectedFixture<String>.all)
    func stringFixture(_ fixture: DirectedFixture<String>) {
        let vertices = Set(fixture.vertices).union(fixture.edges.flatMap { [$0.source, $0.target] })
        let edges = Set(fixture.edges)
        #expect(vertices.count == fixture.vertexCount, "vertexCount")
        #expect(edges.count == fixture.edgeCount, "edgeCount")
        #expect(Set(fixture.outDegree.keys) == vertices, "outDegree covers every vertex")
        #expect(Set(fixture.inDegree.keys) == vertices, "inDegree covers every vertex")
        for v in vertices {
            #expect(edges.filter { $0.source == v }.count == fixture.outDegree[v], "outDegree(of: \(v))")
            #expect(edges.filter { $0.target == v }.count == fixture.inDegree[v], "inDegree(of: \(v))")
        }
    }
}

@Suite("Test vertex types and instrumentation")
struct InstrumentationTests {
    @Test func colliderEqualityIgnoresTheChosenHash() {
        #expect(Collider(1, hash: 0) == Collider(1, hash: 5))
        #expect(Collider(1) != Collider(2))
        #expect(Collider(1).hashValue == Collider(2).hashValue)
    }

    @Test func hashableBoxComparesByValueNotIdentity() {
        let a = HashableBox(1, label: "a")
        let b = HashableBox(1, label: "b")
        #expect(a == b)
        #expect(a !== b)
        #expect(a.hashValue == b.hashValue)
    }

    @Test func minimalSequenceIsSinglePass() {
        let sequence = MinimalSequence(elements: [1, 2, 3], underestimatedCount: .half)
        #expect(sequence.underestimatedCount == 1)
        #expect(Array(sequence) == [1, 2, 3])
        #expect(Array(sequence) == [])
    }

    @Test func splitMix64IsDeterministic() {
        var a = SplitMix64(seed: 7)
        var b = SplitMix64(seed: 7)
        var c = SplitMix64(seed: 8)
        let first = (0 ..< 5).map { _ in a.next() }
        #expect(first == (0 ..< 5).map { _ in b.next() })
        #expect(first != (0 ..< 5).map { _ in c.next() })
    }

    @Test(.lifetimeChecked, .tags(.lifetime))
    func lifetimeTrackerCountsLiveInstances() {
        do {
            let tracked = LifetimeTracked(1)
            #expect(LifetimeTracker.current?.instances == 1)
            withExtendedLifetime(tracked) {}
        }
        #expect(LifetimeTracker.current?.instances == 0)
        #expect(LifetimeTracker.current?.created == 1)
    }

    /// Confirms exit tests work under both SwiftPM and Bazel before any suite depends on them.
    @Test(.tags(.precondition))
    func exitTestsAreSupported() async {
        await #expect(processExitsWith: .failure) {
            preconditionFailure("intentional")
        }
    }
}
