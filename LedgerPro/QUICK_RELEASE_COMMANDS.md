# 🚀 LedgerPro Release - Quick Command Reference

## ⚡ Essential Commands

### First-Time Setup
```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login

# Make scripts executable
chmod +x scripts/*.sh

# Test setup
./scripts/test_build_setup.sh
```

### Create Release (Local + GitHub)
```bash
# Build release package
./scripts/create_release.sh 1.0.0-beta.1

# Create GitHub release
./scripts/create_github_release.sh 1.0.0-beta.1
```

### Automated Release (GitHub Actions)
```bash
# Tag and push (triggers automated release)
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1
```

## 📋 Quick Checklist for First Release

### ✅ One-Time Setup
```bash
cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro
brew install gh
gh auth login
chmod +x scripts/*.sh
./scripts/test_build_setup.sh
```

### ✅ Create First Release
```bash
# Build the release package
./scripts/create_release.sh 1.0.0-beta.1

# Test locally (optional)
cd releases
unzip LedgerPro-1.0.0-beta.1-macOS.zip
cd LedgerPro-1.0.0-beta.1
./Install_LedgerPro.command

# Create GitHub release
./scripts/create_github_release.sh 1.0.0-beta.1
```

### ✅ Share with Testers
```bash
# Get download link
gh release view v1.0.0-beta.1 --json assets -q '.assets[0].browserDownloadUrl'

# Or open release page
gh release view v1.0.0-beta.1 --web
```

## 🔧 Troubleshooting Commands

### Build Issues
```bash
# Clean build
rm -rf .build releases
swift package clean
swift build

# Verbose build
swift build -c release -v
```

### GitHub Issues
```bash
# Check auth
gh auth status

# Re-authenticate
gh auth logout && gh auth login

# Check repo access
gh repo view
```

### Release Issues
```bash
# List releases
gh release list

# Delete release
gh release delete v1.0.0-beta.1 --yes

# View release details
gh release view v1.0.0-beta.1
```

## 📊 Version Management

### Release Types
```bash
# Stable release
./scripts/create_release.sh 1.0.0

# Beta release
./scripts/create_release.sh 1.1.0-beta.1

# Alpha release  
./scripts/create_release.sh 1.2.0-alpha.1

# Release candidate
./scripts/create_release.sh 1.1.0-rc.1
```

### Version Bumping
```bash
# Current version
git describe --tags --abbrev=0

# Create new version
git tag v1.0.0-beta.2
git push origin v1.0.0-beta.2
```

## 🎯 Complete Workflow Example

```bash
# Start from project directory
cd /Users/jonathanhernandez/Documents/Cursor_AI/LedgerPro_Main/LedgerPro

# 1. Ensure clean state
git status
git add .
git commit -m "Prepare v1.0.0-beta.1 release"

# 2. Build release
./scripts/create_release.sh 1.0.0-beta.1

# 3. Test locally (optional but recommended)
cd releases
unzip LedgerPro-1.0.0-beta.1-macOS.zip
open LedgerPro-1.0.0-beta.1/

# 4. Create GitHub release
cd ..
./scripts/create_github_release.sh 1.0.0-beta.1

# 5. Get download link for testers
gh release view v1.0.0-beta.1 --json assets -q '.assets[0].browserDownloadUrl'
```

## 📨 Tester Communication

### Email Template
```
Subject: LedgerPro v1.0.0-beta.1 Ready for Testing

Download: [paste download link here]

Installation:
1. Download ZIP file
2. Extract and run Install_LedgerPro.command
3. Allow app in System Preferences if prompted

Test data included in TestData folder.
Report issues with steps to reproduce.

Thanks for testing!
```

### Slack/Discord Message
```
🚀 LedgerPro v1.0.0-beta.1 is ready!

📦 Download: [link]
📋 Test the new transaction import features
🐛 Report bugs in #ledgerpro-bugs

Installation instructions in the README.
```

## 🎉 Success Indicators

After running the commands, you should see:
- ✅ Release package in `releases/` directory
- ✅ GitHub release with download link
- ✅ Working installer script
- ✅ Test data files included
- ✅ Clear installation instructions

## 🆘 Emergency Commands

### Quick Fix Release
```bash
# Make changes
git add .
git commit -m "Hotfix: critical bug"

# Bump patch version
./scripts/create_release.sh 1.0.0-beta.2
./scripts/create_github_release.sh 1.0.0-beta.2
```

### Rollback Release
```bash
# Delete problematic release
gh release delete v1.0.0-beta.1 --yes

# Recreate if needed
./scripts/create_github_release.sh 1.0.0-beta.1
```

---

## 🔗 Useful Links

- **GitHub CLI Docs**: https://cli.github.com/manual/
- **Swift Package Manager**: https://swift.org/package-manager/
- **macOS Code Signing**: https://developer.apple.com/documentation/

**Happy releasing! 🎉**