#!/bin/bash
# ==============================================================================
# Automated GitHub Repository Initializer and Push Script
# Synchronizes local project workspaces with remote GitHub repositories.
# ==============================================================================

set -e # Stop execution instantly if any command fails

# 1. Configurable Variables
GITHUB_USERNAME="YOUR_GITHUB_USERNAME"
REPO_NAME="YOUR_REPOSITORY_NAME"
BRANCH_NAME="main"

echo "==> [1/4] Validating local Git environment..."

# Setup basic identity strings if not already globally defined
git config --global user.name "Your Name" || true
git config --global user.email "your_email@example.com" || true

# Initialize Git repository safely without overwriting configurations
if [ ! -d ".git" ]; then
    echo "Initializing fresh local git repository..."
    git init -b "$BRANCH_NAME"
else
    echo "Git repository is already initialized locally."
fi

# 2. Inject an Optimized .gitignore for Android Kernel Building
echo "==> [2/4] Verifying .gitignore constraints..."
if [ ! -f ".gitignore" ]; then
    cat << 'EOF' > .gitignore
# System / IDE Overhead
.DS_Store
.idea/
.vscode/

# Compilation Artifacts and Bazel Caching Layer
out/
.repo/
.bazelrc
.bazel_lock
bazel-*
*.o
*.ko
*.img
Image
EOF
    echo "Created a default .gitignore layout."
fi

# 3. Stages changes for commit
echo "==> [3/4] Staging and committing files locally..."
git add .

# Avoid failing out if there are no new structural changes to commit
if git diff-index --quiet HEAD --; then
    echo "No modifications or new files discovered to commit."
else
    git commit -m "Initial commit: Android 17 Pantah kernel build setup"
fi

# 4. Linking to Remote Host and Pushing Payload
echo "==> [4/4] Establishing secure remote endpoints and pushing..."

# Purge existing stale origins if modifying an older codebase link
git remote remove origin 2>/dev/null || true

# Bind target GitHub URI using secure SSH configuration profiles
REMOTE_URL="git@github.com:$GITHUB_USERNAME/$REPO_NAME.git"
git remote add origin "$REMOTE_URL"

echo "Pushing code assets upstream to repository: $REPO_NAME ($BRANCH_NAME)..."
git push -u origin "$BRANCH_NAME"

echo "========================================================"
echo "🎉 SUCCESS: Code base successfully published to GitHub!"
echo "📍 Target URL: https://github.com"
echo "========================================================"
