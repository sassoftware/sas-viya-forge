#!/bin/bash
# Script to preview the site locally using MkDocs

# Check if python3 and pip are installed
if ! command -v python3 &> /dev/null ; then
    echo "python3 is required to run this script. Please install them and try again."
    exit 1
fi

if ! command -v pip &> /dev/null ; then
    echo "pip is required to run this script. Please install it and try again."
    exit 1
fi

# Check if the current directory is a venv
if [ -z "$VIRTUAL_ENV" ]; then
    echo "This script needs to be run inside a Python virtual environment."
    echo "You can create one using the following commands:"
    echo "python3 -m venv venv"
    echo "source venv/bin/activate"
    echo ""
    exit 1
fi

# Install dependencies and build the site
python3 -m pip install --upgrade pip
pip install -r requirements.txt

# Copy the MkDocs template and generate the navigation tree
cp template/mkdocs.template config/en/mkdocs.yml
sed -i -e 's/LANG/en/g' config/en/mkdocs.yml
bash template/generate-nav-tree.sh docs/en config/en/mkdocs.yml

# Serve the site locally
echo "Starting local preview server at http://localhost:8000"
echo "Press Ctrl+C to stop the server."
mkdocs serve -f config/en/mkdocs.yml
