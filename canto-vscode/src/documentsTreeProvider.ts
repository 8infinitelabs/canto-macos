import * as vscode from 'vscode'
import * as path from 'path'
import * as fs from 'fs'
import { MarkdownEditorProvider } from './markdownEditorProvider'

const SKIP_DIRS = new Set([
  'node_modules',
  '.git',
  'DerivedData',
  'build',
  '.build',
  'dist',
  'out',
  '__pycache__',
  '.next',
  '.claude',
  '.vscode',
])

type DocKind = 'file' | 'folder'

export class DocNode extends vscode.TreeItem {
  constructor(
    public readonly kind: DocKind,
    public readonly label: string,
    public readonly resourceUri: vscode.Uri,
    collapsibleState: vscode.TreeItemCollapsibleState,
    description?: string
  ) {
    super(label, collapsibleState)
    this.description = description
    this.resourceUri = resourceUri

    if (kind === 'file') {
      this.iconPath = new vscode.ThemeIcon('markdown')
      this.command = {
        command: 'vscode.openWith',
        title: 'Open',
        arguments: [resourceUri, MarkdownEditorProvider.viewType],
      }
    } else {
      this.iconPath = new vscode.ThemeIcon('folder')
    }
  }
}

export class DocumentsTreeProvider implements vscode.TreeDataProvider<DocNode> {
  private _onDidChangeTreeData = new vscode.EventEmitter<DocNode | undefined | void>()
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event

  refresh(): void {
    this._onDidChangeTreeData.fire()
  }

  getTreeItem(element: DocNode): vscode.TreeItem {
    return element
  }

  async getChildren(element?: DocNode): Promise<DocNode[]> {
    const root = vscode.workspace.workspaceFolders?.[0]
    if (!root) return []

    const dir = element ? element.resourceUri.fsPath : root.uri.fsPath
    const children = this.readMarkdownChildren(dir)

    // Exclude CLAUDE.md (handled in Claude view) at the root level
    if (!element) {
      return children.filter((n) => n.label !== 'CLAUDE.md')
    }
    return children
  }

  private readMarkdownChildren(dir: string): DocNode[] {
    let entries: fs.Dirent[]
    try {
      entries = fs.readdirSync(dir, { withFileTypes: true })
    } catch {
      return []
    }

    const files: DocNode[] = []
    const folders: DocNode[] = []

    for (const entry of entries) {
      if (entry.name.startsWith('.')) continue
      if (SKIP_DIRS.has(entry.name)) continue

      const fullPath = path.join(dir, entry.name)

      if (entry.isDirectory()) {
        if (containsMarkdown(fullPath)) {
          const count = countMarkdown(fullPath)
          folders.push(
            new DocNode(
              'folder',
              entry.name,
              vscode.Uri.file(fullPath),
              vscode.TreeItemCollapsibleState.Collapsed,
              String(count)
            )
          )
        }
      } else if (entry.name.endsWith('.md')) {
        files.push(
          new DocNode(
            'file',
            entry.name,
            vscode.Uri.file(fullPath),
            vscode.TreeItemCollapsibleState.None
          )
        )
      }
    }

    // Files first, then folders, each sorted alphabetically
    files.sort((a, b) => a.label.toString().localeCompare(b.label.toString()))
    folders.sort((a, b) => a.label.toString().localeCompare(b.label.toString()))
    return [...files, ...folders]
  }
}

function containsMarkdown(dir: string): boolean {
  let entries: fs.Dirent[]
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true })
  } catch {
    return false
  }
  for (const entry of entries) {
    if (SKIP_DIRS.has(entry.name) || entry.name.startsWith('.')) continue
    const fullPath = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      if (containsMarkdown(fullPath)) return true
    } else if (entry.name.endsWith('.md')) {
      return true
    }
  }
  return false
}

function countMarkdown(dir: string): number {
  let entries: fs.Dirent[]
  try {
    entries = fs.readdirSync(dir, { withFileTypes: true })
  } catch {
    return 0
  }
  let count = 0
  for (const entry of entries) {
    if (SKIP_DIRS.has(entry.name) || entry.name.startsWith('.')) continue
    const fullPath = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      count += countMarkdown(fullPath)
    } else if (entry.name.endsWith('.md')) {
      count += 1
    }
  }
  return count
}
