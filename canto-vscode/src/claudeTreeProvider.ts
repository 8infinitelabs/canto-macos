import * as vscode from 'vscode'
import * as path from 'path'
import * as fs from 'fs'
import { MarkdownEditorProvider } from './markdownEditorProvider'

type NodeKind = 'claudeMd' | 'memoryRoot' | 'memory' | 'plansRoot' | 'plan' | 'config' | 'empty'

export class ClaudeNode extends vscode.TreeItem {
  constructor(
    public readonly kind: NodeKind,
    public readonly label: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly resourceUri?: vscode.Uri,
    public readonly description?: string
  ) {
    super(label, collapsibleState)
    this.description = description

    switch (kind) {
      case 'claudeMd':
        this.iconPath = new vscode.ThemeIcon('file-text', new vscode.ThemeColor('charts.orange'))
        this.command = {
          command: 'vscode.openWith',
          title: 'Open',
          arguments: [resourceUri, MarkdownEditorProvider.viewType],
        }
        break
      case 'memoryRoot':
        this.iconPath = new vscode.ThemeIcon('symbol-namespace')
        break
      case 'memory':
        this.iconPath = new vscode.ThemeIcon('note')
        if (resourceUri) {
          this.command = {
            command: 'vscode.openWith',
            title: 'Open memory',
            arguments: [resourceUri, MarkdownEditorProvider.viewType],
          }
        }
        break
      case 'plansRoot':
        this.iconPath = new vscode.ThemeIcon('list-ordered')
        break
      case 'plan':
        this.iconPath = new vscode.ThemeIcon('list-tree')
        if (resourceUri) {
          this.command = {
            command: 'vscode.openWith',
            title: 'Open plan',
            arguments: [resourceUri, MarkdownEditorProvider.viewType],
          }
        }
        break
      case 'config':
        this.iconPath = new vscode.ThemeIcon('gear')
        break
      case 'empty':
        this.iconPath = new vscode.ThemeIcon('info')
        break
    }
  }
}

export class ClaudeTreeProvider implements vscode.TreeDataProvider<ClaudeNode> {
  private _onDidChangeTreeData = new vscode.EventEmitter<ClaudeNode | undefined | void>()
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event

  refresh(): void {
    this._onDidChangeTreeData.fire()
  }

  getTreeItem(element: ClaudeNode): vscode.TreeItem {
    return element
  }

  async getChildren(element?: ClaudeNode): Promise<ClaudeNode[]> {
    const root = vscode.workspace.workspaceFolders?.[0]
    if (!root) return []

    if (!element) {
      // Top-level nodes
      const nodes: ClaudeNode[] = []

      const claudeMdPath = path.join(root.uri.fsPath, 'CLAUDE.md')
      if (fs.existsSync(claudeMdPath)) {
        nodes.push(
          new ClaudeNode(
            'claudeMd',
            'CLAUDE.md',
            vscode.TreeItemCollapsibleState.None,
            vscode.Uri.file(claudeMdPath)
          )
        )
      }

      const memories = this.findMemories(root.uri.fsPath)
      nodes.push(
        new ClaudeNode(
          'memoryRoot',
          'Memory',
          memories.length > 0
            ? vscode.TreeItemCollapsibleState.Collapsed
            : vscode.TreeItemCollapsibleState.None,
          undefined,
          String(memories.length)
        )
      )

      const plans = this.findPlans(root.uri.fsPath)
      nodes.push(
        new ClaudeNode(
          'plansRoot',
          'Plans',
          plans.length > 0
            ? vscode.TreeItemCollapsibleState.Collapsed
            : vscode.TreeItemCollapsibleState.None,
          undefined,
          String(plans.length)
        )
      )

      nodes.push(
        new ClaudeNode('config', 'Config', vscode.TreeItemCollapsibleState.None)
      )

      return nodes
    }

    if (element.kind === 'memoryRoot') {
      return this.findMemories(root.uri.fsPath).map(
        (m) =>
          new ClaudeNode(
            'memory',
            path.basename(m, '.md'),
            vscode.TreeItemCollapsibleState.None,
            vscode.Uri.file(m)
          )
      )
    }

    if (element.kind === 'plansRoot') {
      return this.findPlans(root.uri.fsPath).map(
        (p) =>
          new ClaudeNode(
            'plan',
            path.basename(p, '.md'),
            vscode.TreeItemCollapsibleState.None,
            vscode.Uri.file(p)
          )
      )
    }

    return []
  }

  private findMemories(rootPath: string): string[] {
    const memoryDir = path.join(rootPath, '.claude', 'memory')
    if (!fs.existsSync(memoryDir)) return []
    return fs
      .readdirSync(memoryDir)
      .filter((f) => f.endsWith('.md'))
      .map((f) => path.join(memoryDir, f))
      .sort()
  }

  private findPlans(rootPath: string): string[] {
    const candidates = [
      path.join(rootPath, 'docs', 'superpowers', 'plans'),
      path.join(rootPath, '.claude', 'plans'),
    ]
    const plans: string[] = []
    for (const dir of candidates) {
      if (!fs.existsSync(dir)) continue
      for (const f of fs.readdirSync(dir)) {
        if (f.endsWith('.md')) plans.push(path.join(dir, f))
      }
    }
    return plans.sort()
  }
}
