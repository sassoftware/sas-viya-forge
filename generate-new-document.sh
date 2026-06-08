#!/usr/bin/env bash
# Script to generate a new document from template files

# Function to display usage information
usage() {
    echo "Usage: $0 <options>"
    echo "Generates a new document directory with the specified name and type."
    echo "Options:"
    echo "  -n, --name          Specify the document filename (mandatory)"
    echo "  -t, --title         Specify the document title (mandatory)"
    echo "  -c, --content-type  Specify the content type (mandatory)."
    echo "                      Valid values are best-practice, guide, reference-architecture, pathway"
    echo "  -g, --guide-type    Specify the guide type (mandatory if content type is 'guide')."
    echo "                      Valid values are decision, implementation, deployment, operating"
    echo "  -d, --day           Specify the day in the lifecycle (mandatory if content type is 'best-practice')."
    echo "                      Valid values are 0, 1, 2"
    echo "  -p, --platform      Specify the platform (optional)"
    echo "                      Valid values are AWS, Azure, CNCF, GCP, OpenShift"
    echo "  -b, --valid-from    Specify the valid from SAS Viya version (mandatory)"
    echo "  -e, --valid-to      Specify the valid to SAS Viya version (optional)"
    echo "  -s, --subject       Specify the subject (optional)."
    echo "                      Valid values are Security, Reliability, Cost, Performance & Scale, Efficiency"
    echo "  -x, --external      Specify if the document links to external content (optional)"
    echo "  -h, --help          Display this help message"
    exit 1
}

# Function to run sed with portable in-place editing flags
sed_inplace() {
    local sed_cmd="sed"

    if [[ "$OSTYPE" == "darwin"* ]] && command -v gsed >/dev/null 2>&1; then
        sed_cmd="gsed"
    fi

    if [[ "$sed_cmd" == "gsed" ]]; then
        "$sed_cmd" -i "$@"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        "$sed_cmd" -i '' "$@"
    else
        "$sed_cmd" -i "$@"
    fi
}

# Append a line after the first matching pattern using syntax accepted by BSD and GNU sed
append_after() {
    local pattern="$1"
    local text="$2"
    local file="$3"

    sed_inplace -e "/$pattern/a\\
$text
" "$file"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--name)
            DOCUMENT_NAME="$2"
            shift 2
            ;;
        -t|--title)
            DOCUMENT_TITLE="$2"
            shift 2
            ;;
        -c|--content-type)
            CONTENT_TYPE="$2"
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

# If document title is not provided, print the usage instructions
if [ -z "$DOCUMENT_TITLE" ]; 
then
    echo "Document title is missing."
    usage
fi

# If content type is not provided, print the usage instructions
if [ -z "$CONTENT_TYPE" ]; 
then
    echo "Content type is missing."
    usage
fi

# Validate content type
if [ "$CONTENT_TYPE" != "best-practice" ] && [ "$CONTENT_TYPE" != "guide" ] && [ "$CONTENT_TYPE" != "reference-architecture" ] && [ "$CONTENT_TYPE" != "pathway" ]; 
then
    echo "Invalid content type: $CONTENT_TYPE"
    usage
fi

# Validate guide type is set if content type is guide
if [ "$CONTENT_TYPE" = "guide" ];
then
    if [ -z "$GUIDE_TYPE" ]; 
    then
        echo "Content type \"guide\" provided, but Guide Type is missing."
        usage
    else
        # Validate guide type
        if [ "$GUIDE_TYPE" != "decision" ] && [ "$GUIDE_TYPE" != "implementation" ] && [ "$GUIDE_TYPE" != "deployment" ] && [ "$GUIDE_TYPE" != "operating" ]; 
        then
            echo "Invalid guide type: $GUIDE_TYPE"
            usage
        fi
    fi
fi


# Validate day is set if content type is best-practice
if [ "$CONTENT_TYPE" = "best-practice" ];
then
    if [ -z "$DAY" ]; 
    then
        echo "Content type \"best-practice\" provided, but Day is missing."
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
    if [ "$PLATFORM" != "AWS" ] && [ "$PLATFORM" != "Azure" ] && [ "$PLATFORM" != "CNCF" ] && [ "$PLATFORM" != "GCP" ] && [ "$PLATFORM" != "OpenShift" ]; 
    then
        echo "Invalid platform: $PLATFORM"
        usage
    fi
fi

DATE=$(date +%Y%m%d)

# Determine the template and target directory based on content type
if [ "$CONTENT_TYPE" == "guide" ];
then
    TEMPLATE_DIR="docs/en/templates/$CONTENT_TYPE/$GUIDE_TYPE-guides"
    TARGET_DIR="docs/en/guides/${GUIDE_TYPE}-guides/$DOCUMENT_NAME/$DATE"
