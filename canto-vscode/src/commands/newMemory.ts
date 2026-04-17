import * as vscode from 'vscode'
import * as path from 'path'
import * as fs from 'fs'
import { MarkdownEditorProvider } from '../markdownEditorProvider'

const MEMORY_TYPES = ['user', 'feedback', 'project', 'reference'] as const

export async function createMemory(_context: vscode.ExtensionContext) {
  const root = vscode.workspace.workspaceFolders?.[0]
  if (!root) {
    vscode.window.showWarningMessage('Canto: open a workspace folder first.')
    return
  }

  const name = await vscode.window.showInputBox({
    prompt: 'Memory name (will become filename)',
    placeHolder: 'e.g., user_preferences',
    validateInput: (v) => (v && /^[a-zA-Z0-9_-]+$/.test(v) ? null : 'Use letters, numbers, underscores, dashes only.'),
  })
  if (!name) return

  const description = await vscode.window.showInputBox({
    prompt: 'One-line description',
    placeHolder: 'What is this memory about?',
  })
  if (description === undefined) return

  const type = await vscode.window.showQuickPick([...MEMORY_TYPES], {
    title: 'Memory type',
    placeHolder: 'Select memory type',
  })
  if (!type) return

  const memoryDir = path.join(root.uri.fsPath, '.claude', 'memory')
  fs.mkdirSync(memoryDir, { recursive: true })

  const filename = `${name}.md`
  const filePath = path.join(memoryDir, filename)

  if (fs.existsSync(filePath)) {
    const overwrite = await vscode.window.showWarningMessage(
      `${filename} already exists. Overwrite?`,
      'Overwrite',
      'Cancel'
    )
    if (overwrite !== 'Overwrite') return
  }

  const body = `---
name: ${name}
description: ${description}
type: ${type}
---

`

  fs.writeFileSync(filePath, body, 'utf8')

  const uri = vscode.Uri.file(filePath)
  await vscode.commands.executeCommand('vscode.openWith', uri, MarkdownEditorProvider.viewType)
  await vscode.commands.executeCommand('canto.refresh')
}
