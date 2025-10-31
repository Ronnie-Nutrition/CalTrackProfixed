#!/bin/bash
# GitHub Setup Script for CalTrackProFixed
# Run this after creating the repository on GitHub.com

echo "🚀 Setting up GitHub connection for CalTrackProFixed..."

# You'll need to replace YOUR_USERNAME with your actual GitHub username
echo "📝 Please enter your GitHub username:"
read -p "GitHub username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ GitHub username is required!"
    exit 1
fi

echo "🔗 Adding GitHub remote..."
git remote add origin "https://github.com/$GITHUB_USERNAME/CalTrackProFixed.git"

echo "📤 Pushing to GitHub..."
git push -u origin main

echo "✅ Successfully connected to GitHub!"
echo "🌐 Your repository: https://github.com/$GITHUB_USERNAME/CalTrackProFixed"
echo "🤖 GitHub Actions will start running automatically!"

# Verify the connection
echo "🔍 Verifying connection..."
git remote -v