// Cycle detection over a successor closure, in O(1) memory: the orbit x0, f(x0), f(f(x0)), … of an
// eventually periodic f, as Rust's `pathfinding` crate offers (`cycle_detection::{floyd, brent}`).

/// The tail and cycle of the orbit of `start` under `successor`, by Floyd's algorithm (Knuth,
/// *The Art of Computer Programming*, vol. 2, §3.1, exercise 6): a tortoise and a hare at twice its
/// speed meet on the cycle; a second pass from `start` finds the first cyclic vertex, and a third
/// lap measures the cycle. O(μ + λ) time, O(1) memory, and states need only be `Equatable`.
///
/// Returns `tailLength`, the number of steps from `start` to the first vertex on the cycle (μ,
/// Sage's "preperiod"), `cycleLength` (λ), and that first cyclic vertex, `root`. The closure is
/// called exactly 3ν + 2μ + λ times, where ν is the least multiple of λ that is at least
/// max(μ, 1). `brentCycleDetection(from:successor:)` calls it less often.
///
/// - Precondition: the orbit of `start` is eventually periodic (always so on a finite state
///   space). On an infinite orbit the function does not return.
@inlinable
public func floydCycleDetection<Vertex: Equatable>(
    from start: Vertex, successor f: (Vertex) -> Vertex
) -> (tailLength: Int, cycleLength: Int, root: Vertex) {
    var tortoise = f(start)
    var hare = f(f(start))
    while tortoise != hare {
        tortoise = f(tortoise)
        hare = f(f(hare))
    }
    var tailLength = 0
    tortoise = start
    while tortoise != hare {
        tortoise = f(tortoise)
        hare = f(hare)
        tailLength += 1
    }
    var cycleLength = 1
    hare = f(tortoise)
    while tortoise != hare {
        hare = f(hare)
        cycleLength += 1
    }
    return (tailLength, cycleLength, tortoise)
}

/// The tail and cycle of the orbit of `start` under `successor`, by Brent's algorithm (R. P.
/// Brent, "An improved Monte Carlo factorization algorithm", BIT 20 (1980) 176–184): the tortoise
/// teleports to the hare at each power of two, which measures the cycle length directly; a second
/// pass with the hare λ steps ahead finds the first cyclic vertex. O(μ + λ) time, O(1) memory, and
/// states need only be `Equatable`.
///
/// Returns the same as `floydCycleDetection(from:successor:)`, with fewer closure calls on every
/// orbit the catalog lists (351 against Floyd's 554 for Collatz from 27).
///
/// - Precondition: the orbit of `start` is eventually periodic. On an infinite orbit the function
///   does not return.
@inlinable
public func brentCycleDetection<Vertex: Equatable>(
    from start: Vertex, successor f: (Vertex) -> Vertex
) -> (tailLength: Int, cycleLength: Int, root: Vertex) {
    var power = 1
    var cycleLength = 1
    var tortoise = start
    var hare = f(start)
    while tortoise != hare {
        if power == cycleLength {
            tortoise = hare
            power *= 2
            cycleLength = 0
        }
        hare = f(hare)
        cycleLength += 1
    }
    tortoise = start
    hare = start
    for _ in 0 ..< cycleLength { hare = f(hare) }
    var tailLength = 0
    while tortoise != hare {
        tortoise = f(tortoise)
        hare = f(hare)
        tailLength += 1
    }
    return (tailLength, cycleLength, tortoise)
}
