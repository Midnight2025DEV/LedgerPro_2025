# Git Workflow Requirements

## 🚨 CRITICAL RULES - MUST FOLLOW

### 1. NEVER COMMIT DIRECTLY TO MAIN
- **NEVER** push changes directly to the `main` branch
- All changes must go through Pull Requests
- Main branch is protected and should only receive changes via PR merges

### 2. ALWAYS CHECK FOR EXISTING PRs FIRST
```bash
gh pr list
```
- Check if there's already a PR for the issue you're fixing
- If yes, push to that existing branch
- If no, create a new branch and PR

### 3. MANDATORY WORKFLOW STEPS

#### Step 1: Check Current State
```bash
gh pr list                    # Check existing PRs
git status                   # Check current branch
git branch                   # List local branches
```

#### Step 2: Create Feature Branch
```bash
git checkout main            # Switch to main
git pull origin main         # Get latest changes
git checkout -b fix/descriptive-name-here
```

#### Step 3: Make Changes and Commit
```bash
# Make your changes
git add .
git commit -m "fix: descriptive commit message"
```

#### Step 4: Push and Create PR
```bash
git push origin fix/descriptive-name-here
gh pr create --title "Fix: Descriptive Title" --body "Detailed description"
```

### 4. BRANCH NAMING CONVENTIONS
- `fix/description` - Bug fixes
- `feat/description` - New features  
- `docs/description` - Documentation updates
- `test/description` - Test additions/fixes
- `refactor/description` - Code refactoring

### 5. HANDLING EXISTING PRs
If working on an existing PR:
```bash
git checkout existing-pr-branch-name
git pull origin existing-pr-branch-name
# Make changes
git add .
git commit -m "fix: description"
git push origin existing-pr-branch-name
```

### 6. MERGE CONFLICT RESOLUTION
If conflicts arise:
```bash
git fetch origin main
git merge origin/main
# Resolve conflicts manually
git add .
git commit -m "resolve: merge conflicts"
git push origin branch-name
```

## ❌ WHAT NOT TO DO

### Never do this:
```bash
git push origin main         # ❌ FORBIDDEN
git commit -m "fix" main     # ❌ FORBIDDEN  
git checkout main && git commit  # ❌ FORBIDDEN
```

### Signs you're doing it wrong:
- Pushing directly to main
- No PR created for changes
- Working directly on main branch
- Skipping the PR review process

## ✅ ENFORCEMENT

- All commits to main must come via PR
- PRs require review before merge
- Failed to follow this workflow = revert and redo properly
- When in doubt, create a branch and PR

## 🔧 QUICK REFERENCE

```bash
# Safe workflow - always follow this:
gh pr list                                    # 1. Check PRs
git checkout main && git pull origin main     # 2. Update main  
git checkout -b fix/issue-description         # 3. New branch
# ... make changes ...
git add . && git commit -m "fix: description" # 4. Commit
git push origin fix/issue-description         # 5. Push branch
gh pr create                                  # 6. Create PR
```

---
**Remember: Main branch is sacred. All changes go through PRs. No exceptions.**