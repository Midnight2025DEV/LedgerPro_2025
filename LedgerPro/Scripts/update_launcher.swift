// In MCPServerLauncher.swift, replace createServerProcess with:

private func createServerProcess(for type: ServerType) throws -> Process {
    // Use the new resolver
    return try createServerProcessWithResolver(for: type)
}
EOF < /dev/null