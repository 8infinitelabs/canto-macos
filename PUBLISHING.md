# Publishing Canto to the VS Code Marketplace

Full step-by-step to publish the Canto extension under the **basicstech** publisher, with auto-publish on tag push from GitHub.

---

## One-time setup

### 1. Create the Azure DevOps organization (if you don't have one)

The VS Code Marketplace uses Azure DevOps for authentication.

1. Go to https://dev.azure.com
2. Sign in with a Microsoft account (use `hello@basicstech.org` or a dedicated account)
3. Create a new organization if prompted — name doesn't matter for publishing purposes

### 2. Generate a Personal Access Token (PAT)

1. In Azure DevOps, click your profile icon (top-right) → **User settings** → **Personal access tokens**
2. Click **+ New Token**
3. Fill in:
   - **Name:** `canto-marketplace-publish`
   - **Organization:** select `All accessible organizations` (this is critical — without it vsce fails)
   - **Expiration:** custom, 1 year (set a reminder to rotate)
   - **Scopes:** click **Show all scopes** at the bottom, then scroll to **Marketplace** and check **Manage**
4. Click **Create** and **copy the token immediately** (you can't see it again)

### 3. Create the publisher on the Marketplace

1. Go to https://marketplace.visualstudio.com/manage/publishers/
2. Sign in with the same Microsoft account from step 1
3. Click **+ New publisher**
4. Fill in:
   - **Publisher ID:** `basicstech` (this is permanent and must match `package.json`)
   - **Display name:** `BasicsTech`
   - **Email:** `hello@basicstech.org`
   - **Website:** `https://basicstech.org`
   - **Description:** one-line description of BasicsTech
5. Click **Create**

### 4. Verify publisher on your machine (one-time)

```sh
cd canto-vscode
npx @vscode/vsce login basicstech
# Paste the PAT from step 2 when prompted
```

### 5. Push the repo to GitHub

```sh
cd /Users/diego/dev/canto
git remote add origin git@github.com:basicstech/canto.git
git push -u origin main
```

### 6. Add the PAT to GitHub Secrets

1. Go to https://github.com/basicstech/canto/settings/secrets/actions
2. Click **New repository secret**
3. **Name:** `VSCE_PAT`
4. **Value:** paste the PAT from step 2
5. Click **Add secret**

---

## Publishing a release

### Option A: Automatic (recommended)

Bump the version, tag, push. GitHub Actions handles the rest.

```sh
cd canto-vscode
npm version patch          # 0.1.0 → 0.1.1 (or use minor/major)
git add package.json package-lock.json
git commit -m "release: vscode v0.1.1"
git tag vscode-v0.1.1
git push && git push --tags
```

The workflow at `.github/workflows/publish-extension.yml`:

1. Compiles TypeScript
2. Packages the `.vsix`
3. Publishes to Marketplace with `VSCE_PAT`
4. Creates a GitHub Release with the `.vsix` attached

Check progress at https://github.com/basicstech/canto/actions.

### Option B: Manual from your machine

```sh
cd canto-vscode
npm run compile
npx @vscode/vsce publish
# uses the PAT you saved with `vsce login`
```

---

## Landing page at canto.basicstech.org

The landing is at `/docs/index.html` with a `CNAME` file pointing to `canto.basicstech.org`.

### One-time setup

1. **Enable GitHub Pages:**
   - Go to https://github.com/basicstech/canto/settings/pages
   - Source: **Deploy from a branch**
   - Branch: **main** / folder: **/docs**
   - Click **Save**

2. **DNS:** at your DNS provider for `basicstech.org`, add a CNAME record:
   ```
   canto    CNAME    basicstech.github.io
   ```
   (TTL 3600 is fine)

3. **Wait ~5–15 minutes** for DNS to propagate and GitHub to provision the HTTPS cert.

4. **Verify:**
   - In Settings → Pages, the custom domain field should show `canto.basicstech.org` as verified
   - Check "Enforce HTTPS" once the cert is ready

The page updates automatically on every push to `main` that touches `/docs`.

---

## Testing the extension before publishing

### Install from a local `.vsix`

```sh
cd canto-vscode
npm run compile
npx @vscode/vsce package --no-dependencies
code --install-extension canto-0.1.0.vsix
```

### Develop in Extension Host

1. Open `canto-vscode/` in VS Code
2. Run `npm run watch` in a terminal
3. Press **F5** — a new VS Code window opens with Canto loaded
4. Changes to `src/*.ts` are recompiled; reload the Extension Host window to pick them up (`⌘R` in it)

---

## Unpublishing / delisting

If something goes wrong:

```sh
# Remove a specific version
npx @vscode/vsce unpublish basicstech.canto 0.1.0

# Fully delist the extension
npx @vscode/vsce unpublish basicstech.canto
```

You can also manage the extension at https://marketplace.visualstudio.com/manage/publishers/basicstech.

---

## Troubleshooting

**"ERROR: 401 unauthorized"** — The PAT is wrong, expired, or doesn't have Marketplace → Manage scope on all orgs.

**"ERROR: Extension is already published at version X.Y.Z"** — Bump the version in `package.json` before publishing. Use `npm version patch`.

**"Icon not displayed on Marketplace"** — Icon must be at least 128×128 PNG. We ship 128×128 at `media/icon.png`.

**Landing shows 404** — GitHub Pages takes a few minutes after first setup. Also check that the `docs/` folder is selected as source, not the root.

**Custom domain shows "improperly configured"** — Double-check the CNAME record points to `basicstech.github.io` (no trailing dot needed, though some DNS uis add one).
