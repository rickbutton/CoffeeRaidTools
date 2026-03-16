param (
    [string]$Tag = ""
)
# Increments the latest tag and makes a release
# This triggers the BigWigs packager

# Check if we are on the main branch before releasing
if ((git branch --show-current) -ne "main") {
    Write-Host "Aborting: not on main branch."
    exit 1
}

# Fetch remote release tags, in case we do not have them locally yet
git fetch --tags origin main

# Check if we are up to date with main
if ((git rev-list "@..main" --count) -ne 0) {
    Write-Host "Aborting: remote contains commits missing from local main branch."
    exit 1
}

# Find the latest tag
$AllTags = git tag
$LastVersion = -1
if ($AllTags.count -gt 0) {
    $LastVersion = $AllTags | ForEach-Object { [int]$_.Substring(1) } | Sort-Object -Descending | Select-Object -First 1
    Write-Host "Most recent tag: $LastVersion"
} else {
    Write-Host "No existing tags found."
}

# If a latest tag exists (i.e., this is not the first ever release), increment it
if ([String]::IsNullOrEmpty($Tag)) {
    if ($LastVersion -eq -1) {
        Write-Host "Aborting: no existing tags, but tag wasn't specified. Specify a tag with -Tag <tag>."
        exit 1
    } else {
        $Tag = "v" + (([int]$LastVersion) + 1)
    }
}

Write-Host "Creating tag $Tag"
git tag $Tag
Write-Host "Pushing tag $Tag to origin"
git push origin $Tag
