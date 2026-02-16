#!/bin/bash
# Script to generate a new document from template files

# Function to display usage information
usage() {
    echo "Usage: $0 <options>"
    echo "Generates a new document directory with the specified name and type."
    echo "Options:"
    echo "  -n, --name          Specify the document filename (mandatory)"
    echo "  -t, --type          Specify the document type (mandatory)."
    echo "                      Valid values are best-practice, guide, reference-architecture, pathway"
    echo "  -g, --guide-type    Specify the guide type (mandatory if document type is 'guide')."
    echo "                      Valid values are implementation, deployment, operating"
    echo "  -d, --day           Specify the day in the lifecycle (mandatory if document type is 'best-practice')."
    echo "                      Valid values are 0, 1, 2"
    echo "  -p, --platform      Specify the platform (optional)"
    echo "                      Valid values are AWS, Azure, GCP, OpenShift"
    echo "  -b, --valid-from    Specify the valid from SAS Viya version (mandatory)"
    echo "  -e, --valid-to      Specify the valid to SAS Viya version (optional)"
    echo "  -s, --subject       Specify the subject (optional)."
    echo "                      Valid values are Security, Reliability, Cost, Performance & Scale, Efficiency"
    echo "  -x, --external      Specify if the document links to external content (optional)"
    echo "  -h, --help          Display this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            DOCUMENT_NAME="$2"
            shift 2
            ;;
        -t|--type)
            DOCUMENT_TYPE="$2"
            shift 2
            ;;
        -g|--guide-type)
            GUIDE_TYPE="$2"
            shift 2
            ;;
        -d|--day)
            DAY="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -s|--subject)
            SUBJECT="$2"
            shift 2
            ;;
        -b|--valid-from)
            VALID_FROM="$2"
            shift 2
            ;;
        -e|--valid-to)
            VALID_TO="$2"
            shift 2
            ;;
        -x|--external)
            EXTERNAL_CONTENT=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            shift
            ;;
    esac
done

# Check if EXTERNAL_CONTENT is set, if not set to false
if [ -z "$EXTERNAL_CONTENT" ]; 
then
    EXTERNAL_CONTENT=false
fi

# If document name is not provided, print the usage instructions
if [ -z "$DOCUMENT_NAME" ]; 
then
    echo "Document name is missing."
    usage
fi

# If document name is not provided, print the usage instructions
if [ -z "$DOCUMENT_TYPE" ]; 
then
    echo "Document type is missing."
    usage
fi

# Validate document type
if [ "$DOCUMENT_TYPE" != "best-practice" ] && [ "$DOCUMENT_TYPE" != "guide" ] && [ "$DOCUMENT_TYPE" != "reference-architecture" ] && [ "$DOCUMENT_TYPE" != "pathway" ]; 
then
    echo "Invalid document type: $DOCUMENT_TYPE"
    usage
fi

# Validate guide type is set if document type is guide
if [ "$DOCUMENT_TYPE" = "guide" ];
then
    if [ -z "$GUIDE_TYPE" ]; 
    then
        echo "Document type \"guide\" provided, but Guide Type is missing."
        usage
    else
        # Validate guide type
        if [ "$GUIDE_TYPE" != "implementation" ] && [ "$GUIDE_TYPE" != "deployment" ] && [ "$GUIDE_TYPE" != "operating" ]; 
        then
            echo "Invalid guide type: $GUIDE_TYPE"
            usage
        fi
    fi
fi


# Validate day is set if document type is best-practice
if [ "$DOCUMENT_TYPE" = "best-practice" ];
then
    if [ -z "$DAY" ]; 
    then
        echo "Document type \"best-practice\" provided, but Day is missing."
        usage
    else
        # Validate day
        if [ "$DAY" != "0" ] && [ "$DAY" != "1" ] && [ "$DAY" != "2" ]; 
        then
            echo "Invalid day: $DAY"
            usage
        fi
    fi
