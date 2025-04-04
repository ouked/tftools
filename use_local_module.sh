#!/usr/bin/env bash

set -euo pipefail

# === Configuration ===
# Define your local modules here: "local_path:module_name"
# The `module_name` must match the module block name in your Terraform files
LOCAL_MODULES=(
  "../module:module_block_name"
  "../another_module:another_module"
)

# Set workspace if
# export TF_WORKSPACE=''

MODULE_DEST_DIR="./.local_modules"

# === Step 1: Copy all local modules ===
echo "📦 Copying local modules..."

mkdir -p "$MODULE_DEST_DIR"

for ENTRY in "${LOCAL_MODULES[@]}"; do
  IFS=":" read -r LOCAL_PATH MODULE_NAME <<< "$ENTRY"

  if [ ! -d "$LOCAL_PATH" ]; then
    echo "❌ Module path not found: $LOCAL_PATH"
    exit 1
  fi

  DEST_PATH="${MODULE_DEST_DIR}/${MODULE_NAME}"

  echo "🔁 Copying $MODULE_NAME from $LOCAL_PATH to $DEST_PATH"

  rm -rf "$DEST_PATH"
  cp -R "$LOCAL_PATH" "$DEST_PATH"
done

# === Step 2: Rewrite source paths in *.tf files ===
echo "✏️  Rewriting module source paths in Terraform files..."

find . -maxdepth 1 -name "*.tf" | while read -r TF_FILE; do
  for ENTRY in "${LOCAL_MODULES[@]}"; do
    IFS=":" read -r _ MODULE_NAME <<< "$ENTRY"
    NEW_SOURCE="./.local_modules/${MODULE_NAME}"

    echo "  - Updating module \"$MODULE_NAME\" in $TF_FILE"

    # Backup the file
    cp "$TF_FILE" "$TF_FILE.bak"

    # Replace in a temp file
    awk -v mod="$MODULE_NAME" -v path="$NEW_SOURCE" '
      BEGIN { in_block=0 }
      {
        if ($0 ~ "module \"" mod "\"") in_block=1
        if (in_block && $0 ~ /^[[:space:]]*source[[:space:]]*=/) {
          print "# " $0
          print "  source = \"" path "\""
          next
        }
        if (in_block && $0 ~ /^[[:space:]]*version[[:space:]]*=/) {
          print "# " $0
          next
        }
        print
        if (in_block && $0 ~ /^[[:space:]]*}[[:space:]]*$/) in_block=0
      }
    ' "$TF_FILE.bak" > "$TF_FILE"
  done
done

# === Step 3: Run Terraform ===
if [ "${SKIP_INIT:-false}" = false ]; then
  echo "🚀 Running terraform init..."
  terraform init
else
  echo "⚠️ Skipping terraform init because SKIP_INIT=true"
fi

echo "🧪 Running terraform apply..."
terraform apply 
