#!/bin/bash

# Function to extract the first title from a markdown file
extract_title() {
    local file="$1"
    grep -m 1 '^# ' "$file" | sed 's/^# //'
}

# Function to read the contents of a .title file
read_title_file() {
    local file="$1"
    cat "$file"
}

process_folder() {
    local folder="$1"
    local indent="$2"
    local lookup_name=$3
    
    local title;
    title=$(basename "$folder")

    if [ "$lookup_name" = true ]; then
        if [ -f "$folder/index.md" ]; then
            title=$(extract_title "$folder/index.md")
        else
            echo "Failed to generate nav tree. Directory does not contain an index.md file"
            exit 2
        fi
    fi

    file_path="$folder/index.md"
    rel_file_path="${file_path#$root_dir/}"
    echo "${indent}- \"${title}\": ${rel_file_path}" >> "$output"    
}

# Function to generate nav tree
generate_nav_tree() {
    local dir="$1"
    local indent="$2"
    local output="$3"
    local root_dir="$4"

    for entry in "$dir"/*; do
        if [ -d "$entry" ]; then
            local folder_name
            local title
            local version_folder

            folder_name=$(basename "$entry")
            if [ "$folder_name" = "0-intro" ]; then
                process_folder "$entry" "$indent" true
                continue
            fi
            
            # Does the current folder have version subfolders
            version_folders=$(find "$entry" -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9][0-1][0-9][0-3][0-9]' -prune | sort)
                        
            if [ -n "$version_folders" ]; then
                versions=$(echo "$version_folders" | wc -l)
                
                if [ "$versions" = 1 ]; then
                    # There is only a single version

                    version_folder=$version_folders
                    process_folder "$version_folder" "$indent" true

                    continue
                else
                    # There are multiple versions

                    # Print the name of the current folder
                    title=$folder_name
                    if [ -f "$entry/.title" ]; then
                        title=$(read_title_file "$entry/.title")
                    fi
                    
                    echo "${indent}- ${title}:" >> "$output"

                    # Print the latest version subfolder
                    latest_version=$(echo "$version_folders" | tail -n 1)
                    file_path="$latest_version/index.md"
                    rel_file_path="${file_path#$root_dir/}"
                    echo "  ${indent}- Latest Version: ${rel_file_path}" >> "$output"
                    
                    # Print the older version subfolders
                    echo "  ${indent}- Older Versions:" >> "$output"
                    older_versions=$(echo "$version_folders" | head -n -1)

                    while IFS= read -r version_folder; do
                        process_folder "$version_folder" "    $indent" false
                    done <<< "$older_versions"

                    continue
                fi
            fi

            # Continue traversing the folder structure
            title=$folder_name
            if [ -f "$entry/.title" ]; then
                title=$(read_title_file "$entry/.title")
            fi
            
            echo "${indent}- ${title}:" >> "$output"
            generate_nav_tree "$entry" "  $indent" "$output" "$root_dir"
        fi
    done
}

# Main script
main() {
    local root_dir="$1"
    local output_file="$2"
    local top_level_dirs=("reference-architectures" "best-practices" "guides" "pathways" "tools")

    if [ -z "$root_dir" ] || [ -z "$output_file" ]; then
        echo "Usage: $0 <root_directory> <output_file>"
        exit 1
    fi

    echo "nav:" >> "$output_file"
    echo "  - Home: index.md" >> "$output_file"
    
    for top_dir in "${top_level_dirs[@]}"; do
        if [ -d "$root_dir/$top_dir" ]; then
            local folder_name

            folder_name="$root_dir/$top_dir"
            if [ -f "$root_dir/$top_dir/.title" ]; then
                folder_name=$(read_title_file "$root_dir/$top_dir/.title")
            fi

            echo "  - $folder_name:" >> "$output_file"
            generate_nav_tree "$root_dir/$top_dir" "    " "$output_file" "$root_dir"
        fi
    done

    echo "  - Contributing: contributing.md" >> "$output_file"
    echo "  - Glossary: glossary.md" >> "$output_file"
    echo "  - Search: search.md" >> "$output_file"
}

main "$@"