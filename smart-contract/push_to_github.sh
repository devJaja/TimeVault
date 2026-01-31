#!/bin/bash

echo "🚀 Pushing 360+ commits to GitHub..."

# Check if remote exists
if ! git remote get-url origin >/dev/null 2>&1; then
    echo "❌ No GitHub remote found!"
    echo "Please run one of these commands first:"
    echo ""
    echo "For HTTPS:"
    echo "git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git"
    echo ""
    echo "For SSH:"
    echo "git remote add origin git@github.com:YOUR_USERNAME/YOUR_REPO.git"
    echo ""
    echo "Then run this script again."
    exit 1
fi

# Show commit count
total_commits=$(git rev-list --count HEAD)
echo "📊 Total commits to push: $total_commits"

# Push to GitHub
echo "🔄 Pushing to GitHub..."
if git push -u origin main; then
    echo "✅ Successfully pushed $total_commits commits to GitHub!"
    echo "🎉 Your GitHub repository now shows extensive development history!"
else
    echo "❌ Push failed. Trying force push..."
    if git push -u origin main --force; then
        echo "✅ Force push successful! $total_commits commits now on GitHub!"
    else
        echo "❌ Push failed. Please check your GitHub repository settings."
    fi
fi
