# CalTrackPro Development Guide

## Quick Start Commands

### Fast Development Workflow
```bash
# Quick build (fastest option)
./scripts/quick-build.sh

# Build with tests
./scripts/quick-build.sh test

# Full quality check
./scripts/quick-build.sh all

# Clean build (when things get wonky)
./scripts/quick-build.sh clean
```

### GitHub Integration Workflow

#### Feature Development
```bash
# 1. Create feature branch
git checkout -b feature/your-feature-name

# 2. Make changes and test locally
./scripts/quick-build.sh test

# 3. Commit with descriptive message
git add .
git commit -m "Add your feature description"

# 4. Push and create PR
git push origin feature/your-feature-name
```

#### Hotfix Workflow
```bash
# 1. Create hotfix branch from main
git checkout main
git checkout -b hotfix/fix-description

# 2. Make fix and test
./scripts/quick-build.sh all

# 3. Commit and push
git add .
git commit -m "Fix: description of fix"
git push origin hotfix/fix-description
```

## Automated CI/CD

### GitHub Actions Pipeline
- **Triggers**: Push to main/develop, PRs to main
- **Builds**: Automatic iOS build on every commit
- **Tests**: Full test suite runs automatically
- **Quality**: SwiftLint and SwiftFormat checks

### Branch Strategy
- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: Individual features
- `hotfix/*`: Emergency fixes

## Development Tools Setup

### Required Tools
```bash
# Install development tools
brew install swiftlint swiftformat

# Verify installation
swiftlint version
swiftformat --version
```

### Xcode Configuration
1. Enable "Show build times" in Xcode preferences
2. Set up code formatting on save
3. Configure SwiftLint build phase

## Performance Tips

### Faster Builds
1. Use the quick-build script instead of full Xcode builds
2. Clean derived data when experiencing issues
3. Use simulators for testing (faster than devices)

### Efficient Testing
- Run unit tests frequently with `./scripts/quick-build.sh test`
- Use TDD approach for new features
- Focus on testing critical business logic

## Project Structure
```
CalTrackProFixed/
├── Models/           # Data models and business logic
├── Views/           # SwiftUI views and UI components
├── Utilities/       # Helper functions and extensions
├── scripts/         # Build and automation scripts
└── .github/         # GitHub Actions workflows
```

## Troubleshooting

### Common Issues
1. **Build fails**: Run `./scripts/quick-build.sh clean`
2. **Tests hanging**: Check simulator state
3. **Linting errors**: Run `swiftlint autocorrect`

### Getting Help
- Check GitHub Actions logs for CI failures
- Review SwiftLint output for code quality issues
- Use Xcode's built-in diagnostics for runtime issues