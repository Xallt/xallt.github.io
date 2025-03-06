#!/usr/bin/env python3
"""
Post Creator for Jekyll with Chirpy Theme

This script helps create new posts for a Jekyll blog using the Chirpy theme.
It prompts for post details, shows existing tags and categories,
and generates a properly formatted post file.
"""

import datetime
import os
import re
from collections import Counter

# Try to import dependencies, install if missing
try:
    import pytz
    import yaml
except ImportError:
    print("Missing dependencies. Installing required packages...")
    import subprocess
    import sys

    # Install required packages
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pyyaml", "pytz"])

    # Try importing again
    import pytz
    import yaml

    print("Dependencies installed successfully.")

# Configuration
POSTS_DIR = "_posts"
DEFAULT_TIMEZONE = "Asia/Tbilisi"  # From _config.yml
DEFAULT_AUTHOR = "xallt"


def slugify(text):
    """Convert text to slug format for filenames."""
    # Convert to lowercase and replace spaces with hyphens
    slug = text.lower().strip().replace(" ", "-")
    # Remove special characters
    slug = re.sub(r"[^a-z0-9-]", "", slug)
    # Replace multiple hyphens with a single one
    slug = re.sub(r"-+", "-", slug)
    return slug


def extract_front_matter(file_path):
    """Extract front matter from a post file."""
    try:
        with open(file_path, "r", encoding="utf-8") as file:
            content = file.read()
            # Find front matter between --- markers
            match = re.search(r"^---\s*\n(.*?)\n---\s*\n", content, re.DOTALL)
            if match:
                front_matter_text = match.group(1)
                try:
                    # Parse YAML front matter
                    return yaml.safe_load(front_matter_text)
                except yaml.YAMLError:
                    return {}
    except Exception as e:
        print(f"Error reading {file_path}: {e}")
    return {}


def get_existing_tags_and_categories():
    """Scan existing posts to collect tags and categories."""
    tags = Counter()
    categories = Counter()
    main_categories = Counter()
    sub_categories = Counter()

    # Get all markdown files in the posts directory
    post_files = [
        f for f in os.listdir(POSTS_DIR) if f.endswith(".md") or f.endswith(".markdown")
    ]

    for post_file in post_files:
        file_path = os.path.join(POSTS_DIR, post_file)
        front_matter = extract_front_matter(file_path)

        # Extract tags
        post_tags = front_matter.get("tags", [])
        if isinstance(post_tags, list):
            for tag in post_tags:
                tags[tag] += 1

        # Extract categories
        post_categories = front_matter.get("categories", [])
        if isinstance(post_categories, list):
            # Track main and sub categories separately
            if len(post_categories) >= 1:
                main_categories[post_categories[0]] += 1
            if len(post_categories) >= 2:
                sub_categories[post_categories[1]] += 1

            for category in post_categories:
                categories[category] += 1

    return dict(tags), dict(categories), dict(main_categories), dict(sub_categories)


def prompt_with_suggestions(
    prompt, suggestions=None, allow_multiple=False, required=True
):
    """Prompt user with suggestions and return their choice(s)."""
    while True:
        if suggestions:
            print(f"\n{prompt}")
            print("Existing options:")
            for i, option in enumerate(suggestions, 1):
                print(f"  {i}. {option}")
            print("  0. Enter custom value")

            if allow_multiple:
                print("\nEnter numbers separated by commas, or 0 for custom input")
                choice = input("> ").strip()

                if choice == "" and not required:
                    return []
                elif choice == "" and required:
                    print("This field is required. Please make a selection.")
                    continue

                if choice == "0":
                    custom = input("Enter custom values (comma-separated): ").strip()
                    if custom:
                        values = [item.strip() for item in custom.split(",")]
                        if not values:
                            print("No valid values entered. Please try again.")
                            continue
                        return values
                    elif not required:
                        return []
                    else:
                        print(
                            "This field is required. Please enter at least one value."
                        )
                        continue

                try:
                    # Parse comma-separated numbers
                    indices = [int(idx.strip()) for idx in choice.split(",")]
                    result = []
                    invalid_indices = []

                    for idx in indices:
                        if 1 <= idx <= len(suggestions):
                            result.append(suggestions[idx - 1])
                        else:
                            invalid_indices.append(idx)

                    if invalid_indices:
                        print(
                            f"Invalid option(s): {', '.join(str(idx) for idx in invalid_indices)}"
                        )
                        print(
                            f"Please enter numbers between 1 and {len(suggestions)}, or 0 for custom input."
                        )
                        continue

                    if result or not required:
                        return result
                    else:
                        print("No valid options selected. Please try again.")
                        continue
                except ValueError:
                    print(
                        "Please enter valid numbers separated by commas, or 0 for custom input."
                    )
                    continue
            else:
                choice = input("> ").strip()

                if choice == "" and not required:
                    return None
                elif choice == "" and required:
                    print("This field is required. Please make a selection.")
                    continue

                if choice == "0":
                    custom = input("Enter custom value: ").strip()
                    if custom or not required:
                        return custom
                    else:
                        print("This field is required. Please enter a value.")
                        continue

                try:
                    idx = int(choice)
                    if 1 <= idx <= len(suggestions):
                        return suggestions[idx - 1]
                    else:
                        print(
                            f"Invalid option: {idx}. Please enter a number between 1 and {len(suggestions)}, or 0 for custom input."
                        )
                        continue
                except ValueError:
                    print(
                        f"Invalid input: '{choice}'. Please enter a number between 1 and {len(suggestions)}, or 0 for custom input."
                    )
                    continue
        else:
            value = input(f"{prompt}: ").strip()
            if value or not required:
                return value
            else:
                print("This field is required. Please enter a value.")
                continue


