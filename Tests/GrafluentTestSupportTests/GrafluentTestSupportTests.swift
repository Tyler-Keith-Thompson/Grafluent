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

    // Expected values come from the reference C implementations (splitmix64.c seeding
    // xoroshiro128plus.c, https://prng.di.unimi.it), not from this Swift code.
    @Test func seededGeneratorMatchesTheReferenceImplementation() {
        let reference: [UInt: [UInt64]] = [
            462346254: [
                7188512221314505992, 13067092035217335334, 18036172061541971367, 8098609137924594849,
                239428566617223886, 6872094544315259919, 16501699288111535592, 9712912748733719603,
                5300755583954492353, 3025778352444969603,
            ],
            245624567: [16175927826622449706, 5627237920778996644, 10394421899939585479],
            12346: [16039327328697369042, 18199867944689021781, 3928971382274766616],
            0xE24582F: [1680410077313269968, 18068499793270021440, 9153120156528839347],
            0: [5807750865143411619, 38375600193489914, 1180499099402622421],
            1: [5761717516557699368, 17295345234682295910, 1053790060648499002],
        ]
        for (seed, expected) in reference {
            var rng = SeededRandomNumberGenerator(seed: seed)
            #expect(expected.map { _ in rng.next() } == expected, "seed \(seed)")
        }
    }

    @Test func nearbySeedsGiveUnrelatedSequences() {
        // The original seeding gave the same first draw for all of seeds 0..<100.
        var firstDraws = Set<Int>()
        var firstFive = Set<[Int]>()
        for seed in 0 ..< 100 as Range<UInt> {
            var rng = SeededRandomNumberGenerator(seed: seed)
            let draws = (0 ..< 5).map { _ in Int.random(in: 0 ..< 12, using: &rng) }
            firstDraws.insert(draws[0])
            firstFive.insert(draws)
        }
        #expect(firstDraws.count == 12)
        #expect(firstFive.count == 100)
    }

    @Test func seededGeneratorIsDeterministic() {
        var a = SeededRandomNumberGenerator(seed: 7)
        var b = SeededRandomNumberGenerator(seed: 7)
        #expect((0 ..< 5).map { _ in a.next() } == (0 ..< 5).map { _ in b.next() })
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
