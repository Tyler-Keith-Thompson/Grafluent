import PackagePlugin

/// Writes `Snippets.swift`, the code-panel text of every `// snippet: name` region in the
/// target's sources, so the text the pages show is the code they compile.
@main
struct Snippets: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) throws -> [Command] {
        guard let target = target as? SourceModuleTarget else { return [] }
        let inputs = target.sourceFiles(withSuffix: "swift").map(\.url).sorted { $0.path < $1.path }
        let output = context.pluginWorkDirectoryURL.appending(path: "Snippets.swift")
        return [
            .buildCommand(
                displayName: "Extracting code-panel snippets",
                executable: try context.tool(named: "SnippetExtractor").url,
                arguments: [output.path] + inputs.map(\.path),
                inputFiles: inputs,
                outputFiles: [output])
        ]
    }
}
