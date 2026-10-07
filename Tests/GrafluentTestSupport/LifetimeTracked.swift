// The technique (count live instances, fail the test if any remain) comes from swift-collections'
// LifetimeTracker / LifetimeTracked (Apache-2.0). This is an independent reimplementation for
// Swift Testing: the tracker is task-local rather than global, because Swift Testing runs tests
// in parallel.

import Synchronization
import Testing

/// Counts live `LifetimeTracked` instances created within one test.
public final class LifetimeTracker: Sendable {
    @TaskLocal public static var current: LifetimeTracker?

    private struct State {
        var instances = 0
        var created = 0
    }

    private let state = Mutex(State())

    public init() {}

    /// The number of tracked instances that are currently alive.
    public var instances: Int { state.withLock { $0.instances } }

    /// The total number of tracked instances created so far.
    public var created: Int { state.withLock { $0.created } }

    fileprivate func instanceDidInitialize() -> Int {
        state.withLock {
            $0.instances += 1
            $0.created += 1
            return $0.created
        }
    }

    fileprivate func instanceDidDeinitialize() {
        state.withLock { $0.instances -= 1 }
    }
}

/// A reference-type wrapper whose instances are counted by the current `LifetimeTracker`.
///
/// Equality, hashing and ordering forward to `payload`, so two distinct instances can compare
/// equal. Tests use `===` to check which instance a container kept.
public final class LifetimeTracked<Payload: Sendable>: Sendable {
    public let payload: Payload
    public let serialNumber: Int
    private let tracker: LifetimeTracker

    public init(_ payload: Payload) {
        guard let tracker = LifetimeTracker.current else {
            preconditionFailure("LifetimeTracked must be created inside a test with the .lifetimeChecked trait")
        }
        self.payload = payload
        self.tracker = tracker
        self.serialNumber = tracker.instanceDidInitialize()
    }

    deinit {
        tracker.instanceDidDeinitialize()
    }
}

extension LifetimeTracked: Equatable where Payload: Equatable {
    public static func == (lhs: LifetimeTracked, rhs: LifetimeTracked) -> Bool {
        lhs.payload == rhs.payload
    }
}

extension LifetimeTracked: Hashable where Payload: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(payload)
    }
}

extension LifetimeTracked: Comparable where Payload: Comparable {
    public static func < (lhs: LifetimeTracked, rhs: LifetimeTracked) -> Bool {
        lhs.payload < rhs.payload
    }
}

extension LifetimeTracked: CustomStringConvertible {
    public var description: String { "\(payload)#\(serialNumber)" }
}

/// Runs each test case with a fresh `LifetimeTracker`, and fails the case if any
/// `LifetimeTracked` instance created during it is still alive when it finishes.
public struct LifetimeCheckedTrait: TestTrait, SuiteTrait, TestScoping {
    public var isRecursive: Bool { true }

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        guard testCase != nil else {
            try await function()
            return
        }
        let tracker = LifetimeTracker()
        try await LifetimeTracker.$current.withValue(tracker) {
            try await function()
        }
        #expect(
            tracker.instances == 0,
            "\(tracker.instances) of \(tracker.created) tracked instances outlived the test (leak)"
        )
    }
}

extension Trait where Self == LifetimeCheckedTrait {
    /// Fails the test if any `LifetimeTracked` instance created during it is leaked.
    public static var lifetimeChecked: Self { Self() }
}
