#!/bin/bash

# WooCommerce POS Gateway Generator Script
# This script creates a new WooCommerce POS gateway plugin from the template

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==================================="
echo "WooCommerce POS Gateway Generator"
echo "==================================="
echo ""

# Escape special characters for sed replacement strings
escape_sed() {
    printf '%s' "$1" | sed 's/[&\\/]/\\&/g'
}

# --- Collect input ---

# Gateway name is the only required field
read -p "Enter gateway name (e.g., 'Cash Payment'): " GATEWAY_NAME
if [ -z "$GATEWAY_NAME" ]; then
    echo "Error: Gateway name is required."
    exit 1
fi

# Auto-generate slug from name: lowercase, spaces to hyphens, strip non-alphanumeric
AUTO_SLUG=$(echo "$GATEWAY_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-' | sed 's/--*/-/g' | sed 's/^-//;s/-$//')

read -p "Enter gateway slug [$AUTO_SLUG]: " GATEWAY_SLUG
GATEWAY_SLUG="${GATEWAY_SLUG:-$AUTO_SLUG}"

read -p "Enter gateway description (optional): " GATEWAY_DESCRIPTION
read -p "Enter default checkout description (optional): " GATEWAY_DEFAULT_DESCRIPTION
read -p "Enter your GitHub username (optional): " GITHUB_USERNAME

AUTO_REPO="$GATEWAY_SLUG-gateway"
read -p "Enter repository name [$AUTO_REPO]: " REPO_NAME
REPO_NAME="${REPO_NAME:-$AUTO_REPO}"

read -p "Enter author name (optional): " AUTHOR_NAME

DEFAULT_DIR="$(dirname "$SCRIPT_DIR")"
read -p "Enter target directory path [$DEFAULT_DIR]: " TARGET_DIR
TARGET_DIR="${TARGET_DIR:-$DEFAULT_DIR}"

# --- Derive values ---

GATEWAY_ID=$(echo "$GATEWAY_SLUG" | tr '-' '_')
# Capitalize each word and join with underscores: "cash payment" -> "Cash_Payment"
GATEWAY_CLASS_NAME=$(echo "$GATEWAY_NAME" | sed 's/[^a-zA-Z0-9 ]//g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' | tr ' ' '_')
GATEWAY_FUNCTION_PREFIX=$(echo "$GATEWAY_SLUG" | tr '-' '_')

# Escape user input for safe sed substitution
E_GATEWAY_NAME=$(escape_sed "$GATEWAY_NAME")
E_GATEWAY_DESCRIPTION=$(escape_sed "$GATEWAY_DESCRIPTION")
E_GATEWAY_DEFAULT_DESCRIPTION=$(escape_sed "$GATEWAY_DEFAULT_DESCRIPTION")
E_GITHUB_USERNAME=$(escape_sed "$GITHUB_USERNAME")
E_REPO_NAME=$(escape_sed "$REPO_NAME")
E_AUTHOR_NAME=$(escape_sed "$AUTHOR_NAME")

# --- Generate plugin ---

TARGET_PATH="$TARGET_DIR/$REPO_NAME"
mkdir -p "$TARGET_PATH/.github/workflows"
mkdir -p "$TARGET_PATH/languages"
cp "$SCRIPT_DIR/.gitignore" "$TARGET_PATH/"

# Helper to run all placeholder replacements on a file
process_template() {
    sed -e "s/{{GATEWAY_NAME}}/$E_GATEWAY_NAME/g" \
        -e "s/{{GATEWAY_SLUG}}/$GATEWAY_SLUG/g" \
        -e "s/{{GATEWAY_DESCRIPTION}}/$E_GATEWAY_DESCRIPTION/g" \
        -e "s/{{GATEWAY_DEFAULT_DESCRIPTION}}/$E_GATEWAY_DEFAULT_DESCRIPTION/g" \
        -e "s/{{GITHUB_USERNAME}}/$E_GITHUB_USERNAME/g" \
        -e "s/{{REPO_NAME}}/$E_REPO_NAME/g" \
        -e "s/{{AUTHOR_NAME}}/$E_AUTHOR_NAME/g" \
        -e "s/{{GATEWAY_ID}}/$GATEWAY_ID/g" \
        -e "s/{{GATEWAY_CLASS_NAME}}/$GATEWAY_CLASS_NAME/g" \
        -e "s/{{GATEWAY_FUNCTION_PREFIX}}/$GATEWAY_FUNCTION_PREFIX/g" \
        "$1"
}

process_template "$SCRIPT_DIR/wcpos-{{GATEWAY_SLUG}}.php" > "$TARGET_PATH/wcpos-$GATEWAY_SLUG.php"
process_template "$SCRIPT_DIR/PLUGIN_README.md" > "$TARGET_PATH/README.md"
process_template "$SCRIPT_DIR/.github/workflows/release.yml" > "$TARGET_PATH/.github/workflows/release.yml"
process_template "$SCRIPT_DIR/.github/workflows/update-pot.yml" > "$TARGET_PATH/.github/workflows/update-pot.yml"

if [ -f "$SCRIPT_DIR/languages/woocommerce-pos-{{GATEWAY_SLUG}}-gateway.pot" ]; then
    process_template "$SCRIPT_DIR/languages/woocommerce-pos-{{GATEWAY_SLUG}}-gateway.pot" > "$TARGET_PATH/languages/woocommerce-pos-$GATEWAY_SLUG-gateway.pot"
fi

# --- Done ---

echo ""
echo "Gateway plugin created successfully!"
echo "Location: $TARGET_PATH"
echo ""
echo "To install:"
echo "  Zip the folder and upload via WP Admin > Plugins > Add New > Upload Plugin"
echo "  Or copy the folder directly into wp-content/plugins/"
if [ -n "$GITHUB_USERNAME" ]; then
    echo ""
    echo "To push to GitHub:"
    echo "  cd $TARGET_PATH"
    echo "  git init && git add . && git commit -m 'Initial commit'"
    echo "  git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
    echo "  git push -u origin main"
fi