fi



# If valid from date is not provided, print the usage instructions
if [ -z "$VALID_FROM" ]; 
then
    echo "Valid from date is missing."
    usage
fi

if [ -n "$PLATFORM" ]; 
then
    if [ "$PLATFORM" != "AWS" ] && [ "$PLATFORM" != "Azure" ] && [ "$PLATFORM" != "GCP" ] && [ "$PLATFORM" != "OpenShift" ]; 
    then
        echo "Invalid platform: $PLATFORM"
        usage
    fi
fi

DATE=$(date +%Y%m%d)

# Determine the template and target directory based on document type
if [ "$DOCUMENT_TYPE" == "guide" ];
then
    TEMPLATE_DIR="docs/en/templates/$DOCUMENT_TYPE/$GUIDE_TYPE-guides"
    TARGET_DIR="docs/en/guides/${GUIDE_TYPE}-guides/$DOCUMENT_NAME/$DATE"
elif [ "$DOCUMENT_TYPE" == "best-practice" ];
then
    TEMPLATE_DIR="docs/en/templates/best-practice"
    TARGET_DIR="docs/en/best-practices/day${DAY}/$DOCUMENT_NAME/$DATE"
else
    TEMPLATE_DIR="docs/en/templates/$DOCUMENT_TYPE"
    TARGET_DIR="docs/en/${DOCUMENT_TYPE}s/$DOCUMENT_NAME/$DATE"
fi

# If external content flag is set, use the external content template instead
if [ "$EXTERNAL_CONTENT" = true ];
then
    TEMPLATE_DIR="docs/en/templates/external-content"
fi


if [ -d "$TARGET_DIR" ]; 
then
    echo "Target directory $TARGET_DIR already exists. Please choose a different document name."
    exit 1
fi

# Determine the sections directory based on platform and document type
if [ -z "$PLATFORM" ];
then
    if [ "$DOCUMENT_TYPE" == "guide" ];
    then
        SECTIONS_DIR="docs/en/sections/generic/$GUIDE_TYPE-guides/$DOCUMENT_NAME/$DATE"
    else
        SECTIONS_DIR="docs/en/sections/generic/${DOCUMENT_TYPE}s/$DOCUMENT_NAME/$DATE"
    fi
else
    if [ "$DOCUMENT_TYPE" == "guide" ];
    then
        SECTIONS_DIR="docs/en/sections/platform-specific/${PLATFORM,,}/$GUIDE_TYPE-guides/$DOCUMENT_NAME/$DATE"
    else
        SECTIONS_DIR="docs/en/sections/platform-specific/${PLATFORM,,}/${DOCUMENT_TYPE}s/$DOCUMENT_NAME/$DATE"
    fi
fi


# Create the target directory
mkdir -p "$TARGET_DIR"

# Copy index files to the target directory
cp "$TEMPLATE_DIR/index.md" "$TARGET_DIR/"

if [ "$DOCUMENT_TYPE" != "pathway" ] && [ "$EXTERNAL_CONTENT" = false ];
then
    # Copy introduction file to the target directory
    cp "$TEMPLATE_DIR/introduction.md" "$TARGET_DIR/"

    # Create the sections directory
    mkdir -p "$SECTIONS_DIR"
    mkdir -p "$SECTIONS_DIR/img"

    # Copy the sections files to the sections directory
    cp "$TEMPLATE_DIR/sections/"* "$SECTIONS_DIR/"
fi

# Replace placeholders in the copied files
if [ ! -z "$PLATFORM" ]; then
    sed -i "/Valid From/a\  - Infrastructure Provider - $PLATFORM" "$TARGET_DIR/index.md"
fi

if [ ! -z "$SUBJECT" ]; then
    sed -i "/Valid From/a\  - Pillar - $SUBJECT" "$TARGET_DIR/index.md"
fi

if [ "$EXTERNAL_CONTENT" = true ]; then
    sed -i "/Valid From/a\  - External Content" "$TARGET_DIR/index.md"
