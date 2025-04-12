#!/bin/bash
set -e

# Function to prompt for vault path
get_vault_path() {
    read -p "Please enter the path to your Obsidian vault: " vault_path
    # Expand ~ to full home directory path if used
    vault_path="${vault_path/#\~/$HOME}"
    
    if [ ! -d "$vault_path" ]; then
        echo "Error: Directory does not exist!"
        exit 1
    fi
    
    if [ ! -d "$vault_path/.obsidian" ]; then
        echo "Error: Not a valid Obsidian vault (no .obsidian directory found)!"
        exit 1
    fi
    
    echo "$vault_path"
}

# Get the vault path
vault_path=$(get_vault_path)
plugin_dir="$vault_path/.obsidian/plugins/obsidian-links-export"

# Create plugin directory if it doesn't exist
mkdir -p "$plugin_dir"

# Build the plugin
echo "Building plugin..."
npm run build

# Copy plugin files
echo "Copying plugin files to Obsidian vault..."
cp main.js manifest.json "$plugin_dir/"

echo "Plugin installed successfully!"
echo "Please:"
echo "1. Open your Obsidian vault"
echo "2. Go to Settings -> Community plugins"
echo "3. Enable 'Links Export' plugin"
echo "4. Click the link icon in the left ribbon to export links"
echo "5. Press Enter here once you've exported the links..."

read -p "Press Enter to continue..."

# Check if links.csv exists
if [ ! -f "$vault_path/links.json" ]; then
    echo "Error: links.json not found in vault! Did you run the export?"
    exit 1
fi

# Copy links.csv to _data directory
echo "Copying links.json to _data directory..."
cp "$vault_path/links.json" "../../_data/"

echo "Import complete! links.json has been copied to _data directory." 