# Hosting Guide for askdocs Flutter App

This guide covers multiple ways to host your Flutter web app from GitHub.

## Prerequisites

- Flutter SDK installed
- Git configured
- GitHub account
- Your repository: `https://github.com/ag597482/askdocs.git`

---

## Option 1: GitHub Pages (Free Static Hosting)

### Step 1: Build Flutter Web App

```bash
# Build the web app for production
flutter build web --release
```

This creates optimized files in the `build/web/` directory.

### Step 2: Configure GitHub Pages

1. **Push your code to GitHub:**
   ```bash
   git add .
   git commit -m "Prepare for deployment"
   git push origin main
   ```

2. **Enable GitHub Pages:**
   - Go to your repository: https://github.com/ag597482/askdocs
   - Click **Settings** → **Pages**
   - Under **Source**, select:
     - **Branch**: `gh-pages` (or `main` if you prefer)
     - **Folder**: `/ (root)` or `/docs` (if you move build files there)
   - Click **Save**

3. **Set up deployment workflow:**
   - Create `.github/workflows/deploy.yml` (see below)

### Step 3: Create GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build web app
        run: flutter build web --release --base-href "/askdocs/"
      
      - name: Setup Pages
        uses: actions/configure-pages@v4
      
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: build/web
      
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

**Note:** Change `--base-href "/askdocs/"` to `"/"` if your repository name is different or you want it at the root.

### Step 4: Update base href in index.html (if needed)

If deploying to a subdirectory, update `web/index.html`:

```html
<base href="/askdocs/">
```

---

## Option 2: Netlify (Recommended for Flutter Web)

### Step 1: Build Configuration

Create `netlify.toml` in the root:

```toml
[build]
  command = "flutter build web --release"
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

### Step 2: Deploy to Netlify

1. **Via Netlify Dashboard:**
   - Go to https://app.netlify.com
   - Click **Add new site** → **Import an existing project**
   - Connect your GitHub repository
   - Netlify will auto-detect the build settings from `netlify.toml`
   - Click **Deploy site**

2. **Via Netlify CLI:**
   ```bash
   npm install -g netlify-cli
   netlify login
   netlify deploy --prod
   ```

### Step 3: Configure Environment Variables (if needed)

If your app needs environment variables:
- Go to **Site settings** → **Environment variables**
- Add any required variables

---

## Option 3: Vercel

### Step 1: Create `vercel.json`

```json
{
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

### Step 2: Deploy

1. Go to https://vercel.com
2. Import your GitHub repository
3. Vercel will use the `vercel.json` configuration
4. Deploy!

---

## Option 4: Firebase Hosting

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Step 2: Initialize Firebase

```bash
firebase init hosting
```

Select:
- **What do you want to use as your public directory?** → `build/web`
- **Configure as a single-page app?** → `Yes`
- **Set up automatic builds and deploys with GitHub?** → `Yes` (optional)

### Step 3: Build and Deploy

```bash
flutter build web --release
firebase deploy
```

---

## Option 5: Railway (Since you're already using it for backend)

### Step 1: Create `railway.json`

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "flutter build web --release"
  },
  "deploy": {
    "startCommand": "npx serve -s build/web -l 3000",
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### Step 2: Deploy

1. Go to https://railway.app
2. Create a new project
3. Connect your GitHub repository
4. Railway will auto-detect and deploy

---

## Current Status & Next Steps

### Your Current Git Status:
- ✅ Repository connected: `https://github.com/ag597482/askdocs.git`
- ⚠️ You have uncommitted changes
- ⚠️ You're 1 commit ahead of origin

### Immediate Actions:

1. **Commit and push your changes:**
   ```bash
   git add .
   git commit -m "Add TTS service and update configurations"
   git push origin main
   ```

2. **Choose a hosting option** from above

3. **For GitHub Pages**, create the workflow file:
   ```bash
   mkdir -p .github/workflows
   # Then create deploy.yml (see Option 1)
   ```

---

## Important Notes

### Base URL Configuration

Your app uses a backend API at `https://rag1-askdocs.up.railway.app`. Make sure:
- CORS is properly configured on your backend
- The API URL is accessible from your hosting domain
- If needed, update `lib/config/api_config.dart` for production URLs

### Environment-Specific Builds

For different environments, you can use:

```bash
# Development
flutter build web --release --dart-define=API_URL=https://rag1-askdocs.up.railway.app

# Production
flutter build web --release --dart-define=API_URL=https://your-prod-api.com
```

Then update `api_config.dart` to read from `String.fromEnvironment('API_URL')`.

---

## Recommended Approach

**For beginners:** Start with **Netlify** (Option 2) - it's the easiest and works great with Flutter web apps.

**For GitHub integration:** Use **GitHub Pages** (Option 1) with the GitHub Actions workflow.

**For existing Railway users:** Use **Railway** (Option 5) to keep everything in one place.

---

## Troubleshooting

### CORS Issues
If you encounter CORS errors, ensure your backend allows requests from your hosting domain.

### Routing Issues
Flutter web apps need proper routing configuration. All hosting options above include redirect rules for single-page app routing.

### Build Failures
Make sure your `pubspec.yaml` dependencies are up to date:
```bash
flutter pub get
flutter pub upgrade
```
