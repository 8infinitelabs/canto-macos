import XCTest
@testable import Canto

final class ConfigReaderTests: XCTestCase {
    func testParseMCPServers() throws {
        let json = """
        {
          "mcpServers": {
            "supabase": {
              "command": "npx",
              "args": ["-y", "@supabase/mcp-server"]
            },
            "context7": {
              "command": "npx",
              "args": ["@context7/mcp"]
            }
          }
        }
        """
        let servers = ConfigReader.parseMCPServers(from: json)
        XCTAssertEqual(servers.count, 2)
        XCTAssertEqual(servers[0].name, "context7")
    }

    func testParsePermissions() throws {
        let json = """
        {
          "permissions": {
            "allow": ["Bash(npm *)", "Edit"],
            "deny": ["Bash(rm *)"]
          }
        }
        """
        let permissions = ConfigReader.parsePermissions(from: json)
        XCTAssertEqual(permissions.filter { $0.allowed }.count, 2)
        XCTAssertEqual(permissions.filter { !$0.allowed }.count, 1)
    }
}
