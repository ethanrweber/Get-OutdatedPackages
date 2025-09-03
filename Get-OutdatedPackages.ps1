function Get-OutdatedPackages {
    param(
        [switch]$Major
    )

    $solution = Get-ChildItem -Filter *.sln | Select-Object -First 1

    if (-not $solution) {
        Write-Host "No solution file found in the current directory." -ForegroundColor Red
        return
    }

    # Helper function to compare semantic versions for major updates
    function Test-MajorVersionUpdate {
        param(
            [string]$CurrentVersion,
            [string]$LatestVersion
        )
        
        # Parse version numbers, handling potential pre-release suffixes
        $currentParts = $CurrentVersion -split '\.' | ForEach-Object { ($_ -split '-')[0] }
        $latestParts = $LatestVersion -split '\.' | ForEach-Object { ($_ -split '-')[0] }
        
        # Ensure we have at least 3 parts for comparison (major.minor.patch)
        while ($currentParts.Count -lt 3) { $currentParts += "0" }
        while ($latestParts.Count -lt 3) { $latestParts += "0" }
        
        try {
            $currentMajor = [int]$currentParts[0]
            $latestMajor = [int]$latestParts[0]
            
            return $latestMajor -gt $currentMajor
        }
        catch {
            # If version parsing fails, include the package to be safe
            return $true
        }
    }

    $packages = dotnet list $solution.FullName package --outdated |
        Select-String '>' | ForEach-Object {
            $parts = ($_ -split '\s+') -ne ''
            [PSCustomObject]@{
                Package        = $parts[1]  # Package name
                CurrentVersion = $parts[3]  # Resolved version
                LatestVersion  = $parts[4]  # Latest version
            }
        } | Where-Object { $_.CurrentVersion -ne $_.LatestVersion -and $_.LatestVersion -ne 'Not' }

    # Apply major version filter if the flag is specified
    if ($Major) {
        $packages = $packages | Where-Object { 
            Test-MajorVersionUpdate -CurrentVersion $_.CurrentVersion -LatestVersion $_.LatestVersion
        }
    }

    $packages | Sort-Object Package -Unique | Format-Table -AutoSize
}