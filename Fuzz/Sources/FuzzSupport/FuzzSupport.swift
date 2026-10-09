#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// The fuzzer's bytes, read as a sequence of small choices. Past the end every read is 0, so any
/// input decodes, and libFuzzer's mutations (flip, insert, erase a byte) change one choice.
public struct FuzzInput {
    @usableFromInline let bytes: UnsafeBufferPointer<UInt8>
    @usableFromInline var position = 0

    init(_ bytes: UnsafeBufferPointer<UInt8>) { self.bytes = bytes }

    /// Whether every byte has been read.
    public var isEmpty: Bool { position >= bytes.count }

    /// The next byte.
    @inlinable
    public mutating func byte() -> Int {
        guard position < bytes.count else { return 0 }
        defer { position += 1 }
        return Int(bytes[position])
    }

    /// A choice in `0..<bound`.
    @inlinable
    public mutating func int(below bound: Int) -> Int { byte() % bound }

    /// A choice in `range`, which spans at most 256 values.
    @inlinable
    public mutating func int(in range: ClosedRange<Int>) -> Int { range.lowerBound + byte() % range.count }
}

/// Stops the run with `message` when `condition` is false. libFuzzer catches the abort and saves
/// the input as a crash file.
@inlinable
public func check(_ condition: Bool, _ message: @autoclosure () -> String, file: StaticString = #fileID, line: UInt = #line) {
    if !condition { fail(message(), file: file, line: line) }
}

@usableFromInline
func fail(_ message: String, file: StaticString, line: UInt) -> Never {
    var report = "\(file):\(line): check failed: \(message)\n"
    report.withUTF8 { _ = write(2, $0.baseAddress, $0.count) }
    abort()
}

@_silgen_name("LLVMFuzzerRunDriver")
func LLVMFuzzerRunDriver(
    _ argc: UnsafeMutablePointer<CInt>,
    _ argv: UnsafeMutablePointer<UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>>,
    _ callback: @convention(c) (UnsafePointer<UInt8>?, Int) -> CInt
) -> CInt

nonisolated(unsafe) var testOneInput: ((inout FuzzInput) -> Void)?

/// Runs libFuzzer with `body` as the test of one input, passing the command line through.
///
/// libFuzzer normally supplies `main` and calls `LLVMFuzzerTestOneInput`. SwiftPM links every
/// executable against its own entry point instead, so each target has an `@main` that calls this,
/// and libFuzzer's driver is started explicitly.
public func runFuzzer(_ body: @escaping (inout FuzzInput) -> Void) -> Never {
    testOneInput = body
    var argc = CommandLine.argc
    var argv = CommandLine.unsafeArgv
    exit(LLVMFuzzerRunDriver(&argc, &argv) { data, size in
        var input = FuzzInput(UnsafeBufferPointer(start: data, count: size))
        testOneInput!(&input)
        return 0
    })
}
