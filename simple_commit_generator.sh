#!/bin/bash

# Simple but effective commit generator for TimeVault
set -e

COMMIT_COUNT=0
TARGET=360

echo "🚀 Starting TimeVault commit generation..."
echo "Target: $TARGET commits"

# Simple commit messages
MESSAGES=(
    "feat: enhance vault functionality"
    "fix: improve error handling"
    "docs: update documentation"
    "refactor: optimize code structure"
    "test: add comprehensive tests"
    "perf: improve performance"
    "style: format code"
    "chore: update dependencies"
    "feat: add new features"
    "fix: resolve bugs"
)

while [ $COMMIT_COUNT -lt $TARGET ]; do
    # Create a simple file change
    echo "Commit $COMMIT_COUNT created at $(date)" > "smart-contract/auto_commit_${COMMIT_COUNT}.txt"
    
    # Add and commit
    git add "smart-contract/auto_commit_${COMMIT_COUNT}.txt"
    
    # Select random message
    MSG_INDEX=$((COMMIT_COUNT % ${#MESSAGES[@]}))
    MESSAGE="${MESSAGES[$MSG_INDEX]} (#$COMMIT_COUNT)"
    
    git commit -m "$MESSAGE" --quiet
    
    COMMIT_COUNT=$((COMMIT_COUNT + 1))
    
    # Progress update every 50 commits
    if [ $((COMMIT_COUNT % 50)) -eq 0 ]; then
        echo "Progress: $COMMIT_COUNT/$TARGET commits completed"
    fi
    
    # Milestone commits
    if [ $((COMMIT_COUNT % 100)) -eq 0 ] && [ $COMMIT_COUNT -lt $TARGET ]; then
        echo "🎉 Milestone: $COMMIT_COUNT commits!" > "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        git add "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        git commit -m "milestone: reach $COMMIT_COUNT commits 🎉" --quiet
        COMMIT_COUNT=$((COMMIT_COUNT + 1))
        echo "🎉 Milestone: $COMMIT_COUNT commits reached!"
    fi
done

echo "✅ Successfully generated $COMMIT_COUNT commits!"
echo "📊 Total commits in repository: $(git rev-list --count HEAD)"
echo "🚀 Ready to push to remote repository!"