def create_post():
    """Main function to create a new post."""
    print("=== Jekyll Post Creator for Chirpy Theme ===\n")

    # Get existing tags and categories
    tags_dict, categories_dict, main_categories_dict, sub_categories_dict = (
        get_existing_tags_and_categories()
    )
    tags_list = sorted(tags_dict.keys())
    main_categories_list = sorted(main_categories_dict.keys())
    sub_categories_list = sorted(sub_categories_dict.keys())

    # Get post title
    while True:
        title = prompt_with_suggestions("Enter post title", required=True)
        if not title or len(title.strip()) < 3:
            print("Title must be at least 3 characters long. Please try again.")
            continue
        break

    # Generate filename slug
    date_str = datetime.datetime.now().strftime("%Y-%m-%d")
    slug = slugify(title)
    if not slug:
        print("Warning: Generated slug is empty. Using 'untitled' as fallback.")
        slug = "untitled"

    filename = f"{date_str}-{slug}.md"
    filepath = os.path.join(POSTS_DIR, filename)

    # Check if file already exists
    if os.path.exists(filepath):
        overwrite = input(f"File {filename} already exists. Overwrite? (y/n): ").lower()
        if overwrite != "y":
            print("Operation cancelled.")
            return

    # Get main category (first level)
    print("\nChirpy theme requires exactly two categories for proper folder structure.")
    print(
        "The first category determines the main section, and the second determines the subsection."
    )

    if not main_categories_list:
        print("No existing main categories found. You'll need to create a new one.")
        main_category = input("Enter a new main category: ").strip()
        if not main_category:
            print("Main category cannot be empty. Using 'Uncategorized' as fallback.")
            main_category = "Uncategorized"
    else:
        main_category = prompt_with_suggestions(
            "Select MAIN category (first level)",
            main_categories_list,
            allow_multiple=False,
            required=True,
        )

    # Get sub category (second level)
    if not sub_categories_list:
        print("No existing sub categories found. You'll need to create a new one.")
        sub_category = input("Enter a new sub category: ").strip()
        if not sub_category:
            print("Sub category cannot be empty. Using 'General' as fallback.")
            sub_category = "General"
    else:
        sub_category = prompt_with_suggestions(
            "Select SUB category (second level)",
            sub_categories_list,
            allow_multiple=False,
            required=True,
        )

    # Combine into categories list with exactly two elements
    categories = [main_category, sub_category]

    # Get tags (showing existing ones)
    print("\nTags should be lowercase and descriptive")
    tags = prompt_with_suggestions(
        "Select tags", tags_list, allow_multiple=True, required=False
    )

    # Convert tags to lowercase
    tags = [tag.lower() for tag in tags]

    # Set default values for front matter options
    # Math is enabled by default
    math_enabled = True

    # Mermaid diagrams are disabled by default
    mermaid_enabled = False

    # Post pinning is disabled by default
    pin_post = False

    # Table of contents is enabled by default
    toc_enabled = True

    # Create front matter
    front_matter = {
        "title": title,
        "date": datetime.datetime.now(pytz.timezone(DEFAULT_TIMEZONE)).strftime(
            "%Y-%m-%d %H:%M:%S %z"
        ),
        "author": DEFAULT_AUTHOR,
    }

    # Always include categories with exactly two elements
    front_matter["categories"] = categories

    if tags:
        front_matter["tags"] = tags

    # Always include math by default
    front_matter["math"] = math_enabled

    # Only include mermaid if enabled (false by default)
    if mermaid_enabled:
        front_matter["mermaid"] = True

    # Only include pin if enabled (false by default)
    if pin_post:
        front_matter["pin"] = True

    # TOC is enabled by default in Chirpy, so only include if disabled
    if not toc_enabled:
        front_matter["toc"] = False

    # Create post content
    post_content = "---\n"
    post_content += yaml.dump(
        front_matter, default_flow_style=False, allow_unicode=True
    )
    post_content += "---\n\n"
    post_content += "<!-- Write your content here -->\n"

    # Write to file
    try:
        with open(filepath, "w", encoding="utf-8") as file:
            file.write(post_content)
        print(f"\nPost created successfully: {filepath}")
        print(f"Categories: {categories[0]}/{categories[1]}")
        print(
            "Default settings: math=enabled, mermaid=disabled, pinned=no, TOC=enabled"
        )
    except Exception as e:
        print(f"Error creating post file: {e}")
        return

    print("\nRemember these formatting options:")
    print('- Images: ![Alt text](/path/to/image){: width="700" height="400" .shadow }')
    print("- Prompts: > Text {: .prompt-tip/info/warning/danger }")
    print("- Code: ```language\ncode\n```")
    print("- File paths: `/path/to/file`{: .filepath}")
    print("- Math: $$ equation $$ (with blank lines before/after for block math)")

    print(
        "\nTo add an image path or description, edit the front matter manually after writing content."
    )


if __name__ == "__main__":
    create_post()
