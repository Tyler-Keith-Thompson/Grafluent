#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#endif

/// The number of tasks a parallel measure runs when `parallelism` is nil: the processors online,
/// at least 1; 1 on WebAssembly, which has one thread.
@inlinable
public var defaultParallelism: Int {
    #if os(WASI)
    return 1
    #else
    return Swift.max(1, Int(sysconf(Int32(_SC_NPROCESSORS_ONLN))))
    #endif
}

/// The task count for `parallelism` over `n` sources: `parallelism`, or the default when nil,
/// never more than `n` and at least 1.
///
/// - Precondition: `parallelism`, when given, is greater than zero.
@inlinable
func _taskCount(_ parallelism: Int?, sources n: Int) -> Int {
    let requested = parallelism ?? defaultParallelism
    precondition(requested > 0, "parallelism must be greater than zero")
    return Swift.max(1, Swift.min(requested, n))
}

/// Runs `body` on each of `tasks` interleaved shares of `0 ..< n` (share k takes the sources
/// k, k + tasks, k + 2·tasks, …, so every share has about the same work on a graph whose rows
/// vary along the index), and sums the per-vertex results. The shares are added in share order,
/// so the same input gives the same sum.
@inlinable
func _sumOverShares(count n: Int, tasks: Int, _ body: @Sendable @escaping ([Int]) -> [Double]) async -> [Double] {
    if tasks == 1 { return body(Array(0 ..< n)) }
    return await withTaskGroup(of: (Int, [Double]).self) { group in
        for k in 0 ..< tasks {
            group.addTask { (k, body(Array(stride(from: k, to: n, by: tasks)))) }
        }
        var parts = [[Double]?](repeating: nil, count: tasks)
        for await (k, part) in group { parts[k] = part }
        var total = [Double](repeating: 0, count: n)
        for part in parts {
            let part = part.unsafelyUnwrapped
            for v in 0 ..< n { total[v] += part[v] }
        }
        return total
    }
}

/// Runs `body` on each of `tasks` interleaved shares of `0 ..< n`, each returning the scores of
/// its share's sources in share order, and gathers them by source.
@inlinable
func _gatherOverShares(count n: Int, tasks: Int, _ body: @Sendable @escaping ([Int]) -> [Double]) async -> [Double] {
    if tasks == 1 { return body(Array(0 ..< n)) }
    return await withTaskGroup(of: (Int, [Double]).self) { group in
        for k in 0 ..< tasks {
            group.addTask { (k, body(Array(stride(from: k, to: n, by: tasks)))) }
        }
        var scores = [Double](repeating: 0, count: n)
        for await (k, part) in group {
            var source = k
            for value in part {
                scores[source] = value
                source += tasks
            }
        }
        return scores
    }
}
