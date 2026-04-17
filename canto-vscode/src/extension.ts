import * as vscode from 'vscode'
import { ClaudeTreeProvider } from './claudeTreeProvider'
import { DocumentsTreeProvider } from './documentsTreeProvider'
import { MarkdownEditorProvider } from './markdownEditorProvider'
import { createMemory } from './commands/newMemory'
import { createPlan } from './commands/newPlan'

export function activate(context: vscode.ExtensionContext) {
  const claudeTree = new ClaudeTreeProvider()
  const documentsTree = new DocumentsTreeProvider()

  context.subscriptions.push(
    vscode.window.registerTreeDataProvider('canto.claude', claudeTree),
    vscode.window.registerTreeDataProvider('canto.documents', documentsTree)
  )

  // Register the WYSIWYG custom editor for .md files
  context.subscriptions.push(MarkdownEditorProvider.register(context))

  context.subscriptions.push(
    vscode.commands.registerCommand('canto.openEditor', async (uri?: vscode.Uri) => {
      const target = uri ?? vscode.window.activeTextEditor?.document.uri
      if (!target) {
        vscode.window.showWarningMessage('Canto: no markdown file selected.')
        return
      }
      await vscode.commands.executeCommand('vscode.openWith', target, MarkdownEditorProvider.viewType)
    }),

    vscode.commands.registerCommand('canto.openClaudeMd', async () => {
      const root = vscode.workspace.workspaceFolders?.[0]
      if (!root) return
      const uri = vscode.Uri.joinPath(root.uri, 'CLAUDE.md')
      await vscode.commands.executeCommand('vscode.openWith', uri, MarkdownEditorProvider.viewType)
    }),

    vscode.commands.registerCommand('canto.newMemory', () => createMemory(context)),
    vscode.commands.registerCommand('canto.newPlan', () => createPlan(context)),

    vscode.commands.registerCommand('canto.refresh', () => {
      claudeTree.refresh()
      documentsTree.refresh()
    })
  )

  // Watch for file changes to refresh tree views
  const watcher = vscode.workspace.createFileSystemWatcher('**/{CLAUDE.md,.claude/**,*.md}')
  context.subscriptions.push(
    watcher,
    watcher.onDidCreate(() => {
      claudeTree.refresh()
      documentsTree.refresh()
    }),
    watcher.onDidDelete(() => {
      claudeTree.refresh()
      documentsTree.refresh()
    })
  )
}

export function deactivate() {}
