import Foundation

struct MCPServerConfig: Identifiable, Codable {
    var id: String { name }
    let name: String
    let command: String?
    let args: [String]?
    let url: String?
    let toolCount: Int?
}

struct SkillConfig: Identifiable, Codable {
    var id: String { name }
    let name: String
    let description: String
    let source: String // "built-in", "plugin", "custom"
}

struct PermissionConfig: Identifiable, Codable {
    var id: String { tool + scope }
    let tool: String
    let scope: String // "global", "project"
    let allowed: Bool
}

struct HookConfig: Identifiable, Codable {
    var id: String { event + command }
    let event: String
    let command: String
}
