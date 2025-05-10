# Approver App Development Scripts

This directory contains scripts to automate common development tasks.

## Version Management

The Approver app uses semantic versioning (MAJOR.MINOR.PATCH). These tools help maintain consistent versioning across the app.

### Quick Version Bump (Recommended)

The easiest way to update the app version is using the version.sh script:

```bash
# Run from the project root directory
./scripts/version.sh [patch|minor|major] "Your release note"

# Examples:
./scripts/version.sh patch "Fixed login screen layout issues"
./scripts/version.sh minor "Added dark theme support"
./scripts/version.sh major "Complete UI redesign with breaking changes"
```

This script will:
1. Update the version in pubspec.yaml
2. Update the VERSION file with the new version and release note
3. Add an entry to CHANGELOG.md
4. Optionally commit the changes and create a git tag
5. **IMPORTANT:** Changes will NOT be pushed to GitHub automatically

To push changes after using the script:
```bash
git push origin dev           # Push commits to development branch
git push origin v1.0.1        # Push the specific tag (example)
```

### Manual Version Bump with Dart Script

If you prefer more control, you can use the Dart script directly:

```bash
# Run from the project root directory
dart scripts/bump_version.dart [patch|minor|major] "Your release note"
```

## GitHub Actions Workflow

A GitHub Actions workflow is available for version bumping through the GitHub UI:

1. Go to your repository on GitHub
2. Navigate to Actions → Version Management
3. Click "Run workflow"
4. Select bump type and enter release note
5. The workflow will create a Pull Request with the version changes
6. You can then review and merge the PR when ready

This approach maintains the policy of not pushing changes directly.

## Version File Structure

The versioning system maintains three key files:

1. **pubspec.yaml** - Contains the official app version (e.g., `1.0.0+1`)
2. **VERSION** - Documents the version history and guidelines
3. **CHANGELOG.md** - Provides a detailed log of changes for each version

## Git Tag Naming Convention

Git tags are named with a 'v' prefix followed by the semantic version:
- v1.0.0
- v1.1.0
- v1.0.1 