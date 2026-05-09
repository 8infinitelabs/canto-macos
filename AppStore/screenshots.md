# Canto — App Store Screenshots

## Required sizes (macOS)
App Store Connect requires screenshots in these resolutions:
- 1280 × 800 (required)
- 1440 × 900 (required)
- 2560 × 1600 (recommended for Retina)
- 2880 × 1800 (recommended for Retina)

Up to 10 screenshots total (any mix of sizes).

## Recommended shots (5 screenshots)

### 1. Editor + Preview Split
Show the live split view with a markdown file open. Edit on left, rendered preview on right.
- File: something meaningful like CLAUDE.md or a project README
- Format toolbar visible at top
- Bold, italic, headings, lists, tables rendered in preview

### 2. Claude Project Sidebar
Show the full window with sidebar visible:
- Activity indicator (purple dot)
- CLAUDE.md section expanded
- Memory section with type badges
- File tree with markdown files

### 3. Memory Browser
Show the Memory Browser view with memory cards:
- Filter by type (user/feedback/project/reference)
- Search bar
- Memory cards with type badges, descriptions
- "New Memory" button

### 4. Welcome Screen
Show the initial welcome/landing screen:
- App icon
- "Your Claude Code companion for Mac" tagline
- "Open Project" button
- Drop zone
- Recent projects list
- Version number

### 5. Tables + Code Blocks
Open a markdown file with:
- Tables (with headers, alternating rows, borders)
- Fenced code blocks (with syntax)
- Blockquotes
- Bullet and numbered lists

## How to capture

1. **Build and launch the release app:**
   ```bash
   xcodebuild -project Canto.xcodeproj -scheme Canto -configuration Release build
   open ~/Library/Developer/Xcode/DerivedData/Canto-*/Build/Products/Release/Canto.app
   ```

2. **Resize window** to desired resolution:
   - Use `⌘⇧4` then `Space` to capture a single window (includes shadow)
   - Or use the Screenshot app (`⌘⇧5`) for precise sizing

3. **Prepare sample content:**
   Create a test folder with good-looking markdown files that showcase all features.
   A CLAUDE.md file with sections, memories, and tables works best.

4. **Use a clean desktop** or neutral background when capturing with shadow.

## Using sips to resize
If you capture at Retina, resize down to required sizes:
```bash
sips -z 900 1440 screenshot.png --out screenshot_1440x900.png
sips -z 800 1280 screenshot.png --out screenshot_1280x800.png
```
