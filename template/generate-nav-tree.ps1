# Script to generate MkDocs navigation tree from directory structure

# Function to extract the first title from a markdown file
function Extract-Title {
    param([string]$FilePath)
    
    $content = Get-Content -Path $FilePath
    foreach ($line in $content) {
        if ($line -match '^# (.+)') {
            return $matches[1]
        }
    }
}

# Function to read the contents of a .title file
function Read-TitleFile {
    param([string]$FilePath)
    
    return Get-Content -Path $FilePath -Raw | ForEach-Object { $_.Trim() }
}

# Function to process a single folder
function Process-Folder {
    param(
        [string]$Folder,
        [string]$Indent,
        [bool]$LookupName,
        [string]$RootDir,
        [string]$OutputFile
    )
    
    $title = Split-Path -Leaf $Folder
    
    if ($LookupName) {
        $indexPath = Join-Path $Folder "index.md"
        if (Test-Path $indexPath) {
            $title = Extract-Title $indexPath
        } else {
            Write-Host "Failed to generate nav tree. Directory does not contain an index.md file"
            exit 2
        }
    }
    
    $filePath = Join-Path $Folder "index.md"
    $relFilePath = $filePath.Substring($RootDir.Length).TrimStart('\').Replace('\', '/')
    
    Add-Content -Path $OutputFile -Value "$Indent- `"$title`": $relFilePath"
}

# Function to generate nav tree recursively
function Generate-NavTree {
    param(
        [string]$Dir,
        [string]$Indent,
        [string]$OutputFile,
        [string]$RootDir
    )

    $cwd = (Get-Location).ProviderPath
    $cwdWithSep = $cwd.TrimEnd('\') + '\'
    
    $entries = @(Get-ChildItem -Path $Dir -Directory -ErrorAction SilentlyContinue |
                    ForEach-Object {
                    $relative = $_.FullName -replace [regex]::Escape($cwdWithSep), ""
                    # keep .FullName and .Name so the rest of the script continues to work
                    [PSCustomObject]@{ FullName = $relative; Name = $_.Name }
                    }) 
    
    foreach ($entry in $entries) {
        $folderName = Split-Path -Leaf $entry.FullName
        
        if ($folderName -eq "0-intro") {
            Process-Folder -Folder $entry.FullName -Indent $Indent -LookupName $true -RootDir $RootDir -OutputFile $OutputFile
            continue
        }
        
        # Check for version subfolders (YYYYMMDD format)
        $versionPattern = '^[0-9]{8}$'
        $versionFolders = @(Get-ChildItem -Path $entry.FullName -Directory -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -match $versionPattern } |
                    Sort-Object -Property Name |
                    ForEach-Object {
                    $relative = $_.FullName -replace [regex]::Escape($cwdWithSep), ""
                    # keep .FullName and .Name so the rest of the script continues to work
                    [PSCustomObject]@{ FullName = $relative; Name = $_.Name }
                    })
        
        if ($versionFolders.Count -gt 0) {
            if ($versionFolders.Count -eq 1) {
                # Single version - process it directly
                Process-Folder -Folder $versionFolders[0].FullName -Indent $Indent -LookupName $true -RootDir $RootDir -OutputFile $OutputFile
                continue
            } else {
                # Multiple versions
                $title = $folderName
                $titleFile = Join-Path $entry.FullName ".title"
                if (Test-Path $titleFile) {
                    $title = Read-TitleFile $titleFile
                }
                
                Add-Content -Path $OutputFile -Value "$Indent- $title`:"
                
                # Latest version
                $latestVersion = $versionFolders[-1].FullName
                $filePath = Join-Path $latestVersion "index.md"
                $relFilePath = $filePath.Substring($RootDir.Length).TrimStart('\').Replace('\', '/')
                Add-Content -Path $OutputFile -Value "  $Indent- Latest Version: $relFilePath"
                
                # Older versions
                Add-Content -Path $OutputFile -Value "  $Indent- Older Versions:"
                $olderVersions = $versionFolders | Select-Object -SkipLast 1
                
                foreach ($versionFolder in $olderVersions) {
                    Process-Folder -Folder $versionFolder.FullName -Indent "    $Indent" -LookupName $false -RootDir $RootDir -OutputFile $OutputFile
                }
                
                continue
            }
        }
        
        # Traverse folder structure recursively
        $title = $folderName
        $titleFile = Join-Path $entry.FullName ".title"
        if (Test-Path $titleFile) {
            $title = Read-TitleFile $titleFile
        }
        
        Add-Content -Path $OutputFile -Value "$Indent- $title`:"
        Generate-NavTree -Dir $entry.FullName -Indent "  $Indent" -OutputFile $OutputFile -RootDir $RootDir
    }
}

# Main function
function Main {
    param(
        [string]$RootDir,
        [string]$OutputFile
    )
    
    $topLevelDirs = @("reference-architectures", "best-practices", "guides", "pathways")
    
    if ([string]::IsNullOrEmpty($RootDir) -or [string]::IsNullOrEmpty($OutputFile)) {
        Write-Host "Usage: .\generate-nav-tree.ps1 -RootDir <root_directory> -OutputFile <output_file>"
        exit 1
    }
    
    Add-Content -Path $OutputFile -Value "nav:"
    Add-Content -Path $OutputFile -Value "  - Home: index.md"
    
    foreach ($topDir in $topLevelDirs) {
        $topDirPath = Join-Path $RootDir $topDir
        if (Test-Path $topDirPath -PathType Container) {
            $folderName = $topDir
            $titleFile = Join-Path $topDirPath ".title"
            if (Test-Path $titleFile) {
                $folderName = Read-TitleFile $titleFile
            }
            
            Add-Content -Path $OutputFile -Value "  - $folderName`:"
            Generate-NavTree -Dir $topDirPath -Indent "    " -OutputFile $OutputFile -RootDir $RootDir
        }
    }
    
    Add-Content -Path $OutputFile -Value "  - Contributing: contributing.md"
    Add-Content -Path $OutputFile -Value "  - Glossary: glossary.md"
    Add-Content -Path $OutputFile -Value "  - Search: search.md"
}

# Script entry point
if ($args.Count -lt 2) {
    Write-Host "Usage: .\generate-nav-tree.ps1 <root_directory> <output_file>"
    exit 1
}

Main -RootDir $args[0] -OutputFile $args[1]