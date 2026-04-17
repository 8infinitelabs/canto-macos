import * as vscode from 'vscode'
import * as path from 'path'
import * as fs from 'fs'
import { MarkdownEditorProvider } from '../markdownEditorProvider'

export async function createPlan(_context: vscode.ExtensionContext) {
  const root = vscode.workspace.workspaceFolders?.[0]
  if (!root) {
    vscode.window.showWarningMessage('Canto: open a workspace folder first.')
    return
  }

  const name = await vscode.window.showInputBox({
    prompt: 'Plan name (used in filename)',
    placeHolder: 'e.g., migrate-auth-system',
    validateInput: (v) => (v && /^[a-zA-Z0-9_-]+$/.test(v) ? null : 'Use letters, numbers, underscores, dashes only.'),
  })
  if (!name) return

  const goal = await vscode.window.showInputBox({
    prompt: 'Goal — what will this plan accomplish?',
    placeHolder: 'One-line summary',
  })
  if (goal === undefined) return

  // Prefer docs/superpowers/plans/ if it exists
  const supDir = path.join(root.uri.fsPath, 'docs', 'superpowers', 'plans')
  const claudeDir = path.join(root.uri.fsPath, '.claude', 'plans')
  const targetDir = fs.existsSync(supDir) ? supDir : claudeDir
  fs.mkdirSync(targetDir, { recursive: true })

  const now = new Date()
  const dateStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`
  const filename = `${dateStr}-${name}.md`
  const filePath = path.join(targetDir, filename)

  const body = `# ${name}

**Goal:** ${goal}

## Context

## Tasks

- [ ] Task 1
`

  fs.writeFileSync(filePath, body, 'utf8')

  const uri = vscode.Uri.file(filePath)
  await vscode.commands.executeCommand('vscode.openWith', uri, MarkdownEditorProvider.viewType)
  await vscode.commands.executeCommand('canto.refresh')
}
