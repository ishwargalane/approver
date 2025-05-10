#!/bin/bash

# Easy to remember script for bumping version
# Usage: ./scripts/version.sh [patch|minor|major] "Release note"

# Default to patch if no arguments
BUMP_TYPE=${1:-patch}
RELEASE_NOTE="${@:2}"

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Print header
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}         APPROVER VERSION BUMPER           ${NC}"
echo -e "${BLUE}============================================${NC}"

# Run dart script
echo -e "Running ${BUMP_TYPE} update with note: \"${RELEASE_NOTE}\""
dart scripts/bump_version.dart $BUMP_TYPE "$RELEASE_NOTE"

# Exit if command failed
if [ $? -ne 0 ]; then
  echo -e "${RED}Version update failed!${NC}"
  exit 1
fi

# Ask if user wants to commit changes
echo -e "${GREEN}Do you want to commit these changes? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  # Get the new version
  VERSION=$(head -n 1 VERSION)
  echo -e "Committing version ${VERSION}..."
  
  # Commit the changes
  git add pubspec.yaml VERSION CHANGELOG.md
  git commit -m "Bump version to ${VERSION}"
  
  # Ask if user wants to create a tag
  echo -e "${GREEN}Do you want to create a git tag for v${VERSION}? (y/n)${NC}"
  read -r tag_response
  if [[ "$tag_response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    git tag -a "v${VERSION}" -m "Version ${VERSION}"
    echo -e "${GREEN}Created tag v${VERSION}${NC}"
    
    # Remind user about push option without pushing
    echo -e "${YELLOW}NOTE: Changes are committed locally but not pushed to remote.${NC}"
    echo -e "${YELLOW}To push these changes to GitHub, use:${NC}"
    echo -e "${YELLOW}  git push origin dev${NC}"
    echo -e "${YELLOW}  git push origin v${VERSION}${NC}"
  fi
else
  echo -e "${YELLOW}Changes are saved locally but not committed.${NC}"
fi

echo -e "${GREEN}✅ Done!${NC}" 