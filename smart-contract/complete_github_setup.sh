#!/bin/bash

echo "🚀 Complete GitHub Setup & Push Script"
echo "======================================"

read -p "Enter your GitHub username: " username
read -p "Enter your repository name: " repo_name

# Validate inputs
if [[ -z "$username" || -z "$repo_name" ]]; then
    echo "❌ Username and repository name are required!"
    exit 1
fi

# Set up remote
remote_url="https://github.com/$username/$repo_name.git"
echo "🔗 Setting up remote: $remote_url"

# Remove existing remote if it exists
git remote remove origin 2>/dev/null || true

# Add new remote
git remote add origin "$remote_url"

# Show commit count
total_commits=$(git rev-list --count HEAD)
echo "📊 Ready to push $total_commits commits"

# Push to GitHub
echo "🔄 Pushing to GitHub..."
if git push -u origin main; then
    echo "✅ SUCCESS! $total_commits commits pushed to GitHub!"
    echo "🎉 Visit: https://github.com/$username/$repo_name"
else
    echo "🔄 Initial push failed, trying force push..."
    if git push -u origin main --force; then
        echo "✅ SUCCESS! $total_commits commits force-pushed to GitHub!"
        echo "🎉 Visit: https://github.com/$username/$repo_name"
    else
        echo "❌ Push failed. Make sure:"
        echo "1. Repository exists on GitHub"
        echo "2. You have push permissions"
        echo "3. Repository name is correct"
    fi
fi
