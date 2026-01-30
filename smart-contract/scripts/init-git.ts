#!/usr/bin/env node

import { execSync } from 'child_process';
import { readFileSync } from 'fs';

async function initializeGitAndPush() {
  console.log('🚀 Initializing Git repository and pushing TimeVault project...\n');

  try {
    // Initialize git if not already initialized
    try {
      execSync('git status', { stdio: 'ignore' });
      console.log('✅ Git repository already initialized');
    } catch {
      console.log('📦 Initializing Git repository...');
      execSync('git init', { stdio: 'inherit' });
    }

    // Add all files
    console.log('📁 Adding all files to Git...');
    execSync('git add .', { stdio: 'inherit' });

    // Read commit messages
    const commitMessages = readFileSync('commit-messages.txt', 'utf8').split('\n').filter(msg => msg.trim());
    
    console.log(`📝 Found ${commitMessages.length} commit messages\n`);

    // Create initial commit with first message
    console.log('💾 Creating initial commit...');
    const firstCommit = commitMessages[0] || 'feat: initialize TimeVault smart contract project';
    
    try {
      execSync(`git commit -m "${firstCommit}"`, { stdio: 'inherit' });
      console.log('✅ Initial commit created');
    } catch (error) {
      console.log('ℹ️  No changes to commit or commit already exists');
    }

    // Set up remote (you'll need to replace with your actual repository URL)
    console.log('\n🔗 Setting up remote repository...');
    console.log('ℹ️  Please set up your remote repository manually:');
    console.log('   git remote add origin <your-repository-url>');
    console.log('   git branch -M main');
    console.log('   git push -u origin main');

    console.log('\n📋 Remaining commit messages for future use:');
    console.log(`   ${commitMessages.length - 1} commit messages available in commit-messages.txt`);
    
    console.log('\n🎉 Git repository initialized successfully!');
    console.log('\n📦 Project Structure:');
    execSync('find . -type f -name "*.sol" -o -name "*.ts" -o -name "*.md" | head -20', { stdio: 'inherit' });

    console.log('\n✅ TimeVault project is ready for deployment!');
    console.log('\nNext steps:');
    console.log('1. Set up your remote repository');
    console.log('2. Configure Base Sepolia environment variables');
    console.log('3. Deploy contracts: npm run deploy -- --network baseSepolia');
    console.log('4. Verify contracts on Basescan');

  } catch (error) {
    console.error('❌ Git initialization failed:', error);
    process.exit(1);
  }
}

initializeGitAndPush();
