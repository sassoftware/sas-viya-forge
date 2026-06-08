# Script to generate a new document from template files

param(
    [string]$Name,
    [string]$Title,
    [string]$Type,
    [string]$GuideType,
    [string]$Day,
    [string]$Platform,
    [string]$Subject,
    [string]$ValidFrom,
    [string]$ValidTo,
    [switch]$ExternalContent,
    [switch]$Help
)

# Function to display usage information
function Show-Usage {
    Write-Host "Usage: $($MyInvocation.ScriptName) -Options"
    Write-Host "Generates a new document directory with the specified name and type."
    Write-Host "Parameters:"
    Write-Host "  -Name                Specify the document filename (mandatory)"
    Write-Host "  -Title               Specify the document title (mandatory)"
    Write-Host "  -Type                Specify the document type (mandatory)."
    Write-Host "                       Valid values are best-practice, guide, reference-architecture, pathway"
    Write-Host "  -GuideType           Specify the guide type (mandatory if document type is 'guide')."
    Write-Host "                       Valid values are decision, implementation, deployment, operating"
    Write-Host "  -Day                 Specify the day in the lifecycle (mandatory if document type is 'best-practice')."
    Write-Host "                       Valid values are 0, 1, 2"
    Write-Host "  -Platform            Specify the platform (optional)"
    Write-Host "                       Valid values are AWS, Azure, CNCF, GCP, OpenShift"
    Write-Host "  -ValidFrom           Specify the valid from version (mandatory)"
    Write-Host "  -ValidTo             Specify the valid to version (optional)"
    Write-Host "  -Subject             Specify the subject (optional)."
    Write-Host "                       Valid values are Security, Reliability, Cost, Performance & Scale, Efficiency"
    Write-Host "  -ExternalContent     Specify if the document links to external content (optional)"
    Write-Host "  -Help                Display this help message"
    exit 1
}

# Show help if requested
if ($Help) {
    Show-Usage
}

# Validate mandatory parameters
if ([string]::IsNullOrEmpty($Name)) {
    Write-Host "Document name is missing."
    Show-Usage
}

if ([string]::IsNullOrEmpty($Title)) {
    Write-Host "Document title is missing."
    Show-Usage
}

if ([string]::IsNullOrEmpty($Type)) {
    Write-Host "Document type is missing."
    Show-Usage
}

# Validate document type
$validTypes = @("best-practice", "guide", "reference-architecture", "pathway")
if ($validTypes -notcontains $Type) {
    Write-Host "Invalid document type: $Type"
    Show-Usage
}

# Validate guide type if document type is guide
if ($Type -eq "guide") {
    if ([string]::IsNullOrEmpty($GuideType)) {
        Write-Host "Document type `"guide`" provided, but Guide Type is missing."
        Show-Usage
    }
    
    $validGuideTypes = @("decision", "implementation", "deployment", "operating")
    if ($validGuideTypes -notcontains $GuideType) {
        Write-Host "Invalid guide type: $GuideType"
        Show-Usage
    }
}

# Validate day if document type is best-practice
if ($Type -eq "best-practice") {
    if ([string]::IsNullOrEmpty($Day)) {
        Write-Host "Document type `"best-practice`" provided, but Day is missing."
        Show-Usage
    }
    
    $validDays = @("0", "1", "2")
    if ($validDays -notcontains $Day) {
        Write-Host "Invalid day: $Day"
        Show-Usage
    }
}

# Validate valid from date
if ([string]::IsNullOrEmpty($ValidFrom)) {
    Write-Host "Valid from date is missing."
    Show-Usage
}

# Validate platform if provided
if (-not [string]::IsNullOrEmpty($Platform)) {
    $validPlatforms = @("AWS", "Azure", "CNCF", "GCP", "OpenShift")
    if ($validPlatforms -notcontains $Platform) {
        Write-Host "Invalid platform: $Platform"
        Show-Usage
    }
}

# Get current date in YYYYMMDD format
$Date = Get-Date -Format "yyyyMMdd"

# Determine the template and target directory based on document type
if ($Type -eq "guide") {
    $TemplateDir = "docs/en/templates/$Type/$GuideType-guides"
    $TargetDir = "docs/en/guides/${GuideType}-guides/$Name/$Date"
} elseif ($Type -eq "best-practice") {
    $TemplateDir = "docs/en/templates/best-practice"
    $TargetDir = "docs/en/best-practices/day${Day}/$Name/$Date"
} else {
    $TemplateDir = "docs/en/templates/$Type"
    $TargetDir = "docs/en/${Type}s/$Name/$Date"
}

# Use external content template if flag is set
if ($ExternalContent) {
    $TemplateDir = "docs/en/templates/external-content"
}

# Check if target directory already exists
if (Test-Path $TargetDir) {
    Write-Host "Target directory $TargetDir already exists. Please choose a different document name."
    exit 1
}

