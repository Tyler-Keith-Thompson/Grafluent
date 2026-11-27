import GrafluentTestSupport
import Testing

@Suite("Exit tests")
struct ExitTestSupportTests {
    /// Confirms exit tests work under both SwiftPM and Bazel before any suite depends on them.
    @Test(.tags(.precondition))
    func exitTestsAreSupported() async {
        await #expect(processExitsWith: .failure) {
            preconditionFailure("intentional")
        }
    }
}
