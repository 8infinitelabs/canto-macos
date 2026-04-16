export interface CantoMessage {
  type: 'loadFile' | 'setTheme' | 'focusLine' | 'getContent' | 'toggleCodeView'
  payload?: any
}

export function sendToSwift(type: string, data: any) {
  ;(window as any).webkit?.messageHandlers?.canto?.postMessage({
    type,
    data,
  })
}

export function setupBridge(callbacks: {
  onLoadFile: (content: string) => void
  onSetTheme: (theme: 'dark' | 'light') => void
  onFocusLine: (line: number) => void
  onToggleCodeView: () => void
}) {
  ;(window as any).cantoReceive = (message: CantoMessage) => {
    switch (message.type) {
      case 'loadFile':
        callbacks.onLoadFile(message.payload)
        break
      case 'setTheme':
        callbacks.onSetTheme(message.payload)
        break
      case 'focusLine':
        callbacks.onFocusLine(message.payload)
        break
      case 'toggleCodeView':
        callbacks.onToggleCodeView()
        break
    }
  }
}