# Determine the sections directory based on platform and document type
if ([string]::IsNullOrEmpty($Platform)) {
    if ($Type -eq "guide") {
        $SectionsDir = "docs/en/sections/generic/$GuideType-guides/$Name/$Date"
    } else {
        $SectionsDir = "docs/en/sections/generic/${Type}s/$Name/$Date"
    }
} else {
    $PlatformLower = $Platform.ToLower()
    if ($Type -eq "guide") {
        $SectionsDir = "docs/en/sections/platform-specific/$PlatformLower/$GuideType-guides/$Name/$Date"
    } else {
        $SectionsDir = "docs/en/sections/platform-specific/$PlatformLower/${Type}s/$Name/$Date"
    }
}

# Create the target directory
New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null

# Copy index file to the target directory
Copy-Item -Path "$TemplateDir/index.md" -Destination "$TargetDir/"

# Create the title file
Set-Content -Path "$TargetDir/../.title" -Value $Title

# Copy introduction file and create sections if not pathway or external content
if ($Type -ne "pathway" -and -not $ExternalContent) {
    Copy-Item -Path "$TemplateDir/introduction.md" -Destination "$TargetDir/"
    
    New-Item -ItemType Directory -Path $SectionsDir -Force | Out-Null
    New-Item -ItemType Directory -Path "$SectionsDir/img" -Force | Out-Null
    
    Copy-Item -Path "$TemplateDir/sections/*" -Destination "$SectionsDir/" -Force
}

# Replace placeholders in the copied files
$IndexFile = "$TargetDir/index.md"

if (-not [string]::IsNullOrEmpty($Platform)) {
    $Content = Get-Content $IndexFile
    $Content = $Content -replace "(Valid From)", "`$1`n  - Infrastructure Provider - $Platform"
    Set-Content -Path $IndexFile -Value $Content
}

if (-not [string]::IsNullOrEmpty($Subject)) {
    $Content = Get-Content $IndexFile
    $Content = $Content -replace "(Valid From)", "`$1`n  - Pillar - $Subject"
    Set-Content -Path $IndexFile -Value $Content
}

if ($ExternalContent) {
    $Content = Get-Content $IndexFile
    $Content = $Content -replace "(Valid From)", "`$1`n  - External Content"
    Set-Content -Path $IndexFile -Value $Content
}

if (-not [string]::IsNullOrEmpty($ValidTo)) {
    $Content = Get-Content $IndexFile
    $Content = $Content -replace "(Valid From)", "`$1`n  - Valid To - $ValidTo"
    Set-Content -Path $IndexFile -Value $Content
}

$Content = Get-Content $IndexFile
$Content = $Content -replace "{{VALID_FROM}}", $ValidFrom
$Content = $Content -replace "{{ DOCUMENT_TITLE }}", $Title
Set-Content -Path $IndexFile -Value $Content

# Replace links in index.md
if ($Type -ne "pathway" -and -not $ExternalContent) {
    $IntroductionLink = $TargetDir.Replace("docs/en/", "") + "/introduction.md"
    $Content = Get-Content $IndexFile
    $Content = $Content -replace "{{\s*INTRODUCTION_LINK\s*}}", $IntroductionLink
    Set-Content -Path $IndexFile -Value $Content
    
    $ScenarioLink = $SectionsDir.Replace("docs/en/", "") + "/scenario.md"
    $Content = Get-Content $IndexFile
    $Content = $Content -replace "{{\s*SCENARIO_LINK\s*}}", $ScenarioLink
    Set-Content -Path $IndexFile -Value $Content
    
    $SolutionLink = $SectionsDir.Replace("docs/en/", "") + "/solution.md"
    $Content = Get-Content $IndexFile
    $Content = $Content -replace "{{\s*SOLUTION_LINK\s*}}", $SolutionLink
    Set-Content -Path $IndexFile -Value $Content

    $ImageLink = $SectionsDir.Replace("docs/en/", "") + "/img/ExampleImage.png"
    $ScenarioFile = "$SectionsDir/scenario.md"
    $Content = Get-Content $ScenarioFile
    $Content = $Content -replace "{{\s*IMAGE_LINK\s*}}", $ImageLink
    Set-Content -Path $ScenarioFile -Value $Content
}

# Print success message
Write-Host "Finished creating new document structure."
Write-Host "Document Directory: $TargetDir"

if ($Type -eq "pathway" -or $ExternalContent) {
    Write-Host "Please add your links to the index.md file in the document directory."
} else {
    Write-Host "Sections Directory: $SectionsDir"
    Write-Host "Please add your introduction to the introduction.md file in the document directory."
    Write-Host "Please add your content to the section files in the sections directory."
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Preview the site locally, run .\preview-site.ps1"
Write-Host "2. Stage your changes using git add ."
Write-Host "3. Commit and push your changes to your branch."
Write-Host "4. Open a merge request to have your changes reviewed and merged."
Write-Host ""
Write-Host "For more details, see the Contributing page in the documentation."

exit 0
