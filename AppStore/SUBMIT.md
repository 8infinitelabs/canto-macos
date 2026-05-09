# Canto — App Store Submission Checklist

Everything you need to submit Canto to the Mac App Store.

## ✅ Assets ready

```
AppStore/
├── listing.md              ← Description, keywords, subtitle, category
├── privacy-policy.md       ← Privacy policy text (also published at canto.infinitelabs.co/privacy)
├── archive.sh              ← Build + archive script
├── exportOptions.plist     ← Export configuration for App Store
├── screenshots/
│   ├── raw/                ← Source captures (2780×1792)
│   └── final/
│       ├── 2880x1800/      ← Retina (5 PNGs)
│       ├── 1440x900/       ← 1x (5 PNGs)
│       └── 1280x800/       ← Smaller (5 PNGs)
└── SUBMIT.md               ← This file
```

## 📝 Final submission steps

### 1. Apple Developer Program ($99/year)

If not already enrolled: https://developer.apple.com/programs/enroll/

### 2. Create app record in App Store Connect

Go to https://appstoreconnect.apple.com → My Apps → "+" → New App.

| Field | Value |
|-------|-------|
| Platform | macOS |
| Name | Canto |
| Primary Language | English (U.S.) |
| Bundle ID | com.infinitelabs.canto (register first in Certificates portal) |
| SKU | canto-macos-1 |
| User Access | Full Access |

### 3. Fill in app information

Copy the relevant fields from `listing.md`:

- **Subtitle:** "Your Claude Code companion"
- **Promotional Text:** Optional, can update without review.
- **Description:** Full description from `listing.md`.
- **Keywords:** `markdown,editor,claude,code,ai,developer,tool,claude-code,preview,wysiwyg,mac,writing,notes,readme,documentation`
- **Support URL:** https://canto.infinitelabs.co
- **Marketing URL:** https://canto.infinitelabs.co
- **Privacy Policy URL:** https://canto.infinitelabs.co/privacy

### 4. Pricing

- **Tier:** USD 9.99 (one-time purchase)
- **No in-app purchases**
- **No subscriptions**

### 5. App Privacy

In the Privacy section, declare: **"Data Not Collected"** for all categories. Canto truly collects nothing.

### 6. App Review Information

- **Sign-in required:** No
- **Demo account:** Not needed
- **Notes for reviewer:**
  > Canto is a native macOS markdown editor designed for Claude Code users. It works with any folder containing markdown files. To test, choose any folder with .md files via "Open Project..." or drag-drop. The app has additional features for folders containing a `.claude/` subdirectory, which is where Claude Code stores project memories and plans.

- **Contact:** diego@infinitelabs.co

### 7. Upload screenshots

Upload the 5 screenshots from `screenshots/final/1440x900/` (or higher Retina sizes). App Store Connect accepts up to 10.

Recommended order:
1. `01_welcome.png` — First impression
2. `02_editor_with_preview.png` — Core feature
3. `03_claude_dashboard.png` — Claude Code integration
4. `04_memory_browser.png` — Memory management
5. `05_clean_editor.png` — Editor with code/lists

### 8. Build & archive

```bash
cd /Users/diego/dev/canto
./AppStore/archive.sh
```

If the script fails on signing, use Xcode UI:
1. Open `Canto.xcodeproj` in Xcode
2. Select scheme "Canto" → Mac
3. Product → Archive
4. Window → Organizer → Distribute App → App Store Connect

Apple's notarization runs automatically as part of App Store distribution.

### 9. Submit for review

Once the build appears in App Store Connect (10-30 min after upload):

1. Go to your app version (1.0)
2. Select the build
3. Submit for Review

Apple usually responds within 24-48 hours. First-time submissions may take longer.

## 🚧 Pre-submit verification

- [ ] App icon appears in Finder (1024×1024 PNG)
- [ ] Privacy Policy live at https://canto.infinitelabs.co/privacy
- [ ] App opens, Welcome screen renders correctly
- [ ] Open a folder with .md files — sidebar populates
- [ ] Open a .md file — editor + preview render
- [ ] ⌘B / ⌘I / ⌘S / ⌘N / ⌘W / ⌘F all work
- [ ] App version matches in About panel and `Info.plist`
- [ ] Sandbox enabled in entitlements
- [ ] Hardened Runtime enabled

## 💰 Tax & banking

Before any sale processes, fill out in App Store Connect → Agreements, Tax, and Banking:
- Paid Apps agreement
- Banking info (Infinite Labs OÜ EU account)
- Tax forms (W-8BEN-E for non-US entities)

## 📦 Update workflow (future versions)

```bash
# Bump version in project.yml (MARKETING_VERSION)
# Bump CURRENT_PROJECT_VERSION (build number)
xcodegen generate --spec project.yml
./AppStore/archive.sh
```

Then create a new version in App Store Connect → submit for review.
