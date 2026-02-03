#!/bin/bash

# WooCommerce POS Gateway Generator Script
# This script creates a new WooCommerce POS gateway plugin from the template

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==================================="
echo "WooCommerce POS Gateway Generator"
echo "==================================="
echo ""

# Validation helper
validate_input() {
    if [ -z "$2" ]; then
        echo "Error: $1 cannot be empty."
        exit 1
    fi
}

# Escape special characters for sed replacement strings
escape_sed() {
    printf '%s' "$1" | sed 's/[&\\/]/\\&/g'
}

# Prompt for plugin details
read -p "Enter gateway name (e.g., 'Cash Payment'): " GATEWAY_NAME
validate_input "Gateway name" "$GATEWAY_NAME"

read -p "Enter gateway slug (e.g., 'cash-payment'): " GATEWAY_SLUG
validate_input "Gateway slug" "$GATEWAY_SLUG"

read -p "Enter gateway description: " GATEWAY_DESCRIPTION
validate_input "Gateway description" "$GATEWAY_DESCRIPTION"

read -p "Enter default checkout description: " GATEWAY_DEFAULT_DESCRIPTION
validate_input "Default checkout description" "$GATEWAY_DEFAULT_DESCRIPTION"

read -p "Enter your GitHub username: " GITHUB_USERNAME
validate_input "GitHub username" "$GITHUB_USERNAME"

read -p "Enter repository name (e.g., 'cash-payment-gateway'): " REPO_NAME
validate_input "Repository name" "$REPO_NAME"

read -p "Enter author name: " AUTHOR_NAME
validate_input "Author name" "$AUTHOR_NAME"

read -p "Enter target directory path (or press Enter for current directory): " TARGET_DIR

# Set default target directory if not provided
if [ -z "$TARGET_DIR" ]; then
    TARGET_DIR="."
fi

# Create target directory
TARGET_PATH="$TARGET_DIR/$REPO_NAME"
mkdir -p "$TARGET_PATH"

# Convert names to different formats
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

# Create directory structure
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

# Process and copy main plugin file
process_template "$SCRIPT_DIR/wcpos-{{GATEWAY_SLUG}}.php" > "$TARGET_PATH/wcpos-$GATEWAY_SLUG.php"

# Process README (PLUGIN_README.md is the template for generated plugins)
process_template "$SCRIPT_DIR/PLUGIN_README.md" > "$TARGET_PATH/README.md"

# Process GitHub workflows
process_template "$SCRIPT_DIR/.github/workflows/release.yml" > "$TARGET_PATH/.github/workflows/release.yml"
process_template "$SCRIPT_DIR/.github/workflows/update-pot.yml" > "$TARGET_PATH/.github/workflows/update-pot.yml"

# Process and rename POT file
if [ -f "$SCRIPT_DIR/languages/woocommerce-pos-{{GATEWAY_SLUG}}-gateway.pot" ]; then
    process_template "$SCRIPT_DIR/languages/woocommerce-pos-{{GATEWAY_SLUG}}-gateway.pot" > "$TARGET_PATH/languages/woocommerce-pos-$GATEWAY_SLUG-gateway.pot"
fi

echo ""
echo "Gateway plugin created successfully!"
echo "Location: $TARGET_PATH"
echo ""
echo "Next steps:"
echo "1. cd $TARGET_PATH"
echo "2. git init"
echo "3. git add ."
echo "4. git commit -m 'Initial commit'"
echo "5. Create a new repository on GitHub: https://github.com/new"
echo "6. git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"
echo "7. git push -u origin main"
echo ""
echo "To create a release:"
echo "- Update the Version number in wcpos-$GATEWAY_SLUG.php"
echo "- Commit and push to main branch"
echo "- GitHub Actions will automatically create a release with the plugin ZIP"
