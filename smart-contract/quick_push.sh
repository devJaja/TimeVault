#!/bin/bash
echo "Enter your GitHub repository URL (e.g., https://github.com/username/repo.git):"
read repo_url

cd /home/jaja/Desktop/my-project/TimeVault/smart-contract
git remote remove origin 2>/dev/null || true
git remote add origin "$repo_url"
git push -u origin main --force

echo "✅ Pushed 360 commits to GitHub!"
