// Slash menu configuration for Milkdown
// Will be expanded with custom commands in future versions
export function createSlashMenu() {
  return {
    items: [
      { label: 'Heading 1', command: 'heading1' },
      { label: 'Heading 2', command: 'heading2' },
      { label: 'Heading 3', command: 'heading3' },
      { label: 'Bullet List', command: 'bulletList' },
      { label: 'Ordered List', command: 'orderedList' },
      { label: 'Code Block', command: 'codeBlock' },
      { label: 'Blockquote', command: 'blockquote' },
      { label: 'Horizontal Rule', command: 'hr' },
      { label: 'Table', command: 'table' },
    ],
  }
}