elif [ "$CONTENT_TYPE" == "best-practice" ];
then
    TEMPLATE_DIR="docs/en/templates/best-practice"
    TARGET_DIR="docs/en/best-practices/day${DAY}/$DOCUMENT_NAME/$DATE"
else
    TEMPLATE_DIR="docs/en/templates/$CONTENT_TYPE"
    TARGET_DIR="docs/en/${CONTENT_TYPE}s/$DOCUMENT_NAME/$DATE"
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

# Determine the sections directory based on platform and content type
if [ -z "$PLATFORM" ];
then
    if [ "$CONTENT_TYPE" == "guide" ];
    then
        SECTIONS_DIR="docs/en/sections/generic/$GUIDE_TYPE-guides/$DOCUMENT_NAME/$DATE"
    else
        SECTIONS_DIR="docs/en/sections/generic/${CONTENT_TYPE}s/$DOCUMENT_NAME/$DATE"
    fi
else
    if [ "$CONTENT_TYPE" == "guide" ];
    then
        SECTIONS_DIR="docs/en/sections/platform-specific/${PLATFORM,,}/$GUIDE_TYPE-guides/$DOCUMENT_NAME/$DATE"
    else
        SECTIONS_DIR="docs/en/sections/platform-specific/${PLATFORM,,}/${CONTENT_TYPE}s/$DOCUMENT_NAME/$DATE"
    fi
fi


# Create the target directory
mkdir -p "$TARGET_DIR"

# Copy index files to the target directory
cp "$TEMPLATE_DIR/index.md" "$TARGET_DIR/"

# Create the title file
echo "$DOCUMENT_TITLE" > "$TARGET_DIR/../.title"

if [ "$CONTENT_TYPE" != "pathway" ] && [ "$EXTERNAL_CONTENT" = false ];
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
    append_after "Valid From" "  - Infrastructure Provider - $PLATFORM" "$TARGET_DIR/index.md"
fi

if [ ! -z "$SUBJECT" ]; then
    append_after "Valid From" "  - Pillar - $SUBJECT" "$TARGET_DIR/index.md"
fi

if [ "$EXTERNAL_CONTENT" = true ]; then
    append_after "Valid From" "  - External Content" "$TARGET_DIR/index.md"
fi

if [ ! -z "$VALID_TO" ]; then
    append_after "Valid From" "  - Valid To - $VALID_TO" "$TARGET_DIR/index.md"
fi

sed_inplace "s/{{VALID_FROM}}/$VALID_FROM/g" "$TARGET_DIR/index.md"
sed_inplace "s/{{ DOCUMENT_TITLE }}/$DOCUMENT_TITLE/g" "$TARGET_DIR/index.md"

# Replace links in index.md
if [ "$CONTENT_TYPE" != "pathway" ] && [ "$EXTERNAL_CONTENT" = false ];
then
    INTRODUCTION_LINK="/${TARGET_DIR#docs/en/}/introduction.md"
    ESCAPED_INTRODUCTION_LINK=$(printf '%s\n' "$INTRODUCTION_LINK" | sed 's/[\/&]/\\&/g')
    sed_inplace "s/{{ INTRODUCTION_LINK }}/$ESCAPED_INTRODUCTION_LINK/g" "$TARGET_DIR/index.md"

    SCENARIO_LINK="/${SECTIONS_DIR#docs/en/}/scenario.md"
    ESCAPED_SCENARIO_LINK=$(printf '%s\n' "$SCENARIO_LINK" | sed 's/[\/&]/\\&/g')
    sed_inplace "s/{{ SCENARIO_LINK }}/$ESCAPED_SCENARIO_LINK/g" "$TARGET_DIR/index.md"

    SOLUTION_LINK="/${SECTIONS_DIR#docs/en/}/solution.md"
    ESCAPED_SOLUTION_LINK=$(printf '%s\n' "$SOLUTION_LINK" | sed 's/[\/&]/\\&/g')
    sed_inplace "s/{{ SOLUTION_LINK }}/$ESCAPED_SOLUTION_LINK/g" "$TARGET_DIR/index.md"

    IMAGE_LINK="/${SECTIONS_DIR#docs/en/}/img/ExampleImage.png"
    ESCAPED_IMAGE_LINK=$(printf '%s\n' "$IMAGE_LINK" | sed 's/[\/&]/\\&/g')
    sed_inplace "s/{{ IMAGE_LINK }}/$ESCAPED_IMAGE_LINK/g" "$SECTIONS_DIR/scenario.md"
fi

# Print success message
if [ "$CONTENT_TYPE" == "pathway" ] || [ "$EXTERNAL_CONTENT" = true ];
then
    echo "Finished creating new document structure."
    echo "Document Directory: $TARGET_DIR"
    echo "Please add your links to the index.md file in the document directory."
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