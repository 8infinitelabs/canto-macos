import Foundation

enum ConfigReader {
    static func readClaudeSettings(globalPath: URL? = nil, projectPath: URL? = nil) -> (
        servers: [MCPServerConfig],
        permissions: [PermissionConfig],
        hooks: [HookConfig]
    ) {
        let globalSettings = globalPath.flatMap { readJSON(at: $0) } ?? [:]
        let projectSettings = projectPath.flatMap { readJSON(at: $0) } ?? [:]

        let mergedJSON: String
        if let data = try? JSONSerialization.data(
            withJSONObject: globalSettings.merging(projectSettings) { _, new in new },
            options: .prettyPrinted
        ), let str = String(data: data, encoding: .utf8) {
            mergedJSON = str
        } else {
            mergedJSON = "{}"
        }

        return (
            servers: parseMCPServers(from: mergedJSON),
            permissions: parsePermissions(from: mergedJSON),
            hooks: parseHooks(from: mergedJSON)
        )
    }

    static func parseMCPServers(from json: String) -> [MCPServerConfig] {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let servers = root["mcpServers"] as? [String: Any]
        else { return [] }

        return servers.map { name, config in
            let cfg = config as? [String: Any] ?? [:]
            return MCPServerConfig(
                name: name,
                command: cfg["command"] as? String,
                args: cfg["args"] as? [String],
                url: cfg["url"] as? String,
                toolCount: nil
            )
        }.sorted { $0.name < $1.name }
    }

    static func parsePermissions(from json: String) -> [PermissionConfig] {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let permissions = root["permissions"] as? [String: Any]
        else { return [] }

        var result: [PermissionConfig] = []
        if let allow = permissions["allow"] as? [String] {
            result += allow.map { PermissionConfig(tool: $0, scope: "project", allowed: true) }
        }
        if let deny = permissions["deny"] as? [String] {
            result += deny.map { PermissionConfig(tool: $0, scope: "project", allowed: false) }
        }
        return result
    }

    static func parseHooks(from json: String) -> [HookConfig] {
        guard let data = json.data(using: .utf8),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let hooks = root["hooks"] as? [String: Any]
        else { return [] }

        return hooks.compactMap { event, config in
            if let cmd = config as? String {
                return HookConfig(event: event, command: cmd)
            }
            if let cfg = config as? [String: Any], let cmd = cfg["command"] as? String {
                return HookConfig(event: event, command: cmd)
            }
            return nil
        }
    }

    private static func readJSON(at url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return json
    }
}
