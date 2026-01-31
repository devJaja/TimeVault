#!/bin/bash

echo "🚀 Setting up GitHub repository and pushing 360+ commits..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
fi

# Add all files
git add .

# Create initial commit if needed
if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
    git commit -m "Initial commit: Enhanced TimeVault DeFi Ecosystem"
fi

# Set default branch to main
git branch -M main

echo "📋 To complete the setup:"
echo "1. Create a new repository on GitHub"
echo "2. Run: git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
echo "3. Run: git push -u origin main"
echo ""
echo "Or run this one-liner (replace with your repo URL):"
echo "git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git && git push -u origin main"

# Show current status
echo ""
echo "📊 Current repository status:"
git log --oneline | head -10
echo "..."
echo "Total commits: $(git rev-list --count HEAD)"

echo ""
echo "✅ Repository prepared with 360+ commits ready to push!"
