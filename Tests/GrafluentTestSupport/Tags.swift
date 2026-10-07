import Testing

extension Tag {
    /// Tests that a mutation never affects another copy of the same value.
    @Tag public static var copyOnWrite: Self
    /// Tests run under `.lifetimeChecked`, which fails if any tracked object outlives the test.
    @Tag public static var lifetime: Self
    /// Tests that enumerate every case in a finite space (for example, every directed graph on 3 vertices).
    @Tag public static var exhaustive: Self
    /// Seeded randomized tests; each seed is its own reproducible test case.
    @Tag public static var randomized: Self
    /// Laws required by Swift protocols: Equatable, Hashable, Collection, Codable.
    @Tag public static var conformance: Self
    /// Exit tests asserting that a precondition traps.
    @Tag public static var precondition: Self
    /// Tests over the named fixture graphs with known properties.
    @Tag public static var fixture: Self
    /// Tests about self-loops (edges from a vertex to itself).
    @Tag public static var selfLoops: Self
}
