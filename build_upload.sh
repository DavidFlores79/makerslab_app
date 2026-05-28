#!/bin/bash

# =============================================================================
# MakersLab APK Build & Upload Script (macOS/Linux)
# =============================================================================
# Usage:
#   ./build_upload.sh <FOLDER_ID> [FILE_ID]
#
# Examples:
#   ./build_upload.sh 1BTZ3offlSOvIhVZQLVJiJEqut7toI7bV
#   ./build_upload.sh 1BTZ3offlSOvIhVZQLVJiJEqut7toI7bV 1cwp1P62PX1iNKFKGyD5ToU6rm6ffG98O
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FOLDER_ID="${1:-}"
FILE_ID="${2:-}"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

# Validate folder ID
if [ -z "$FOLDER_ID" ]; then
    echo -e "${RED}❌ Error: Folder ID is required${NC}"
    echo ""
    echo "Usage: ./build_upload.sh <FOLDER_ID> [FILE_ID]"
    echo ""
    echo "Examples:"
    echo "  ./build_upload.sh 1BTZ3offlSOvIhVZQLVJiJEqut7toI7bV"
    echo "  ./build_upload.sh 1BTZ3offlSOvIhVZQLVJiJEqut7toI7bV <FILE_ID>"
    exit 1
fi

# Check if gdrive is installed
if ! command -v gdrive &> /dev/null; then
    echo -e "${RED}❌ Error: gdrive is not installed${NC}"
    echo "Install with: brew install gdrive"
    exit 1
fi

echo -e "${BLUE}🔨 Building MakersLab APK...${NC}"
flutter build apk --release

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Build successful${NC}"
echo ""

# Check for existing APKs in the folder
echo -e "${BLUE}🔍 Checking for existing APKs in Google Drive folder...${NC}"

APK_LIST=$(gdrive files list --parent "$FOLDER_ID" --skip-header 2>/dev/null | grep -i "\.apk" || true)
APK_COUNT=$(echo "$APK_LIST" | grep -c "\.apk" 2>/dev/null || echo "0")

if [ -z "$APK_LIST" ] || [ "$APK_COUNT" -eq 0 ]; then
    APK_COUNT=0
fi

echo -e "${YELLOW}Found $APK_COUNT APK file(s) in folder${NC}"
echo ""

if [ "$APK_COUNT" -eq 0 ]; then
    echo -e "${BLUE}☁️  No existing APK found. Uploading new file...${NC}"
    gdrive files upload --parent "$FOLDER_ID" "$APK_PATH"
    echo -e "${GREEN}✅ Upload complete!${NC}"

elif [ "$APK_COUNT" -eq 1 ]; then
    EXISTING_ID=$(echo "$APK_LIST" | awk '{print $1}')
    EXISTING_NAME=$(echo "$APK_LIST" | awk '{print $2}')

    echo -e "${BLUE}☁️  Found existing APK: $EXISTING_NAME${NC}"
    echo -e "${BLUE}☁️  Updating file (ID: $EXISTING_ID)...${NC}"
    gdrive files update "$EXISTING_ID" "$APK_PATH"
    echo -e "${GREEN}✅ Update complete!${NC}"

else
    echo -e "${YELLOW}⚠️  Multiple APK files found in folder:${NC}"
    echo ""
    echo "$APK_LIST" | while read -r line; do
        id=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{print $2}')
        echo "  ID: $id  |  Name: $name"
    done
    echo ""

    if [ -z "$FILE_ID" ]; then
        echo -e "${RED}❌ Error: Multiple APKs found. Please provide the FILE_ID to update.${NC}"
        echo ""
        echo "Usage: ./build_upload.sh $FOLDER_ID <FILE_ID>"
        exit 1
    else
        echo -e "${BLUE}☁️  Updating specified file (ID: $FILE_ID)...${NC}"
        gdrive files update "$FILE_ID" "$APK_PATH"
        echo -e "${GREEN}✅ Update complete!${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 Done!${NC}"
