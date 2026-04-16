import { Editor, rootCtx, defaultValueCtx } from '@milkdown/core'
import { commonmark } from '@milkdown/preset-commonmark'
import { gfm } from '@milkdown/preset-gfm'
import { history } from '@milkdown/plugin-history'
import { clipboard } from '@milkdown/plugin-clipboard'
import { trailing } from '@milkdown/plugin-trailing'
import { listener, listenerCtx } from '@milkdown/plugin-listener'
import { setupBridge, sendToSwift } from './bridge'
import './styles/editor.css'
import './styles/dark.css'

let editor: Editor | null = null
let isCodeView = false
let currentContent = ''

async function createEditor(content: string) {
  const el = document.getElementById('editor')!
  el.innerHTML = ''

  editor = await Editor.make()
    .config((ctx) => {
      ctx.set(rootCtx, el)
      ctx.set(defaultValueCtx, content)
      ctx.get(listenerCtx).markdownUpdated((_, md) => {
        if (md !== currentContent) {
          currentContent = md
          sendToSwift('contentChanged', md)
          updateWordCount(md)
        }
      })
    })
    .use(commonmark)
    .use(gfm)
    .use(history)
    .use(clipboard)
    .use(trailing)
    .use(listener)
    .create()

  currentContent = content
}

function showCodeView(content: string) {
  const el = document.getElementById('editor')!
  el.innerHTML = `<pre class="code-view"><code>${escapeHtml(content)}</code></pre>`
  isCodeView = true
}

function showWysiwygView(content: string) {
  isCodeView = false
  createEditor(content)
}

function escapeHtml(str: string): string {
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

function updateWordCount(content: string) {
  const words = content.trim().split(/\s+/).filter(Boolean).length
  const readingTime = Math.max(1, Math.ceil(words / 200))
  sendToSwift('wordCount', { words, readingTime })
}

setupBridge({
  onLoadFile: (content) => {
    currentContent = content
    if (isCodeView) {
      showCodeView(content)
    } else {
      createEditor(content)
    }
    updateWordCount(content)
  },
  onSetTheme: (theme) => {
    document.body.className = `theme-${theme}`
  },
  onFocusLine: (line) => {
    const el = document.getElementById('editor')!
    const lineHeight = 24
    el.scrollTop = (line - 1) * lineHeight
  },
  onToggleCodeView: () => {
    if (isCodeView) {
      showWysiwygView(currentContent)
    } else {
      showCodeView(currentContent)
    }
  },
})

sendToSwift('ready', null)
