# Fix GitHub Pages Deployment

Your site at https://ag597482.github.io/askdocs/ is currently showing the README instead of your Flutter app. Here's how to fix it:

## The Problem

GitHub Pages is currently serving from your repository files (README.md) instead of the built Flutter web app from GitHub Actions.

## Solution: Configure GitHub Pages to Use GitHub Actions

### Step 1: Update GitHub Pages Settings

1. Go to your repository: https://github.com/ag597482/askdocs
2. Click **Settings** (top menu)
3. Scroll down to **Pages** (left sidebar)
4. Under **Source**, change it to:
   - **Source**: Select **"GitHub Actions"** (NOT "Deploy from a branch")
5. Click **Save**

### Step 2: Commit and Push the Updated Workflow

The workflow file has been updated. Now commit and push it:

```bash
git add .github/workflows/deploy.yml
git commit -m "Fix GitHub Pages deployment workflow"
git push origin main
```

### Step 3: Trigger the Workflow

After pushing, the workflow will automatically run. You can also manually trigger it:

1. Go to **Actions** tab in your repository
2. Click on **"Deploy to GitHub Pages"** workflow
3. Click **"Run workflow"** → **"Run workflow"**

### Step 4: Wait for Deployment

- The workflow will take 2-5 minutes to complete
- You can watch the progress in the **Actions** tab
- Once complete, your Flutter app will be live at: https://ag597482.github.io/askdocs/

## Verify It's Working

After the workflow completes:
1. Visit https://ag597482.github.io/askdocs/
2. You should see your Flutter app (not the README)
3. The app should load and be functional

## Troubleshooting

### If the workflow fails:
- Check the **Actions** tab for error messages
- Common issues:
  - Flutter version compatibility (fixed in updated workflow)
  - Missing dependencies (should be handled by `flutter pub get`)
  - Build errors (check Flutter build locally first)

### If the site still shows README:
- Make sure GitHub Pages source is set to **"GitHub Actions"** (not a branch)
- Wait a few minutes for the deployment to propagate
- Clear your browser cache and try again

### To test locally first:
```bash
flutter build web --release --base-href "/askdocs/"
cd build/web
python3 -m http.server 8000
# Visit http://localhost:8000/askdocs/
```

## Next Steps

Once deployed, every push to `main` will automatically rebuild and redeploy your app!
