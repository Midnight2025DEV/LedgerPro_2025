# Git Workflow Guidelines

## IMPORTANT: Never Push to Main

All changes must go through pull requests. Direct pushes to main are prohibited.

## Workflow Steps

### 1. Check for Existing PRs
```bash
gh pr list
```

### 2. Update Main Branch
```bash
git checkout main
git pull origin main
```

### 3. Create Feature Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 4. Make Changes and Commit
```bash
git add .
git commit -m "type: description"
```

Commit types:
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test additions/changes
- `chore:` Maintenance tasks

### 5. Push to Feature Branch
```bash
git push origin feature/your-feature-name
```

### 6. Create Pull Request
```bash
gh pr create
```

### 7. After PR is Merged
```bash
git checkout main
git pull origin main
git branch -D feature/your-feature-name
```

## Branch Naming Convention

- `feature/` - New features
- `fix/` - Bug fixes
- `hotfix/` - Urgent production fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring

## PR Requirements

1. All tests must pass
2. Code review approved
3. No merge conflicts
4. Descriptive PR title and description

## Example Complete Workflow

```bash
# 1. Check PRs
gh pr list

# 2. Update main
git checkout main
git pull origin main

# 3. Create branch
git checkout -b fix/categorization-test-failures

# 4. Make changes
# ... edit files ...

# 5. Commit
git add .
git commit -m "fix: Resolve categorization test failures in CI"

# 6. Push
git push origin fix/categorization-test-failures

# 7. Create PR
gh pr create --title "Fix categorization test failures" --body "Resolves test failures by importing working rules from enhanced branch"

# 8. After merge
git checkout main
git pull origin main
git branch -D fix/categorization-test-failures
```

## Important Notes

- Always run tests before pushing: `swift test`
- Keep branches focused on single issues
- Update branch from main if it gets behind
- Delete branches after merging