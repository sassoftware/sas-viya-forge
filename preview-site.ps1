# Script to preview the site locally using MkDocs

# Check if python3 and pip are installed
$PythonExists = $null -ne (Get-Command py -ErrorAction SilentlyContinue)
try {
    & py -m pip --version > $null 2>&1
    $PipExists = $?
} catch {
    $PipExists = $false
}

if (-not $PythonExists) {
    Write-Host "python is required to run this script. Please install them and try again."
    exit 1
}

if (-not $PipExists) {
    Write-Host "pip is required to run this script. Please install them and try again."
    exit 1
}

# Check if running inside a Python virtual environment
if ([string]::IsNullOrEmpty($env:VIRTUAL_ENV)) {
    Write-Host "This script needs to be run inside a Python virtual environment."
    Write-Host "You can create one using the following commands:"
    Write-Host "py -m venv venv"
    Write-Host ".\venv\Scripts\Activate.ps1"
    Write-Host ""
    exit 1
}

# Install dependencies and build the site
Write-Host "Upgrading pip..."
python -m pip install --upgrade pip

Write-Host "Installing dependencies..."
pip install -r requirements.txt

# Copy the MkDocs template and generate the navigation tree
Write-Host "Setting up MkDocs configuration..."
Copy-Item -Path "template/mkdocs.template" -Destination "config/en/mkdocs.yml" -Force

# Replace LANG placeholder with 'en'
$Content = Get-Content "config/en/mkdocs.yml"
$Content = $Content -creplace "LANG", "en"
Set-Content -Path "config/en/mkdocs.yml" -Value $Content

# Run the generate nav tree script
Write-Host "Generating navigation tree..."
.\template\generate-nav-tree.ps1 docs/en config/en/mkdocs.yml

# Serve the site locally
Write-Host "Starting local preview server at http://localhost:8000"
Write-Host "Press Ctrl+C to stop the server."
mkdocs serve -f config/en/mkdocs.yml