fi

if [ ! -z "$VALID_TO" ]; then
    sed -i "/Valid From/a\  - Valid To - $VALID_TO" "$TARGET_DIR/index.md"
fi

sed -i "s/{{VALID_FROM}}/$VALID_FROM/g" "$TARGET_DIR/index.md"

# Replace links in index.md
if [ "$DOCUMENT_TYPE" != "pathway" ] && [ "$EXTERNAL_CONTENT" = false ];
then
    INTRODUCTION_LINK="${TARGET_DIR#docs/en/}/introduction.md"
    ESCAPED_INTRODUCTION_LINK=$(printf '%s\n' "$INTRODUCTION_LINK" | sed 's/[\/&]/\\&/g')
    sed -i "s/{{ INTRODUCTION_LINK }}/$ESCAPED_INTRODUCTION_LINK/g" "$TARGET_DIR/index.md"

    SCENARIO_LINK="${SECTIONS_DIR#docs/en/}/scenario.md"
    ESCAPED_SCENARIO_LINK=$(printf '%s\n' "$SCENARIO_LINK" | sed 's/[\/&]/\\&/g')
    sed -i "s/{{ SCENARIO_LINK }}/$ESCAPED_SCENARIO_LINK/g" "$TARGET_DIR/index.md"

    SOLUTION_LINK="${SECTIONS_DIR#docs/en/}/solution.md"
    ESCAPED_SOLUTION_LINK=$(printf '%s\n' "$SOLUTION_LINK" | sed 's/[\/&]/\\&/g')
    sed -i "s/{{ SOLUTION_LINK }}/$ESCAPED_SOLUTION_LINK/g" "$TARGET_DIR/index.md"

    IMAGE_LINK="${SECTIONS_DIR}/img/ExampleImage.png"

    # Compute relative path from TARGET_DIR (index.md location) to IMAGE_LINK
    ImageRelativeLink=""
    if command -v realpath >/dev/null 2>&1; then
        ImageRelativeLink=$(realpath --relative-to="$TARGET_DIR" "$IMAGE_LINK" 2>/dev/null)
    else
        echo "realpath command not found, please install coreutils package."
        exit 1
    fi

    ESCAPED_IMAGE_LINK=$(printf '%s\n' "$ImageRelativeLink" | sed 's/[\/&]/\\&/g')
    sed -i "s/{{ IMAGE_LINK }}/$ESCAPED_IMAGE_LINK/g" "$SECTIONS_DIR/scenario.md"
fi

# Print success message
if [ "$DOCUMENT_TYPE" == "pathway" ] || [ "$EXTERNAL_CONTENT" = true ];
then
    echo "Finished creating new document structure."
    echo "Document Directory: $TARGET_DIR"
    echo "Please add your title and links to the index.md file in the document directory."
    echo ""
    echo "Next steps:"
    echo "1. Preview the site locally, run ./preview-site.sh"
    echo "2. Stage your changes using git add ."
    echo "3. Commit and push your changes to your branch."
    echo "4. Open a merge request to have your changes reviewed and merged."
    echo ""
    echo "For more details, see the Contributing page in the documentation."
	exit 0
else
    echo "Finished creating new document structure."
    echo "Document Directory: $TARGET_DIR"
    echo "Sections Directory: $SECTIONS_DIR"
    echo "Please add your title to the index.md file in the document directory."
    echo "Please add your introduction to the introduction.md file in the document directory."
    echo "Please add your content to the section files in the sections directory."
    echo ""
    echo "Next steps:"
    echo "1. Preview the site locally, run ./preview-site.sh"
    echo "2. Stage your changes using git add ."
    echo "3. Commit and push your changes to your branch."
    echo "4. Open a merge request to have your changes reviewed and merged."
    echo ""
    echo "For more details, see the Contributing page in the documentation."
	exit 0
fi