#!/bin/bash

# Demo: generates a "Cash Payment" gateway to verify the template works.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==================================="
echo "Demo: Creating a Cash Payment Gateway"
echo "==================================="
echo ""

# Example values
GATEWAY_NAME="Cash Payment"
GATEWAY_SLUG="cash-payment"
GATEWAY_DESCRIPTION="Accept cash payments in WooCommerce POS"
GATEWAY_DEFAULT_DESCRIPTION="Pay with cash at the point of sale"
GITHUB_USERNAME="kilbot"
REPO_NAME="cash-payment-gateway"
AUTHOR_NAME="kilbot"

# Derived values
GATEWAY_ID="cash_payment"
GATEWAY_CLASS_NAME="Cash_Payment"
GATEWAY_FUNCTION_PREFIX="cash_payment"

# Create output directory
OUTPUT_DIR="demo-output/$REPO_NAME"
rm -rf "demo-output"
mkdir -p "$OUTPUT_DIR/.github/workflows"
mkdir -p "$OUTPUT_DIR/languages"
cp "$SCRIPT_DIR/.gitignore" "$OUTPUT_DIR/"

# Helper to run all placeholder replacements on a file
process_template() {
    sed -e "s/{{GATEWAY_NAME}}/$GATEWAY_NAME/g" \
        -e "s/{{GATEWAY_SLUG}}/$GATEWAY_SLUG/g" \
        -e "s/{{GATEWAY_DESCRIPTION}}/$GATEWAY_DESCRIPTION/g" \
        -e "s/{{GATEWAY_DEFAULT_DESCRIPTION}}/$GATEWAY_DEFAULT_DESCRIPTION/g" \
        -e "s/{{GITHUB_USERNAME}}/$GITHUB_USERNAME/g" \
        -e "s/{{REPO_NAME}}/$REPO_NAME/g" \
        -e "s/{{AUTHOR_NAME}}/$AUTHOR_NAME/g" \
        -e "s/{{GATEWAY_ID}}/$GATEWAY_ID/g" \
        -e "s/{{GATEWAY_CLASS_NAME}}/$GATEWAY_CLASS_NAME/g" \
        -e "s/{{GATEWAY_FUNCTION_PREFIX}}/$GATEWAY_FUNCTION_PREFIX/g" \
        "$1"
}

# Process all template files
process_template "$SCRIPT_DIR/wcpos-{{GATEWAY_SLUG}}.php" > "$OUTPUT_DIR/wcpos-cash-payment.php"
process_template "$SCRIPT_DIR/PLUGIN_README.md" > "$OUTPUT_DIR/README.md"
process_template "$SCRIPT_DIR/.github/workflows/release.yml" > "$OUTPUT_DIR/.github/workflows/release.yml"
process_template "$SCRIPT_DIR/.github/workflows/update-pot.yml" > "$OUTPUT_DIR/.github/workflows/update-pot.yml"

if [ -f "$SCRIPT_DIR/languages/woocommerce-pos-{{GATEWAY_SLUG}}-gateway.pot" ]; then
    process_template "$SCRIPT_DIR/languages/woocommerce-pos-{{GATEWAY_SLUG}}-gateway.pot" > "$OUTPUT_DIR/languages/woocommerce-pos-cash-payment-gateway.pot"
fi

echo "Demo gateway created in: $OUTPUT_DIR/"
echo ""
echo "Files created:"
find "$OUTPUT_DIR" -type f | sort | sed "s|$OUTPUT_DIR/|- |"

# Validate: check for remaining placeholders
echo ""
if grep -rP '(?<!\$)\{\{[A-Z_]+\}\}' "$OUTPUT_DIR" --include="*.php" --include="*.yml" --include="*.md" --include="*.pot" > /dev/null 2>&1; then
    echo "WARNING: Some placeholders were not replaced:"
    grep -rnP '(?<!\$)\{\{[A-Z_]+\}\}' "$OUTPUT_DIR" --include="*.php" --include="*.yml" --include="*.md" --include="*.pot"
    exit 1
else
    echo "All placeholders successfully replaced."
fi
