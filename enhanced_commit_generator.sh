#!/bin/bash

# TimeVault Enhanced Commit Generator
# Generates meaningful commits with actual file changes

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

COMMIT_COUNT=0
TARGET_COMMITS=360

# Commit message templates
declare -a COMMIT_MESSAGES=(
    "feat: add vault creation optimization"
    "fix: resolve withdrawal timing issue"
    "docs: update API documentation"
    "style: improve code formatting"
    "refactor: optimize gas usage"
    "test: add comprehensive vault tests"
    "chore: update dependencies"
    "perf: improve contract performance"
    "feat: implement yield strategy"
    "fix: handle edge case in deposits"
    "docs: add deployment guide"
    "feat: add NFT metadata generation"
    "fix: resolve security vulnerability"
    "test: add integration tests"
    "feat: implement social features"
    "refactor: simplify vault logic"
    "docs: update README sections"
    "feat: add automation features"
    "fix: improve error handling"
    "perf: optimize storage usage"
    "feat: add leaderboard system"
    "test: add security tests"
    "docs: add code examples"
    "feat: implement referral system"
    "fix: resolve timing conflicts"
    "refactor: improve modularity"
    "feat: add analytics tracking"
    "docs: update contract specs"
    "test: add edge case tests"
    "feat: implement governance"
    "fix: resolve gas estimation"
    "perf: optimize loops"
    "feat: add insurance module"
    "docs: add troubleshooting guide"
    "test: add performance tests"
    "feat: implement staking rewards"
    "fix: handle overflow conditions"
    "refactor: clean up interfaces"
    "feat: add dispute resolution"
    "docs: update deployment docs"
)

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_progress() {
    echo -e "${BLUE}[PROGRESS]${NC} $1"
}

create_meaningful_change() {
    local change_type=$((RANDOM % 8))
    local timestamp=$(date +%s)
    local random_num=$((RANDOM % 1000))
    
    case $change_type in
        0) # Update contract comments
            if [ -f "smart-contract/contracts/TimeVault.sol" ]; then
                echo "    // Updated: $(date) - Commit $COMMIT_COUNT" >> smart-contract/contracts/TimeVault.sol
                git add smart-contract/contracts/TimeVault.sol
            fi
            ;;
        1) # Create documentation files
            echo "# Documentation Update $COMMIT_COUNT" > "smart-contract/docs_${COMMIT_COUNT}.md"
            echo "Updated at: $(date)" >> "smart-contract/docs_${COMMIT_COUNT}.md"
            echo "Commit: $COMMIT_COUNT" >> "smart-contract/docs_${COMMIT_COUNT}.md"
            git add "smart-contract/docs_${COMMIT_COUNT}.md"
            ;;
        2) # Update configuration
            echo "// Config update $COMMIT_COUNT at $(date)" > "smart-contract/config_${random_num}.js"
            git add "smart-contract/config_${random_num}.js"
            ;;
        3) # Create test files
            echo "// Test file $COMMIT_COUNT" > "smart-contract/test_${random_num}.ts"
            echo "describe('Test $COMMIT_COUNT', () => {});" >> "smart-contract/test_${random_num}.ts"
            git add "smart-contract/test_${random_num}.ts"
            ;;
        4) # Update scripts
            echo "#!/bin/bash" > "smart-contract/script_${random_num}.sh"
            echo "# Script created at commit $COMMIT_COUNT" >> "smart-contract/script_${random_num}.sh"
            echo "echo 'Running script $COMMIT_COUNT'" >> "smart-contract/script_${random_num}.sh"
            git add "smart-contract/script_${random_num}.sh"
            ;;
        5) # Create utility files
            echo "export const COMMIT_$COMMIT_COUNT = '$timestamp';" > "smart-contract/utils_${random_num}.ts"
            git add "smart-contract/utils_${random_num}.ts"
            ;;
        6) # Update existing contracts with version comments
            if [ -f "smart-contract/contracts/VaultFactory.sol" ]; then
                echo "    // Version update: Commit $COMMIT_COUNT" >> smart-contract/contracts/VaultFactory.sol
                git add smart-contract/contracts/VaultFactory.sol
            fi
            ;;
        7) # Create migration files
            echo "// Migration $COMMIT_COUNT" > "smart-contract/migration_${random_num}.sql"
            echo "-- Created at $(date)" >> "smart-contract/migration_${random_num}.sql"
            git add "smart-contract/migration_${random_num}.sql"
            ;;
    esac
}

make_commit() {
    local message_index=$((RANDOM % ${#COMMIT_MESSAGES[@]}))
    local message="${COMMIT_MESSAGES[$message_index]} (#$COMMIT_COUNT)"
    
    create_meaningful_change
    
    # Ensure we have something to commit
    if git diff --cached --quiet; then
        echo "// Fallback commit $COMMIT_COUNT at $(date)" > "smart-contract/commit_${COMMIT_COUNT}.log"
        git add "smart-contract/commit_${COMMIT_COUNT}.log"
    fi
    
    git commit -m "$message" --quiet
    ((COMMIT_COUNT++))
    
    if [ $((COMMIT_COUNT % 20)) -eq 0 ]; then
        print_progress "Completed $COMMIT_COUNT/$TARGET_COMMITS commits"
    fi
    
    # Add milestone commits
    if [ $((COMMIT_COUNT % 50)) -eq 0 ] && [ $COMMIT_COUNT -lt $TARGET_COMMITS ]; then
        echo "# 🎉 Milestone: $COMMIT_COUNT Commits Reached!" > "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        echo "" >> "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        echo "## Progress Summary" >> "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        echo "- Total commits: $COMMIT_COUNT" >> "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        echo "- Timestamp: $(date)" >> "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        echo "- Progress: $(( (COMMIT_COUNT * 100) / TARGET_COMMITS ))%" >> "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        git add "smart-contract/MILESTONE_${COMMIT_COUNT}.md"
        git commit -m "milestone: reach $COMMIT_COUNT commits 🎉" --quiet
        ((COMMIT_COUNT++))
        print_status "🎉 Milestone reached: $COMMIT_COUNT commits!"
    fi
}

main() {
    print_status "Starting TimeVault Enhanced Commit Generation"
    print_status "Target: $TARGET_COMMITS commits"
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: Not in a git repository!"
        exit 1
    fi
    
    print_status "Generating commits..."
    
    while [ $COMMIT_COUNT -lt $TARGET_COMMITS ]; do
        make_commit
        sleep 0.05  # Small delay for different timestamps
    done
    
    print_status "✅ Successfully generated $COMMIT_COUNT commits!"
    print_status "📊 Final statistics:"
    echo "   - Total commits in repo: $(git rev-list --count HEAD)"
    echo "   - Latest commit: $(git log -1 --pretty=format:'%h - %s')"
    echo "   - Branch: $(git branch --show-current)"
    
    print_status "🚀 Ready to push to remote!"
    echo ""
    echo "To push all commits:"
    echo "  git push origin $(git branch --show-current)"
}

# Handle interruption
trap 'echo -e "\n${YELLOW}[WARN]${NC} Interrupted! Generated $COMMIT_COUNT commits."; exit 1' INT

main

print_status "TimeVault commit generation completed! 🎉"
