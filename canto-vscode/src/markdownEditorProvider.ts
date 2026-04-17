import * as vscode from 'vscode'

/**
 * Custom editor for .md files that renders a Vditor WYSIWYG editor
 * in a webview. Two-way sync with the underlying text document.
 */
export class MarkdownEditorProvider implements vscode.CustomTextEditorProvider {
  public static readonly viewType = 'canto.markdownEditor'

  public static register(context: vscode.ExtensionContext): vscode.Disposable {
    const provider = new MarkdownEditorProvider(context)
    return vscode.window.registerCustomEditorProvider(MarkdownEditorProvider.viewType, provider, {
      webviewOptions: {
        retainContextWhenHidden: true,
      },
      supportsMultipleEditorsPerDocument: false,
    })
  }

  constructor(private readonly context: vscode.ExtensionContext) {}

  public async resolveCustomTextEditor(
    document: vscode.TextDocument,
    webviewPanel: vscode.WebviewPanel,
    _token: vscode.CancellationToken
  ): Promise<void> {
    webviewPanel.webview.options = {
      enableScripts: true,
    }

    webviewPanel.webview.html = this.getHtml(webviewPanel.webview)

    // Sync doc → webview
    const updateWebview = () => {
      webviewPanel.webview.postMessage({
        type: 'update',
        text: document.getText(),
      })
    }

    const changeSub = vscode.workspace.onDidChangeTextDocument((e) => {
      if (e.document.uri.toString() === document.uri.toString()) {
        updateWebview()
      }
    })

    webviewPanel.onDidDispose(() => changeSub.dispose())

    // Sync webview → doc
    webviewPanel.webview.onDidReceiveMessage(async (message) => {
      switch (message.type) {
        case 'edit': {
          const edit = new vscode.WorkspaceEdit()
          edit.replace(
            document.uri,
            new vscode.Range(0, 0, document.lineCount, 0),
            message.text
          )
          await vscode.workspace.applyEdit(edit)
          break
        }
        case 'ready':
          updateWebview()
          break
      }
    })
  }

  private getHtml(webview: vscode.Webview): string {
    // Use Vditor from CDN for v0.1. Next version: bundle locally.
    const cspSource = webview.cspSource
    const nonce = getNonce()

    return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta http-equiv="Content-Security-Policy"
        content="default-src 'none';
                 img-src ${cspSource} https: data:;
                 style-src ${cspSource} 'unsafe-inline' https:;
                 script-src 'nonce-${nonce}' https:;
                 font-src ${cspSource} https: data:;
                 connect-src https:;" />
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/vditor@3.10.9/dist/index.css" />
  <style>
    html, body { margin: 0; padding: 0; height: 100%; background: transparent; }
    #vditor {
      height: 100vh;
    }
    .vditor {
      border: none !important;
      border-radius: 0 !important;
    }
    .vditor-toolbar {
      border-bottom: 1px solid var(--vscode-editorGroup-border) !important;
      background: var(--vscode-editor-background) !important;
    }
    .vditor-reset, .vditor-ir, .vditor-wysiwyg, .vditor-sv {
      background: var(--vscode-editor-background) !important;
      color: var(--vscode-editor-foreground) !important;
    }
  </style>
</head>
<body>
  <div id="vditor"></div>
  <script nonce="${nonce}" src="https://cdn.jsdelivr.net/npm/vditor@3.10.9/dist/index.min.js"></script>
  <script nonce="${nonce}">
    const vscode = acquireVsCodeApi();
    let vditor = null;
    let suppressUpdate = false;

    function detectTheme() {
      const body = document.body;
      if (body.classList.contains('vscode-dark') || body.classList.contains('vscode-high-contrast')) {
        return 'dark';
      }
      return 'classic';
    }

    function init(initialText) {
      vditor = new Vditor('vditor', {
        mode: 'wysiwyg',
        height: '100vh',
        theme: detectTheme(),
        preview: {
          theme: { current: detectTheme() === 'dark' ? 'dark' : 'light' },
          hljs: { style: detectTheme() === 'dark' ? 'github-dark' : 'github' },
        },
        cache: { enable: false },
        toolbar: [
          'headings', 'bold', 'italic', 'strike', '|',
          'line', 'quote', 'list', 'ordered-list', 'check', '|',
          'code', 'inline-code', 'link', 'table', '|',
          'undo', 'redo', '|',
          'edit-mode', 'preview', 'outline',
        ],
        input: (value) => {
          if (suppressUpdate) return;
          vscode.postMessage({ type: 'edit', text: value });
        },
        after: () => {
          vditor.setValue(initialText || '');
          vscode.postMessage({ type: 'ready' });
        },
      });
    }

    window.addEventListener('message', (event) => {
      const msg = event.data;
      if (msg.type === 'update') {
        if (!vditor) {
          init(msg.text);
        } else if (vditor.getValue() !== msg.text) {
          suppressUpdate = true;
          vditor.setValue(msg.text);
          suppressUpdate = false;
        }
      }
    });

    // Initial request — tell extension we're ready
    vscode.postMessage({ type: 'ready' });
  </script>
</body>
</html>`
  }
}

function getNonce(): string {
  let text = ''
  const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
  for (let i = 0; i < 32; i++) {
    text += possible.charAt(Math.floor(Math.random() * possible.length))
  }
  return text
}
