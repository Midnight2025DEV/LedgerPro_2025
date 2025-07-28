# 🚀 LedgerPro Release Setup Guide

This guide walks you through setting up GitHub releases for your LedgerPro macOS app, creating release packages, and sharing with testers.

## 📋 Quick Start Checklist

### One-Time Setup
- [ ] Install GitHub CLI: `brew install gh`
- [ ] Authenticate with GitHub: `gh auth login`
- [ ] Make scripts executable: `chmod +x scripts/*.sh`
- [ ] Test local build: `./scripts/create_release.sh`

### Create First Release
- [ ] Build release package: `./scripts/create_release.sh 1.0.0-beta.1`
- [ ] Test package locally
- [ ] Create GitHub release: `./scripts/create_github_release.sh 1.0.0-beta.1`
- [ ] Share download link with testers

## 🛠️ Prerequisites

### Required Tools
```bash
# Install GitHub CLI
brew install gh

# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status
```

### Repository Setup
1. **Initialize Git repository** (if not done):
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   ```

2. **Create GitHub repository**:
   ```bash
   gh repo create LedgerPro --private --description "LedgerPro - macOS Financial Transaction Analyzer"
   git remote add origin https://github.com/yourusername/LedgerPro.git
   git push -u origin main
   ```

3. **Make scripts executable**:
   ```bash
   chmod +x scripts/*.sh
   ```

## 📦 Building Releases

### Method 1: Local Build + Manual GitHub Release

```bash
# Build release package
./scripts/create_release.sh 1.0.0-beta.1

# Create GitHub release
./scripts/create_github_release.sh 1.0.0-beta.1
```

### Method 2: Automated GitHub Actions

```bash
# Push a version tag to trigger automated release
git tag v1.0.0-beta.1
git push origin v1.0.0-beta.1

# Or manually trigger via GitHub web interface
# Go to Actions > Create Release > Run workflow
```

### Method 3: Direct GitHub CLI

```bash
# Build and create release in one go
./scripts/create_release.sh 1.0.0-beta.2
gh release create v1.0.0-beta.2 \
  releases/LedgerPro-1.0.0-beta.2-macOS.zip \
  --title "LedgerPro v1.0.0-beta.2" \
  --notes "Testing release with bug fixes" \
  --prerelease
```

## 🧪 Testing Release Packages

### Local Testing
```bash
# Build and test locally
./scripts/create_release.sh test-build

# Extract and test the package
cd releases
unzip LedgerPro-test-build-macOS.zip
cd LedgerPro-test-build
./Install_LedgerPro.command
```

### Test Data Usage
```bash
# Generate large test dataset
cd TestData
python3 generate_large_dataset.py 5000

# Import in LedgerPro:
# 1. Launch the app
# 2. Use file upload feature
# 3. Select generated CSV file
```

### Validation Checklist
- [ ] App launches without errors
- [ ] Can import sample CSV files
- [ ] Transaction categorization works
- [ ] UI is responsive
- [ ] No memory leaks with large datasets
- [ ] Foreign currency calculations are correct

## 📨 Sharing with Testers

### Private Repository (Recommended for Testing)
```bash
# Invite testers as collaborators
gh api repos/:owner/:repo/collaborators/username -X PUT

# Share direct download link
echo "Download: $(gh release view v1.0.0-beta.1 --json assets -q '.assets[0].browserDownloadUrl')"
```

### Public Release
```bash
# Make repository public (optional)
gh repo edit --visibility public

# Share release page
gh release view v1.0.0-beta.1 --web
```

### Email Template for Testers
```
Subject: LedgerPro v1.0.0-beta.1 - Testing Release

Hi [Tester Name],

I've prepared a testing release of LedgerPro for macOS. Here's what you need to know:

🔗 Download Link:
[Direct download URL from GitHub release]

📋 Installation:
1. Download and extract the ZIP file
2. Run "Install_LedgerPro.command" for automatic installation
3. Allow the app in System Preferences > Security & Privacy

🧪 What to Test:
- Import the included CSV test files
- Test transaction categorization
- Try the foreign currency features
- Test with large datasets (generate_large_dataset.py)

🐛 Report Issues:
Please report any bugs with steps to reproduce and your macOS version.

Thanks for testing!
```

## 🔧 Troubleshooting

### Build Issues
```bash
# Clean build environment
rm -rf .build releases
swift package clean

# Verbose build
swift build -c release -v

# Check dependencies
swift package resolve
```

### GitHub CLI Issues
```bash
# Re-authenticate
gh auth logout
gh auth login

# Check repository access
gh repo view

# Verify release permissions
gh api user
```

### macOS Security Issues
```bash
# Remove quarantine from built app
xattr -dr com.apple.quarantine LedgerPro.app

# Test app launch
open LedgerPro.app
```

## 🚀 Advanced Release Workflows

### Semantic Versioning
```bash
# Major release
./scripts/create_release.sh 2.0.0

# Minor release  
./scripts/create_release.sh 1.1.0

# Patch release
./scripts/create_release.sh 1.0.1

# Pre-release
./scripts/create_release.sh 1.1.0-beta.1
./scripts/create_release.sh 1.1.0-rc.1
```

### Release Channels
```bash
# Stable releases (production ready)
gh release create v1.0.0 --latest

# Beta releases (feature testing)
gh release create v1.1.0-beta.1 --prerelease

# Alpha releases (internal testing)
gh release create v1.2.0-alpha.1 --prerelease --draft
```

### Automated Version Bumping
```bash
# Create a version bump script
cat > scripts/bump_version.sh << 'EOF'
#!/bin/bash
CURRENT=$(git describe --tags --abbrev=0)
NEW_VERSION="$1"
echo "Bumping from $CURRENT to $NEW_VERSION"
git tag "v$NEW_VERSION"
git push origin "v$NEW_VERSION"
EOF

chmod +x scripts/bump_version.sh
```

## 📊 Release Analytics

### Track Downloads
```bash
# View release statistics
gh api repos/:owner/:repo/releases/latest

# Download counts
gh release view --json assets -q '.assets[].downloadCount'
```

### Monitor Usage
Add analytics to your app to track:
- Installation success rate
- Feature usage
- Crash reports
- Performance metrics

## 🔒 Security Best Practices

### For Testing Releases
- ✅ Use unsigned builds (as implemented)
- ✅ Include clear security warnings
- ✅ Provide installation instructions
- ✅ Use private repositories for internal testing

### For Production Releases
- ⭐ Get Apple Developer account ($99/year)
- ⭐ Code sign the application
- ⭐ Notarize with Apple
- ⭐ Distribute via Mac App Store or signed DMG

## 📞 Support

### Common Issues
1. **"Cannot open because of unidentified developer"**
   - Right-click app → Open → Open

2. **"Package appears to be damaged"**
   - Remove quarantine: `xattr -dr com.apple.quarantine LedgerPro.app`

3. **GitHub CLI authentication fails**
   - Use personal access token: `gh auth login --with-token`

### Getting Help
- GitHub CLI documentation: `gh help`
- Swift Package Manager: `swift package --help`
- macOS code signing: Apple Developer Documentation

---

## 🎉 You're Ready!

With this setup, you can:
- ✅ Build professional release packages
- ✅ Automate GitHub releases
- ✅ Share with testers easily
- ✅ Handle macOS security requirements
- ✅ Scale to production releases

Happy releasing! 🚀